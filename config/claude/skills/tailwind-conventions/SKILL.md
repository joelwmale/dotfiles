---
name: tailwind-conventions
description: Tailwind CSS v4 conventions - CSS-first theme config, design tokens, class ordering, responsive and dark mode, component extraction and common mistakes. Use when writing or reviewing Tailwind utility classes, theme configuration, or CSS in a Tailwind project.
---

# Tailwind CSS v4 Conventions

Targets Tailwind v4. The headline change from v3 is that configuration moved
out of JavaScript and into CSS - there is no `tailwind.config.js` by default.

## Setup

```css
@import "tailwindcss";

@theme {
    --color-brand-500: oklch(0.62 0.19 256);
    --font-display: "Satoshi", sans-serif;
    --spacing-gutter: 1.5rem;
}
```

- One `@import "tailwindcss"` - not the three v3 `@tailwind` directives
- Theme values are CSS custom properties inside `@theme`
- Namespaces matter: `--color-*` generates colour utilities, `--font-*`
  generates font utilities, `--spacing-*` feeds the spacing scale. A variable in
  the wrong namespace generates nothing.
- `@theme` values are real CSS variables at runtime, so they can be read and
  overridden in CSS - unlike v3's build-time config

### Migrating from v3

If a project still has `tailwind.config.js`, it can be loaded explicitly:

```css
@config "../../tailwind.config.js";
```

Treat that as a migration step, not a destination. Other v3 differences worth
knowing: `@apply` still exists but needs `@reference` when used in a separate
stylesheet or a scoped block; renamed utilities (`shadow-sm` is now `shadow-xs`,
`outline-none` is now `outline-hidden`); and the default border colour changed
from gray-200 to `currentColor`.

## Design Tokens

- Every colour, font and spacing value used twice becomes a theme token
- Name tokens semantically where the meaning is stable (`--color-danger`), and
  by scale where it is not (`--color-brand-500`)
- Prefer `oklch()` over hex - it interpolates predictably and makes generating a
  consistent scale far easier
- Never hardcode a hex in a utility (`bg-[#3b82f6]`) when a token exists

## Arbitrary Values

Escape hatches are fine when justified, and a smell when frequent.

- `w-[347px]` for a one-off that genuinely is not on the scale
- Three arbitrary values on one element means the scale is wrong - fix the scale
- Arbitrary values referencing tokens are better than raw values:
  `bg-[--color-brand-500]`
- Never use an arbitrary value for something on the spacing scale already

## Class Ordering

Use Prettier with `prettier-plugin-tailwindcss`. Do not order by hand and do
not argue about it in review - the plugin settles it.

The canonical order is roughly: layout, box model, typography, visual, then
state and responsive variants.

## Responsive and Dark Mode

- Mobile first. Unprefixed utilities are the small screen; `sm:` upward are
  overrides.
- Do not write `sm:` for the base case
- Container queries are built in - `@container` on the parent and `@sm:` on the
  child. Prefer them for components that must work at several widths, because a
  component should respond to its container, not the viewport.
- Dark mode via the `dark:` variant. Define both in the same place, not in a
  separate stylesheet that drifts.
- Every colour decision needs its dark counterpart at the moment it is written

## Component Extraction

The right answer is almost always a component, not a CSS class.

- Repeating a class string three times means extracting a Blade component, a
  Livewire component or a React component
- `@apply` is a last resort - it re-introduces the indirection Tailwind exists
  to remove. Legitimate uses: styling markup you do not control, and a genuine
  base-layer default.
- `@utility` for a real custom utility that needs variant support:

```css
@utility tap-target {
    min-height: 44px;
    min-width: 44px;
}
```

- Conditional classes go through a helper (`clsx`, `cva`, Laravel's `@class`),
  never string concatenation

## Common Mistakes

- **Dynamic class names.** `bg-${color}-500` does not work - the scanner reads
  source text and never sees the composed string. Map to complete class names:

```tsx
const styles = {
    danger: 'bg-red-500 text-white',
    success: 'bg-green-500 text-white',
} as const;
```

- **Fighting the preflight.** If a reset is causing pain, override deliberately
  in `@layer base` rather than disabling preflight wholesale.
- **Space utilities on flex containers.** Use `gap-*`, not `space-x-*`, wherever
  the parent is flex or grid.
- **`!important` via `!`.** Almost always a specificity problem elsewhere.
- **Unbounded text.** Long user content needs `break-words` or `truncate`; a
  layout that only works with short strings will break in production.

## Accessibility

- `focus-visible:` rather than removing outlines. `outline-hidden` (v4's rename
  of `outline-none`) preserves the forced-colours outline; genuine removal needs
  a replacement indicator.
- Check contrast on every token pair, in both themes
- `sr-only` for content that must exist for screen readers only
- Respect `motion-reduce:` on anything animated
- Interactive targets need a minimum size - roughly 44px - on touch
