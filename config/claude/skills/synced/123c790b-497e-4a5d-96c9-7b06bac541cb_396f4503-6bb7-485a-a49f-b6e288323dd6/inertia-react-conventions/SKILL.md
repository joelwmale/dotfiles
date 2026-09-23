---
name: inertia-react-conventions
description: React conventions for Inertia-powered Laravel apps - page components, props, forms, validation, partial reloads, routing and testing. Use when writing or reviewing React code in a Laravel/Inertia project, or anything under resources/js.
---

# Inertia + React Conventions

React as the Laravel view layer. Laravel-side rules still apply - the
controller is still thin, validation still happens in a FormRequest, and
authorisation still lives in a Policy.

## Project Shape

```
resources/js/
├── app.tsx              # Inertia setup
├── Pages/               # one file per route, PascalCase
│   └── Orders/
│       ├── Index.tsx
│       └── Show.tsx
├── Layouts/
├── Components/          # shared, presentational
├── Hooks/
└── types/               # shared TS types, incl. generated model types
```

- One page component per route, path mirroring the controller
- Pages are containers: they read props, compose components, and own page state
- Components are presentational and take explicit props - no `usePage()` inside
  a shared component

## TypeScript

- TypeScript by default. A `.jsx` file in a TS project needs a reason.
- Type page props explicitly rather than reaching for `any`:

```tsx
interface Props {
    order: Order;
    statuses: OrderStatus[];
}

export default function Show({ order, statuses }: Props) {
```

- Generate model types from the backend where possible, rather than
  hand-maintaining a parallel definition that silently drifts
- `type` for unions and props, `interface` for object shapes you may extend
- No non-null assertions (`!`) to silence the compiler - narrow properly

## Props from the Server

- Send the minimum the page needs. A page prop is JSON on every visit.
- Shape data in the controller or a Resource, not in the component
- Never send a full model when the page renders three fields
- Lazy props for anything expensive:

```php
return Inertia::render('Orders/Show', [
    'order' => new OrderResource($order),
    'history' => Inertia::lazy(fn () => $order->history),
]);
```

- Shared data (auth user, flash) goes through `HandleInertiaRequests`, and stays
  small - it rides along on every response

## Forms

Use Inertia's `useForm`. Do not hand-roll form state.

```tsx
const form = useForm({ name: '', email: '' });

function submit(e: FormEvent) {
    e.preventDefault();
    form.post(route('users.store'), {
        preserveScroll: true,
        onSuccess: () => form.reset(),
    });
}
```

- `form.errors` comes from Laravel validation - do not duplicate rules in the
  client. Client-side validation is an affordance, never the guard.
- `form.processing` to disable the submit control
- `form.reset()` on success, not a manual state clear
- `preserveScroll` on anything that re-renders in place
- `transform()` when the payload shape differs from the form shape

## Routing

- Use Ziggy's `route()` helper - never hardcode a URL string
- `<Link>` for navigation, never `<a href>` for internal routes
- `router.visit()` for programmatic navigation, with `only:` for partial reloads
- `preserveState` on filter and search interactions so inputs do not lose focus

```tsx
router.get(route('orders.index'), { status }, {
    only: ['orders'],
    preserveState: true,
    replace: true,
});
```

## State

- Server state lives on the server. Do not mirror a page prop into `useState`
  and then fight to keep them in sync.
- `useState` for genuinely local UI state - open/closed, hover, a draft field
- Derive rather than store: if it can be computed from props, compute it
- `useMemo` only when profiling says so, not as a habit
- No global store (Redux/Zustand) in an Inertia app unless something genuinely
  spans pages - Inertia's whole point is that the server holds the state

## Components

- Function components only
- Props destructured in the signature
- One component per file, named the same as the file
- Composition over configuration - a component with nine boolean props wants
  splitting
- Keys on list items must be stable IDs, never the array index
- Extract a custom hook when two components share stateful logic

## Effects

- `useEffect` is a last resort. Most uses are a symptom of mirroring props into
  state.
- Every effect needs a complete dependency array - do not silence the lint rule
- Clean up subscriptions, timers and listeners in the return function
- Do not fetch in an effect; let Inertia deliver the data as props

## Accessibility

- Semantic elements first - a `<div onClick>` is not a button
- Every input has a label, associated by `id`/`htmlFor`
- Focus management on modals and after navigation
- `aria-live` for async status messages, including form errors

## Testing

- Feature-test the Laravel side with Pest and assert the Inertia response:

```php
$this->get(route('orders.show', $order))
    ->assertInertia(fn (Assert $page) => $page
        ->component('Orders/Show')
        ->has('order.id')
        ->missing('order.internal_notes')
    );
```

- Assert what is **not** sent as well as what is - leaking a field into page
  props is a real disclosure bug
- Component tests only for genuinely complex interactive components
