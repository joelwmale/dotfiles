---
name: vue-inertia-conventions
description: Vue 3 conventions for Inertia-powered Laravel apps - page components, props, forms, validation, partial reloads, composables, routing and testing. Use when writing or reviewing Vue code in a Laravel/Inertia project, or any .vue file under resources/js.
---

# Inertia + Vue Conventions

Vue as the Laravel view layer. Laravel-side rules still apply - the controller
is still thin, validation still happens in a FormRequest, and authorisation
still lives in a Policy.

## Project Shape

```
resources/js/
├── app.ts               # Inertia setup
├── Pages/               # one file per route, PascalCase
│   └── Orders/
│       ├── Index.vue
│       └── Show.vue
├── Layouts/
├── Components/          # shared, presentational
├── Composables/         # useThing.ts
└── types/               # shared TS types, incl. generated model types
```

- One page component per route, path mirroring the controller
- Pages are containers: they read props, compose components, and own page state
- Shared components take explicit props - no `usePage()` inside them

## Script Setup and TypeScript

- Composition API with `<script setup lang="ts">`, always. No Options API.
- Declare props, emits and models by type, not by runtime object:

```vue
<script setup lang="ts">
interface Props {
    order: Order;
    statuses: OrderStatus[];
}

const props = defineProps<Props>();

const emit = defineEmits<{
    cancelled: [orderId: number];
}>();

const note = defineModel<string>('note', { default: '' });
</script>
```

- Generate model types from the backend where possible, rather than
  hand-maintaining a parallel definition that silently drifts
- No non-null assertions (`!`) to silence the compiler - narrow properly
- In script, read props as `props.order`; the template uses `order` directly.
  Do not mix that with reactive props destructure in the same file.

## Props from the Server

- Send the minimum the page needs. A page prop is JSON on every visit.
- Shape data in the controller or a Resource, not in the component
- Never send a full model when the page renders three fields
- Optional props for anything expensive (`Inertia::optional()`; `lazy()` on
  Inertia v1):

```php
return Inertia::render('Orders/Show', [
    'order' => new OrderResource($order),
    'history' => Inertia::optional(fn () => $order->history),
]);
```

- Shared data (auth user, flash) goes through `HandleInertiaRequests`, and stays
  small - it rides along on every response
- Type shared props once by extending `PageProps`, then read them with
  `usePage<PageProps>().props`

## Forms

Check the installed Inertia version first (`package.json`, `composer show
inertiajs/inertia-laravel`). On v2.1+ the `<Form>` component is the default for a
plain submit; `useForm` is for programmatic control, or where the project
already uses it - follow the codebase. Do not hand-roll form state with `ref`
and `fetch`.

```vue
<script setup lang="ts">
import { Form } from '@inertiajs/vue3';
</script>

<template>
    <Form
        :action="route('users.store')"
        method="post"
        reset-on-success
        #default="{ errors, processing, wasSuccessful }"
    >
        <input name="name" id="name" />
        <p v-if="errors.name">{{ errors.name }}</p>

        <button :disabled="processing">Save</button>
    </Form>
</template>
```

- `reset-on-success`, `reset-on-error` and `set-defaults-on-success` need v2.2+;
  on older versions they are errors, not no-ops
- Fields are plain named inputs; no `v-model` needed

`useForm`, when the form needs programmatic control:

```vue
<script setup lang="ts">
import { useForm } from '@inertiajs/vue3';

const form = useForm({ name: '', email: '' });

function submit() {
    form.post(route('users.store'), {
        preserveScroll: true,
        onSuccess: () => form.reset(),
    });
}
</script>

<template>
    <form @submit.prevent="submit">
        <input v-model="form.name" id="name" />
        <p v-if="form.errors.name">{{ form.errors.name }}</p>

        <button :disabled="form.processing">Save</button>
    </form>
</template>
```

- `form.errors` comes from Laravel validation - do not duplicate rules in the
  client. Client-side validation is an affordance, never the guard.
- `form.processing` disables the submit control
- `form.reset()` on success, not a manual clear
- `preserveScroll` on anything that re-renders in place
- `form.transform()` when the payload shape differs from the form shape

## Routing

- Use Ziggy's `route()` helper - never hardcode a URL string
- `<Link>` for navigation, never `<a href>` for internal routes
- `router.visit()` and `router.get()` for programmatic navigation, with `only:`
  for partial reloads
- `preserveState` on filter and search interactions so inputs keep focus

```ts
router.get(route('orders.index'), { status: status.value }, {
    only: ['orders'],
    preserveState: true,
    replace: true,
});
```

- `<Link href=... method="post" as="button">` for a link that must not be a
  `GET` (logout, delete); never a bare `<a>`
- `prefetch` on a `<Link>` the user is very likely to follow
- Use whichever of Ziggy's `route()` or Wayfinder the project already has
- Persistent layouts with `defineOptions({ layout: AppLayout })` in the page,
  not by wrapping the template in a layout component. Wrapping remounts the
  layout, and its state, on every visit.

## Inertia v2 Features

Confirm the project is on v2 before using any of these.

- **Deferred props** (`Inertia::defer()` on the server) load after first paint.
  The prop is `undefined` until it arrives, so the page renders a skeleton for
  that state; never read into it unguarded.
- **`<WhenVisible>`** loads more when an element scrolls into view - infinite
  scroll, or a below-the-fold section. Give it `data` (the prop to reload),
  `:params` for the next page, and a `#fallback`.
- **`usePoll(ms, { only: [...] })`** refreshes data on an interval. It cleans up
  on unmount and throttles in a background tab; `keepAlive: true` overrides
  that. Reload only the props that change.
- **Partial reloads** (`only`, `except`) for anything that changes one slice of
  the page. Never reload the whole page to refresh one list.

## Reactivity

- `ref` for local UI state, `computed` for anything derived from props or state
- `shallowRef` for large objects that are replaced wholesale, which includes
  most data copied out of page props
- Server state lives on the server. Do not copy a page prop into a `ref` and
  then fight to keep the two in sync - read `props.order` directly.
- Derive rather than store: if it can be computed, use `computed`
- `reactive()` loses reactivity when destructured; prefer `ref`, or `toRefs`
- No global store (Pinia) in an Inertia app unless something genuinely spans
  pages - Inertia's whole point is that the server holds the state

## Watchers and Lifecycle

- `watch` is a last resort. Most uses are a symptom of copying props into state.
- Watch a getter (`() => props.id`), not a destructured value
- Clean up timers, listeners and subscriptions in `onUnmounted`, or with
  `onWatcherCleanup` inside a watcher
- Do not fetch in `onMounted`; let Inertia deliver the data as props, with a
  partial reload for anything later

## Composables

- Name with a `use` prefix, one per file, in `Composables/`
- Accept reactive input as `MaybeRefOrGetter` and read it with `toValue()`
- Return a plain object of refs, never `reactive({ ... })`, so the caller can
  destructure without losing reactivity
- Extract one when two components share stateful logic, not before

```ts
export function useOrderSearch(url: MaybeRefOrGetter<string>) {
    const query = ref('');

    watch(query, (search) => {
        router.get(toValue(url), { search }, {
            only: ['orders'],
            preserveState: true,
            replace: true,
        });
    });

    return { query };
}
```

## Components

- One component per file, PascalCase, named for what it is
- Composition over configuration - a component with nine boolean props wants
  splitting into slots or smaller components
- `:key` on `v-for` is a stable ID, never the array index
- Never `v-if` and `v-for` on the same element; filter in a `computed`
- `v-html` needs a comment explaining why the content is safe, and is never
  fed user input

## Accessibility

- Semantic elements first - a `<div @click>` is not a button
- Every input has a label, associated by `id` and `for`
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
