---
name: livewire-conventions
description: Livewire conventions targeting v4, with v3 differences flagged - components, properties, actions, validation, computed properties, islands, events, wire:model modifiers, Alpine integration and testing. Use when writing or reviewing Livewire components or Blade views containing wire: directives.
---

# Livewire Conventions

**Targets v4. v3 differences are flagged inline** - both are in use across our
projects, and several v4 changes are silent behaviour changes rather than
errors, so check `composer.lock` before assuming.

```bash
jq -r '.packages[]|select(.name=="livewire/livewire")|.version' composer.lock
```

Laravel rules in `rules/php_coding_rules.md` and `laravel-conventions` still
apply - this covers what is specific to Livewire.

## House Structure

We use **class-based components with paired views**, not single-file
components:

```
app/Livewire/Admin/Organisations/Edit.php
resources/views/livewire/admin/organisations/edit.blade.php
```

v4 introduced single-file (SFC) and multi-file (MFC) component formats, and
SFC is the framework's new default for `make:livewire`. We have not adopted
either - stay with the class-based layout above unless a project has
deliberately moved, and do not mix formats inside one project.

A component class should look like this:

```php
<?php

declare(strict_types=1);

namespace App\Livewire\Admin\Organisations;

use Illuminate\Contracts\View\View;
use Livewire\Attributes\Layout;
use Livewire\Component;

#[Layout('layouts.admin')]
class Edit extends Component
{
    public Organisation $organisation;

    public function render(): View
    {
        return view('livewire.admin.organisations.edit');
    }
}
```

## Component Design

- One screen concern per component. Two unrelated responsibilities means split.
- Keep the public surface small - every public property serialises to the
  browser and back on **every** request.
- Business logic belongs in an Action or Service. An action method on the
  component should read as orchestration.

## Properties

- Type every public property.
- Never put a secret, a large collection or an unserialisable object in a
  public property.
- `#[Locked]` on anything the client must not change, IDs above all:

```php
#[Locked]
public int $orderId;
```

- `#[Url]` to bind a property to the query string - use it for filters and
  pagination state so the page is linkable and survives a refresh
- `protected`/`private` for anything the view does not need

## Computed Properties

`#[Computed]` for derived data rather than a public property you keep in sync
by hand. Memoised per request.

```php
#[Computed]
public function order(): Order
{
    return Order::findOrFail($this->orderId);
}
```

- Access as `$this->order` in both PHP and the view
- `#[Computed(persist: true, seconds: 300)]` to cache across requests
- Reach for one whenever you would otherwise query in both `render()` and an
  action

## Actions

- Name them as verbs: `save`, `cancelOrder`, `markAsRead`
- Authorise inside the action. Never assume the UI hid the button.
- Validate before doing work
- Return nothing, or redirect - not data for the view

```php
public function cancel(): void
{
    $this->authorize('cancel', $this->order);

    app(CancelOrder::class)->handle($this->order);

    $this->dispatch('order-cancelled');
}
```

**v4 modifiers worth knowing:**

- `.renderless` - run the action without re-rendering, for fire-and-forget work
- `.preserve-scroll` - stop layout jump on update
- `#[Async]` / `.async` - run in parallel rather than queueing behind other
  requests

## Validation

We use `$this->validate([...])` inline in the action, not `#[Validate]`
attributes - keep that consistent.

```php
$this->validate([
    'userEmail' => ['required', 'email', 'exists:users,email'],
]);
```

Array rules, not pipe strings. Authorisation is a Policy concern, not a
validation one.

## wire:model - read this before binding anything

**v4 changed the modifier semantics, and the change is silent.**

- In v3, `.blur` and `.change` controlled when the *server* was updated
- In v4, they control when **client-side state syncs too**. To get the v3
  behaviour, prefix with `.live`: `wire:model.live.blur`
- In v4, `wire:model` **ignores events from child elements** by default. Use
  `.deep` to restore v3 behaviour - this is the one that silently breaks custom
  input components that emit from an inner element.
- v4 supports bracket notation for nested properties

Otherwise:

- Plain `wire:model` is deferred. That is the right default.
- `.live` only where the UI genuinely needs every keystroke
- `.live.debounce.300ms` on search inputs - never a bare `.live`
- Never bind directly to model attributes when the model is
  authorisation-relevant

## Islands (v4)

Islands are isolated regions that re-render independently of their parent -
the win of a child component without the cost of one. We are not using them
yet; they are the right tool when an expensive region sits beside cheap ones.

```blade
@island(name: 'revenue')
    <div>
        Revenue: {{ $this->revenue }}
        <button wire:click="$refresh" wire:island="revenue">Refresh</button>
    </div>
@endisland
```

Modifiers: `lazy: true` (load on scroll into view), `defer: true` (load after
page load), `always: true`, `skip: true`, and `wire:poll.3s`. `@placeholder`
supplies a loading state.

Use for expensive computations blocking initial load, independent regions, and
targeted real-time updates. Do not use for static content, tightly coupled UI,
or anything that already renders fast.

## Events

- `$this->dispatch('event-name', key: $value)` - named arguments, kebab-case
  names
- `#[On('event-name')]` to listen
- `->to(Component::class)` to target, `->self()` to stay local
- Prefer a parent passing data down over a child broadcasting upward when the
  relationship is direct

## Nesting, Slots and Keys

- **v4: component tags must be closed.** An unclosed tag makes Livewire treat
  everything after it as slot content, which produces baffling output rather
  than an error.
- v4 components support slots and automatic attribute forwarding - use them
  instead of passing markup through props
- Stable `wire:key` on every element in a loop, never the array index
- Children do not reach into parents - use events or `#[Reactive]`
- A nested component that only renders markup should be a Blade component
  instead; a Livewire component costs a round trip

## Routing

Full-page components register with `Route::livewire()` in v4:

```php
Route::livewire('/orders/{order}', ShowOrder::class)->name('orders.show');
```

v3 used `Route::get('/orders/{order}', ShowOrder::class)`, which still works.

## Loading, Navigation and Polling

- `wire:loading` with `wire:target` to scope the indicator to one action
- v4 adds a `data-loading` attribute you can style directly
- `wire:dirty` for unsaved-change affordances
- `#[Lazy]` on expensive below-the-fold components, with a `placeholder()`
- `wire:navigate` on internal links for SPA-style navigation
- v4: `wire:scroll` became `wire:navigate:scroll`
- `wire:poll` sparingly, always with an interval
- **v4 removed `wire:transition`** in favour of the View Transitions API; all
  its modifiers (`.opacity`, `.scale`) are gone

## New v4 Directives

- `wire:sort` - drag-and-drop list sorting, no JS package needed
- `wire:intersect` - run an action when an element enters or leaves the viewport
- `wire:ref` - element references

## Alpine Integration

- Alpine ships with Livewire - do not load it separately
- `$wire` is the bridge: `x-data="{ open: $wire.entangle('isOpen') }"`
- Purely visual state stays in Alpine and never round-trips
- Anything persisted or authorised belongs in Livewire
- `x-on:` for DOM events, `wire:` for server actions - do not mix on one element

## Performance

- Watch the payload - every public property serialises both ways each request
- `#[Computed]` instead of re-querying
- `WithPagination`, never a manual offset in a public property
- One component with a well-shaped payload beats five chatty children
- Islands before splitting into child components

## Testing

```php
it('cancels an order', function () {
    $order = Order::factory()->create();

    Livewire::actingAs($user)
        ->test(ShowOrder::class, ['orderId' => $order->id])
        ->call('cancel')
        ->assertDispatched('order-cancelled');

    expect($order->refresh()->status)->toBe(OrderStatus::Cancelled);
});
```

- Assert the state change, not just the dispatched event
- On the authorisation path, assert the action **did not happen** - a status
  assertion alone passes even if the guard is deleted
- Test `#[Locked]` properties by attempting to set them

## Config Renames (v3 to v4)

| v3 | v4 |
|---|---|
| `layout` | `component_layout` (with `layouts::` namespace) |
| `lazy_placeholder` | `component_placeholder` |
| - | `component_locations`, `component_namespaces` |
| - | `smart_wire_keys` (defaults `true`) |
| - | `csp_safe` |
