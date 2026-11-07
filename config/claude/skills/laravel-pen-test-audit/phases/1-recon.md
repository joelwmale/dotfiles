# Phase 0 - Establish Architecture and Threat Model

Before investigating vulnerabilities, understand the application.

Inspect:

```text
composer.json
composer.lock
package.json
package-lock.json / pnpm-lock.yaml / yarn.lock
routes/*
config/*
bootstrap/*
app/Providers/*
app/Http/Middleware/*
app/Policies/*
app/Livewire/*
app/Http/Controllers/*
app/Http/Requests/*
app/Models/*
resources/js/*
resources/views/*
```

Determine:

- Laravel version
- PHP version
- Livewire version
- Inertia version
- Vue version
- authentication implementation
- MFA implementation
- API authentication
- session storage
- queue infrastructure
- broadcasting infrastructure
- tenancy model
- admin systems
- payment providers
- S3/object storage
- email providers
- webhooks
- OAuth integrations
- external APIs

Identify trust levels such as:

```text
Anonymous
Guest
Authenticated User
Organisation Member
Organisation Administrator
Internal Staff
Administrator
Super Administrator
API Client
Webhook Provider
Queue Worker
Scheduled Process
```

Identify sensitive information:

- personal information
- healthcare information
- financial information
- documents
- prescriptions
- credentials
- private messages
- exports
- API tokens
- commercially sensitive information

For multi-tenant applications explicitly answer:

> What prevents Tenant A from accessing Tenant B?

Do not proceed until this boundary is understood.

---

# Phase 1 - Complete Route Enumeration

Do not inspect only `routes/web.php`.

Laravel applications may define important attack surfaces in:

```text
routes/web.php
routes/api.php
routes/channels.php
routes/console.php
custom route files
package routes
Livewire update endpoints
broadcast authentication endpoints
Horizon
Telescope
Pulse
health routes
Fortify routes
Sanctum routes
```

Generate the route table:

```bash
php artisan route:list --json
```

Fall back to:

```bash
php artisan route:list
```

Classify every meaningful route:

```text
PUBLIC
GUEST
AUTHENTICATED
ADMIN
API
WEBHOOK
SIGNED
UPLOAD
DOWNLOAD
AUTHENTICATION
PASSWORD RESET
VERIFICATION
INVITATION
OAUTH
BROADCASTING
INTERNAL TOOLING
DEBUG
HEALTH
```

Search specifically for:

```text
login
logout
register
password
forgot
reset
verify
verification
mfa
otp
2fa
magic
invite
accept
upload
attachment
media
document
file
import
export
download
admin
impersonate
webhook
callback
oauth
broadcasting
horizon
telescope
pulse
debug
health
preview
signed
temporary
```

Every route that mutates state must be investigated.

---

# Phase 2 - Dangerous GET Requests

GET and HEAD requests should retrieve information.

Search for GET routes which:

- delete data
- update data
- approve data
- log users out
- modify settings
- trigger payments
- send emails
- resend tokens
- perform imports
- perform exports
- execute actions

A GET request may be:

- preloaded
- crawled
- followed by scanners
- opened automatically
- triggered cross-site

State-changing operations should generally use:

```text
POST
PUT
PATCH
DELETE
```

with appropriate CSRF protection and authorisation.

Add regression tests where changing GET semantics represents a security boundary.

---
