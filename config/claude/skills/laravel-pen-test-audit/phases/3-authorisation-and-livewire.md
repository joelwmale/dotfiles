# Phase 9 - Authorization, IDOR and Tenant Isolation

This is one of the highest-priority phases.

For every endpoint containing a resource identifier, attempt substitution.

Examples:

```text
/projects/123
/users/123
/orders/123
/documents/123
/organisations/123
```

Test:

```text
GET
POST
PATCH
PUT
DELETE
custom actions
downloads
exports
```

Attempt:

```text
another user's record
another tenant's record
administrator-only record
archived record
deleted record
record with discovered ULID
record with guessed UUID
```

UUIDs and ULIDs are NOT authorisation.

Search:

```php
find(
findOrFail(
firstWhere(
where('id'
resolveRouteBinding(
```

Verify every sensitive operation uses:

- policies
- gates
- scoped route binding
- explicit ownership validation
- tenant-scoped queries

Where possible prefer obvious authorisation at the route/action boundary.

The test suite should contain explicit negative tests proving:

```text
Tenant A cannot read Tenant B
Tenant A cannot update Tenant B
Tenant A cannot delete Tenant B
normal user cannot perform admin action
```

---

# Phase 10 - Missing Authorization Test Strategy

For every protected controller/action/component method, ask:

> What automated test proves an unauthorised user cannot perform this?

Do not be satisfied only by happy-path tests.

A secure feature generally needs both:

```text
authorised user succeeds
unauthorised user fails
```

For tenant applications:

```text
same tenant succeeds
different tenant fails
```

For admin systems:

```text
admin succeeds
ordinary user fails
```

---

# Phase 11 - Broadcast Channel Authorization

Treat `routes/channels.php` as security-sensitive code.

Inspect every broadcast channel callback.

Example:

```php
Broadcast::channel('users.{id}', function ($user, $id) {
    ...
});
```

Attempt to subscribe to another user's channel.

Review:

```text
private channels
presence channels
Echo subscriptions
broadcast authentication
Reverb
Pusher-compatible infrastructure
```

Look for:

```php
==
!=
```

between user-controlled channel parameters and identifiers.

Use strict comparisons or explicitly cast both operands before comparison.

The Canary audit discovered a critical broadcast authorisation issue caused by PHP type juggling, allowing users to subscribe to another user's private channel.

Test:

```text
own channel succeeds
another user's channel fails
modified identifier fails
unexpected JSON/scalar types fail
```

---

# Phase 12 - Type Juggling

Search security-sensitive comparisons.

Look for:

```php
==
!=
```

especially involving:

```text
user IDs
tenant IDs
API keys
tokens
verification codes
secrets
signatures
broadcast parameters
request JSON
Livewire properties
```

Remember JSON input can represent:

```text
string
integer
boolean
array
null
```

Do not assume request values are strings.

Prefer:

```php
===
!==
```

after normalising expected types.

For secret strings use:

```php
hash_equals()
```

where appropriate.

Attempt inputs such as:

```json
true
false
0
1
null
[]
{}
```

where type confusion may influence authentication or authorisation.

---

# Phase 13 - Mass Assignment and Hidden Parameters

Ignore what the UI sends.

Send additional fields manually.

Look for:

```php
$request->all()
request()->all()
fill()
create()
update()
forceFill()
```

Attempt injection of:

```text
id
user_id
organisation_id
tenant_id
owner_id
role
permissions
is_admin
is_super_admin
status
approved
approved_at
email_verified_at
balance
credit
price
amount
discount
subscription
created_at
updated_at
```

Validation alone is not authorisation.

Determine whether the current actor should be allowed to set each field.

---

# Phase 14 - Livewire Attack Review

Livewire public properties must be treated like browser-submitted form values.

They are NOT trusted server-side state merely because they are PHP properties.

For every Livewire component inspect:

```text
public properties
#[Locked]
mount()
hydrate/dehydrate behaviour
actions
validation
computed properties
file uploads
model binding
```

Attempt to modify public properties manually through Livewire requests.

Attack:

```text
model IDs
tenant IDs
ownership IDs
role
status
price
permissions
tokens
hidden booleans
workflow state
```

For example, if the component contains:

```php
public int $userId;
```

assume the attacker can attempt another value unless it is locked or independently authorised.

Do not rely on:

```text
disabled input
hidden input
wire:show
conditional button
Vue/Alpine state
```

Every Livewire action that modifies protected data should independently enforce its security boundary.

Securing Laravel specifically highlights the danger of treating public Livewire properties as trusted internal state.

## Action inventory (mandatory)

Every public method on a Livewire component is an HTTP endpoint. Build a table of **all** of them:

```bash
rg -n "public function \w+\(" app/Livewire
```

Columns: component, method, what it writes or reveals, authorisation inside the method (policy,
gate, role check, scoped query, or none), and the client-writable properties it reads.

Rules for the verdict:

- Authorisation in `mount()`, in a Blade `@if`/`@can`, or in a `$user->can_x` flag on a button does
  **not** cover the method. Grep the views for the permission flags they check, then confirm the
  action method repeats the same check. A rule that exists only in the template is a finding.
- **Dead actions count.** A method with no button, or whose inputs are `disabled`/`readonly` in the
  view, is still callable with `$wire.$call()` / `$wire.$set()`. A save method for fields the UI
  shows as read-only is a privilege escalation, and a stored-XSS or data-integrity vector.
- A component mounted in a shared layout (cart, notifications, search) is reachable by **every**
  authenticated role, so its actions need role checks even though the page "belongs" to one role.
- Validation is not authorisation. `rules()` proving a field is a string under 255 characters says
  nothing about whether this user may write it.
- Public properties that carry ids, paths, or prices into an action must be `#[Locked]` or
  re-derived server-side. Properties that hold arrays of records (stocks, documents, line items) are
  client-writable all the way down, including nested keys.

### Middleware does not follow Livewire updates

Livewire replays only its **persistent middleware** (by default auth and `can`-style) on
`/livewire/update`. Check:

```bash
rg "addPersistentMiddleware|isLivewireRequest|routeIs\('livewire|is\('livewire|expectsJson" app bootstrap
```

- Custom role/status/onboarding middleware not registered via `Livewire::addPersistentMiddleware()`
  does not run on actions.
- Middleware that lets Livewire requests through (`isLivewireRequest()`, `is('livewire/*')`)
  provides no protection on those requests.
- Middleware that skips its check when `$request->expectsJson()` can be bypassed by sending
  `Accept: application/json`. Test with that header.

Prove each gap by calling the action as a lower role with `Livewire::test()->call()` and asserting
the data is unchanged.

---

# Phase 15 - Inertia / Vue Data Exposure

Inspect:

```text
Inertia::render()
Inertia::share()
HandleInertiaRequests
JsonResource
ResourceCollection
toArray()
```

Remember:

> A value does not need to appear visually on the page to be exposed.

Anything provided as an Inertia prop is available to the browser.

Search for exposure of:

```text
password hashes
remember tokens
API tokens
private notes
internal IDs
PII
other tenant data
permissions
signed URLs
secrets
private storage paths
```

Inspect shared props especially carefully because they may be included on every response.

Frontend permission checks are UX only.

Repeat protected requests directly without Vue.

---
