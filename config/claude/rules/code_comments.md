# Code Comments (Sparse by Default)

Applies to every language, every framework, every codebase. No exceptions for
"this one is complex" - complex code earns *one* comment about the part that is
actually complex, not a running narration.

---

## The principle

**Code says what. Comments say why.**

A comment that restates the line it sits above has negative value: it is one
more thing to read, one more thing to keep in sync, and it goes stale the first
time someone edits the line without editing the comment.

## The test

**Delete the comment. Is anything lost?**

If a competent reader could derive it from the code in about two seconds, it
was noise. Leave it deleted.

```php
// NO - says nothing the line does not
// Get the errors from the requirements object
$errors = collect($object->requirements->errors);

// NO - the variable name already said this
// Loop through each user
foreach ($users as $user) {

// YES - explains something the code cannot
// Stripe returns these unkeyed and out of order, so index by field
// to match them against our form inputs.
$errors = collect($object->requirements->errors)->keyBy('field');
```

---

## Comment when

- **The why is not derivable.** A business rule, a regulatory requirement, an
  ordering constraint, a deliberate performance tradeoff.
- **The code looks wrong but is right.** If the next reader's instinct will be
  to "fix" it, say why not - and that comment saves a future bug.
- **An external system forced your hand.** A third-party API quirk, an
  undocumented response shape, a spec section, a vendor bug you are working
  around. Link or cite where possible.
- **There is a landmine.** "Must run before X." "Changing this order breaks
  the webhook signature." Coupling a reader cannot see from here.
- **The algorithm is genuinely non-obvious.** One comment naming the approach,
  not a line-by-line walkthrough.

## Do not comment

- **Restating the line.** The single most common failure. If the comment is the
  line in English, delete it.
- **Narrating the change.** "Added null check." "Updated to handle empty
  arrays." "New: supports pagination." That is a commit message. The next
  reader has no idea what it was before and does not care.
- **Step narration.** "Step 1: fetch the user. Step 2: validate. Step 3: save."
  If a function needs signposting, it needs splitting.
- **Section headers in a short function.** A six-line function does not have
  sections.
- **Docblocks that repeat the signature.** A `@param string $email` above
  `function send(string $email)` adds nothing. Document a param only when the
  type does not convey the constraint - units, format, allowed range, ownership.
- **Every property of an obvious DTO or config array.**
- **Framework behaviour.** "Eloquent will hydrate this." "React re-renders on
  state change." Assume the reader knows the tools.
- **Commented-out code.** Delete it. Git has it.
- **`TODO` for work you just did**, or placeholders left from scaffolding.

---

## Density

**Match the file you are in.** A codebase with no comments does not suddenly
acquire them because you touched it. If the surrounding code is uncommented and
readable, yours should be too.

**When a comment is warranted, one line is usually enough.** Three lines of
prose above a two-line statement is the failure mode to avoid. Write the
sentence that carries the information and stop.

## Prefer making the comment unnecessary

Most comments are a naming problem wearing a disguise. Before writing one, try:

- a better variable or function name
- extracting the confusing expression into a named variable
- extracting the block into a small, well-named function

A named thing survives refactoring. A comment does not.

```php
// Instead of explaining a condition:
// Check if the order is old enough to be archived and has no open disputes
if ($order->created_at->lt(now()->subYear()) && $order->disputes()->open()->doesntExist()) {

// Name it:
if ($order->isArchivable()) {
```

---

## Do not

- Do not add comments to demonstrate thoroughness. Sparse, accurate comments
  read as more competent than dense ones, not less.
- Do not comment a line because it took you a while to write. Difficulty of
  authorship is not difficulty of reading.
- Do not leave a comment you have not verified is still true after editing the
  code beneath it.
- Do not explain in a comment what a reader would learn faster by reading the
  function you are calling.
