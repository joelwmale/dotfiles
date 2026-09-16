---
name: livewire-conventions
description: Livewire conventions targeting v4, with v3 differences flagged - components, properties, actions, computed properties, islands, wire:model modifiers, Alpine integration, and a security section on client-writable public properties, #[Locked], middleware not re-applying to livewire/update, and how to test tampering. Use when writing or reviewing Livewire components or Blade views containing wire: directives.
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

## Security

Livewire's request model is the single largest source of critical findings in
our pentest reports. Read this section before writing a component.

### Every public property is attacker-controlled

The client posts an `updates` payload to `/livewire/update`. The only check
Livewire applies is that the property is **public and declared on the
component**. There is no allowlist, and **no `wire:model` binding is required** -
a property the template never binds is still writable.

Eloquent *model* properties are checksum-protected. **Scalars and arrays are
not.** An `int`, `string`, `bool` or `array` property is client input.

```php
// DANGEROUS
class ProductIndex extends Component
{
    // A public array is client input on every request after the first one.
    public array $brandIds = [];

    public function mount(): void
    {
        // Runs ONCE, on the initial render.
        $this->brandIds = auth()->user()->supplier->brands->pluck('id')->toArray();
    }

    public function render(): View
    {
        // Runs on EVERY request, against whatever the client last sent.
        return view('livewire.products.index', [
            'products' => Product::whereHas(
                'brand',
                fn ($q) => $q->whereIn('id', $this->brandIds)
            )->get(),
        ]);
    }
}
```

**Best fix: do not hold the value at all.** Resolve it from the authenticated
user inside the query. Note what disappears - the property and `mount()` are
both gone, so there is nothing left for the client to tamper with:

```php
// SAFE
class ProductIndex extends Component
{
    public function render(): View
    {
        return view('livewire.products.index', [
            'products' => Product::whereHas(
                'brand',
                fn ($q) => $q->whereIn('id', auth()->user()->supplier->brands->pluck('id'))
            )->get(),
        ]);
    }
}
```

**Second best: `#[Locked]`.** Apply it to every property the client must not
change - tenancy scopes, IDs, prices, totals, quantities, statuses, roles,
permission flags, polymorphic type strings.

```php
#[Locked]
public int $orderId;

#[Locked]
public string $modelType;
```

Findings we have actually shipped from getting this wrong: cross-tenant
catalogue deletion, platform-wide order book disclosure, account takeover,
2FA bypass, arbitrary gift card values, client-declared payment success, and
stock allocated from reserved and quarantined pools.

### `mount()` runs once and then stops protecting anything

`mount()` fires on the initial render only. `render()` and every action run
again on each subsequent request, against state the client can rewrite.

**Authorisation inside `mount()` is not authorisation.** Authorise inside each
action and re-derive scope inside each query.

### Route middleware does not re-apply to Livewire actions

Livewire re-applies only a fixed allow-list of middleware to
`POST /livewire/update` (see
`vendor/livewire/livewire/src/Mechanisms/PersistentMiddleware/PersistentMiddleware.php`).
Roughly: session authentication, basic auth and route-model binding.

**Your custom middleware does not re-run.** Permission gates, 2FA enforcement,
subscription checks and `throttle` protect the initial GET that renders the
page - and nothing after it. All the real work happens in actions, which POST
to a route those middleware never see.

Two consequences, both of which have produced High findings:

1. **Authorisation must be re-asserted inside the component**, in every action.
   Do not rely on the route's middleware stack.
2. **Rate limiting must be applied inside the action.** A `throttle` on the
   route does not limit a password reset, a verification-code check or a 2FA
   attempt that runs as a Livewire action.

```php
public function verify(): void
{
    $key = 'verify:'.auth()->id();

    if (RateLimiter::tooManyAttempts($key, 5)) {
        throw new TooManyRequestsHttpException(RateLimiter::availableIn($key));
    }

    RateLimiter::hit($key, 300);

    $this->authorize('verify', $this->order);
}
```

Where middleware genuinely must persist, register it explicitly with
`Livewire::addPersistentMiddleware([...])` - and still authorise in the action.

### Every public method is a public endpoint

Any `public function` on a component can be invoked by name, whether or not the
template renders a control for it. Hiding a button hides nothing.

- Authorise inside the method
- Methods that are not actions should be `protected` or `private`
- A public method that sets a session flag, confirms a step, or marks state is
  an unauthenticated state transition unless it checks something

### Never put secrets in public properties

Public properties serialise into the page and back. A `public string $password`
puts the plaintext in the DOM, in the snapshot, and in anything that captures
either.

- Passwords, tokens, TOTP secrets and recovery codes must never be public
  properties
- Bind them to a `protected`/`private` property, or read them from the request
  in the action and clear immediately after use

### Scope every lookup through the relationship

`Model::find($id)` with a client-supplied `$id` is unscoped by definition.

```php
// DANGEROUS - reaches any row
$comment = Comment::find($id);

// Correct - constrained to what this principal owns
$comment = $this->order->comments()->findOrFail($id);
```

### Guards must fail closed on null

A comparison between two nulls passes.

```php
// DANGEROUS - when both sides are null, the guard passes
if ($comment->user_id !== auth('admin')->id()) {
    return false;
}

// Correct - reject an absent identity outright
$adminId = auth('admin')->id();

abort_if($adminId === null, 403);
abort_if($comment->user_id !== $adminId, 403);
```

Rows written by jobs, console commands, webhooks and services have no auth
context, so their ownership columns are null. Those are exactly the rows a
null-comparing guard hands over.

### Testing security fixes

**A single-request Livewire test passes against a two-request tampering
exploit.** The real attack is: post a tampered property, let the server
re-render and hand back a signed snapshot containing the victim's data, then
replay that snapshot and call the destructive action.

So a test must:

1. `->set()` the tampered property explicitly, simulating the client write -
   do not assume the property is unreachable because the template does not
   bind it
2. Assert the guarded action **did not happen**, not merely that a status came
   back or an exception was thrown

```php
it('cannot delete another tenant\'s products', function () {
    $mine = Supplier::factory()->create();
    $theirs = Product::factory()->create();

    Livewire::actingAs($mine->user)
        ->test(ProductIndex::class)
        ->set('brandIds', [$theirs->brand_id])   // the tamper
        ->call('removeProduct', [$theirs->id])
        ->assertForbidden();

    expect(Product::find($theirs->id))->not->toBeNull();  // the real assertion
});
```

Verify a security fix by deleting the guard, watching the test fail, and
restoring it. A test that stays green without the guard is not a test.

## Config Renames (v3 to v4)

| v3 | v4 |
|---|---|
| `layout` | `component_layout` (with `layouts::` namespace) |
| `lazy_placeholder` | `component_placeholder` |
| - | `component_locations`, `component_namespaces` |
| - | `smart_wire_keys` (defaults `true`) |
| - | `csp_safe` |
