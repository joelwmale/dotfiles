# Laravel changes worth a grep

Run these against the diff, `git diff <base>...<head>`, not the tree. A `-` line is something
removed; a `+` line is something added.

## Removed guards (look at every `-` hit)

```bash
git diff <range> | grep -nE '^-.*(authorize|Gate::|->can\(|@can|abort_if|abort_unless|middleware|throttle|RateLimiter|hash_equals|verifyWebhook|signature)'
git diff <range> | grep -nE '^-.*(->validate\(|validated\(\)|FormRequest|Rule::)'
git diff <range> | grep -nE '^-.*(whereNull|where\(.user_id|->where\(.organisation_id|ownedBy|forUser)'
git diff <range> | grep -nE '^-.*\$fillable'
```

Ask: was the check moved, or is it gone? Who can reach the action now?

## Loosened or widened (look at every `+` hit)

| Pattern | Risk |
|---|---|
| `+ ... $guarded = []`, `Model::unguard()` | Mass assignment on every field |
| `+ ... $request->all()` into `create`/`update`/`fill` | Unvalidated or privileged fields set |
| `+ ... ->withoutGlobalScopes()`, `withoutGlobalScope` | Tenant or soft-delete scope bypassed |
| `+ ... DB::raw`, `whereRaw`, `orderByRaw`, `selectRaw` with a variable | SQL injection; bindings do not protect identifiers |
| `+ ... {!! ` , `x-html`, `->html(` | XSS from stored content |
| `+ ... Http::get($` / `file_get_contents($` / `curl` with a variable URL | SSRF; check redirects too |
| `+ ... Storage::`, `response()->file(`, `download(` with a request-derived path | Path traversal or predictable path |
| `+ ... ->signedRoute(` / `temporarySignedRoute(` | A signed URL is not authorisation; check the owner |
| `+ ... unserialize(`, `extract(`, `$$`, `eval(`, `exec(`, `shell_exec(`, `passthru(` | Code execution |
| `+ ... rand(`, `mt_rand(`, `uniqid(` for a token or code | Predictable secret; use `random_int` or `Str::random` |
| `+ ... == ` or `!=` against a secret, token or ID | Loose comparison; use `hash_equals` or `===` |
| `+ ... env(` outside `config/` | Breaks after `config:cache`; returns null in production |
| `+ ... Route::` with no middleware group | Public route; is that intended? |
| `+ ... csrf`, `VerifyCsrfToken $except` | CSRF disabled; needs its own authenticity check |
| `+ ... session()->put('user'` / `Auth::login(` / `loginUsingId` | Authenticating on client-supplied evidence |
| `+ ... ->update(` / `->delete(` in a Livewire action with no `authorize` | Livewire actions are public endpoints |

## Livewire-specific

- A new `public` property of a model or id is client-writable. Is it `#[Locked]`, or
  re-authorised on every action?
- A new public method is callable by anyone who can mount the component. Does it authorise?
- Hidden state in the view (`wire:model` on a price, role, or ownership field).

## Money and state

- A read-then-write on a balance, stock or payout status, with no `lockForUpdate()`,
  conditional `UPDATE ... WHERE`, or unique constraint
- A transition that skips a guard (a paid order cancelled, a payout released twice)
- A job or listener that sends money or mail with no idempotency key and `$tries > 1`
- An event or queued mail dispatched inside a transaction without `afterCommit()`
- A rate or percentage read from user input or stored with no bounds (a zero or negative
  value meaning "everything" or "free")

## Migrations

- A new FK, unique or `NOT NULL` column on a populated table: lock time and failure on
  existing rows
- A `down()` that drops populated columns
- A data rewrite inside a schema migration with no bound or chunking

## Tests that moved with the code

```bash
git diff <range> --stat -- tests
git diff <range> | grep -nE '^-.*(assertForbidden|assertUnauthorized|assertNotFound|assertDatabaseMissing|assertNotSent|assertNothing)'
```

A deleted negative assertion next to changed production code is a removed guard in test form.

## Dependencies and config

```bash
git diff <range> -- composer.json composer.lock package.json package-lock.json .env.example config
composer audit
```

New packages, loosened version constraints, `APP_DEBUG`, session or cookie flags, trusted
proxies, filesystem disk defaults.
