---
name: livewire-conventions
description: Livewire 3 component conventions - properties, actions, validation, computed properties, events, nesting, Alpine integration and testing. Use when writing or reviewing Livewire components or Blade views that contain wire: directives.
---

# Livewire 3 Conventions

Assumes Livewire 3. Laravel rules in `rules/php_coding_rules.md` and
`laravel-conventions` still apply - this covers what is specific to Livewire.

## Component Design

- A component owns one screen concern. If it has two unrelated responsibilities,
  split it.
- Full-page components live in `app/Livewire`, nested ones in a subdirectory
  that mirrors their parent.
- Keep a component's public surface small - every public property is state that
  round-trips to the browser on every request.
- Business logic belongs in an Action or Service, same as a controller. A
  Livewire action method should read as orchestration.

## Properties

- Type every public property.
- Public properties are serialised to the client. Never put a secret, a large
  collection or an unserialisable object in one.
- Use `#[Locked]` on anything the client must not change - IDs above all:

```php
#[Locked]
public int $orderId;
```

- Model properties bind by ID and re-resolve. Prefer holding the ID and a
  computed property over holding a hydrated model.
- `protected` or `private` for anything that does not need to reach the view.

## Computed Properties

Use `#[Computed]` for derived data instead of a public property you keep in
sync by hand. It is memoised per request.

```php
#[Computed]
public function order(): Order
{
    return Order::findOrFail($this->orderId);
}
```

- Access as `$this->order` in PHP and `$this->order` in the view
- `#[Computed(persist: true)]` to cache across requests, with a `seconds:` value
- Reach for a computed property whenever you would otherwise re-query in both
  `render()` and an action

## Actions

- Name them as verbs: `save`, `cancelOrder`, `markAsRead`
- Authorise inside the action - `$this->authorize(...)` - never assume the UI
  hid the button
- Validate before doing work
- Return nothing, or redirect. Do not return data for the view; use a property
  or computed property.
- `wire:click="save"` over `wire:click="$set(...)"` for anything with side
  effects

```php
public function cancel(): void
{
    $this->authorize('cancel', $this->order);

    app(CancelOrder::class)->handle($this->order);

    $this->dispatch('order-cancelled');
}
```

## Validation

- `#[Validate]` attributes for simple, stable rules
- A `rules()` method when rules are conditional
- `$this->validate()` inside the action, not in `render()`
- Real-time validation via `#[Validate(onUpdate: false)]` plus an explicit
  `validateOnly()` in `updated()`, so you control when it fires

## Data Binding

- `wire:model` is deferred in Livewire 3. That is the right default.
- `wire:model.live` only where the UI genuinely needs each keystroke
- `wire:model.blur` for validation-on-leave
- `.live.debounce.300ms` on search inputs - never bare `.live`
- Never bind a form directly to a model's attributes when the model is
  authorisation-relevant

## Events

- `$this->dispatch('event-name', key: $value)` - named arguments, kebab-case
  event names
- `#[On('event-name')]` to listen
- `dispatch()->to(Component::class)` to target, `->self()` to stay local
- Prefer a parent passing data down over children broadcasting upward where the
  relationship is direct

## Nesting

- Every nested component needs a stable `:key`, especially inside loops
- `wire:key` on the loop element, not the component tag, when iterating
- Children do not reach into parents. Use events or `#[Reactive]` props.
- A nested component that only renders markup should be a Blade component
  instead - Livewire components cost a round trip

## Loading and Lazy States

- `wire:loading` on anything that takes a perceptible moment
- `wire:target` to scope the indicator to one action
- `wire:dirty` for unsaved-change affordances
- `#[Lazy]` on components that are expensive and below the fold, with a
  `placeholder()` method
- `wire:navigate` on internal links for SPA-style navigation

## Alpine Integration

- Alpine ships with Livewire 3 - do not load it separately
- `$wire` is the bridge: `x-data="{ open: $wire.entangle('isOpen') }"`
- Keep purely visual state in Alpine and never round-trip it
- Anything persisted or authorised belongs in Livewire, not Alpine
- `x-on:` for DOM events, `wire:` for server actions - do not mix concerns on
  one element

## Performance

- Watch the payload: every public property is serialised both ways each request
- `#[Computed]` instead of re-querying
- Pagination via `WithPagination`, never a manual offset in a public property
- `wire:poll` sparingly and always with an interval
- Prefer one component with a well-shaped payload over five chatty children

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
- `assertForbidden()` on the authorisation path, and assert the action did not
  happen
- Test `#[Locked]` properties by attempting to set them
