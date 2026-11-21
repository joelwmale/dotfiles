# Generated Copy (No Instruction Text)

Applies to every page, component, form, email and empty state you write that has
visible text. Same test as `code_comments.md`: **remove the line - does a user
who can see the page lose anything?** If not, it was fluff.

The interface shows the thing. Text is for labelling it, or for what the
interface cannot say on its own.

## Do not generate

- instruction lines the controls already show: "Fill in the form below",
  "Click the button to save", "Enter your email to continue"
- an intro that restates the title: heading "Users" over "Manage your users here"
- a subtitle under every heading; one heading is the default
- eyebrow labels (small uppercase text above a heading) and `01 //` numbering with no real order
- badges ("New", "AI", "Beta") and pulsing status dots not bound to real state
- decorative emoji or icons in headings, buttons and feature lists
- a chart title that names the chart, or a caption that explains how to read it
- status strings chained with a dot ("12 items · Updated 2m ago · Synced") - keep the one fact the user acts on
- staccato slogans ("Ship faster. Think less.")
- chart clutter: a legend where each line could carry its name, a value on every point plus axis plus gridlines, frame boxes, 3D
- helper text that repeats the label or placeholder
- placeholders that repeat the label
- app-UI marketing filler: "Welcome to your dashboard", "Everything in one place"
- tooltips or `title` attributes that repeat a visible label
- empty-state essays: one short line and the action
- success prose: "Your changes have been saved successfully!" becomes "Saved"
- HTML or Blade comments that name a section: `<!-- Header -->`
- descriptive filler in seed, sample or demo data

Delete before rewriting. Never invent a number, speed, integration or benefit the
code does not show. In an app screen a heading or card title stays at 5 words or fewer.

## Do write copy for

- an error that says how to fix it
- a warning before an irreversible action
- a constraint the control cannot show: format, limit, who will see this
- legal or required text
- copy the user supplied

Icon-only controls still get an accessible name. That is a label, not fluff.

## Cleanup

For a screen that already exists, run `/unslop-ui <path>`. This file prevents the
tells at write time; that skill removes them and reports what it cut.

## Density

Match the project's existing pages. If they carry no helper text, yours carry none.
