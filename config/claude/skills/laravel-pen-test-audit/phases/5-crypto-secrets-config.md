# Phase 24 - Cryptography

Search for custom cryptography.

Look for:

```text
openssl_encrypt
openssl_decrypt
sodium
AES
cipher
encrypt
decrypt
IV
nonce
key derivation
```

Strongly prefer established Laravel or reputable cryptography libraries.

Avoid custom encryption schemes.

## Disabled TLS verification

Search config and code for switched-off certificate or hostname checks:

```bash
rg -n -i "verify_peer|verify_peer_name|allow_self_signed|verify.?=>\s*false|withoutVerifying|CURLOPT_SSL_VERIFY|SSL_VERIFY_SERVER_CERT|'verify'\s*=>|sslmode|ssl_mode|stream_context" config app bootstrap
```

Typical hits:

```text
config/database.php   redis 'context' => ['ssl' => ['verify_peer' => false, 'verify_peer_name' => false]]
config/database.php   MySQL PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false, Postgres sslmode=require
config/mail.php       SMTP stream options with verify_peer false
Http::withoutVerifying(), Guzzle 'verify' => false
```

These are often copied from a managed-Redis tutorial to make a self-signed or hostname-mismatched
endpoint "just work". With verification off, TLS gives no protection against an active
man-in-the-middle, and for Redis that includes cache and **queue** payloads (PHP-serialised job
objects), which makes tampering a deserialisation concern. Rate it LOW unless the network path is
untrusted or the data is sensitive, state what you could not establish (effective URL, whether TLS
is used at all, network isolation), and recommend enabling verification with the provider's CA
bundle and the correct hostname. Never leave `Http::withoutVerifying()` in non-test code.

Check:

- random IV/nonce per encryption operation
- authenticated encryption
- key storage
- key rotation
- deterministic encryption only where explicitly required

The Canary audit identified a custom encryption implementation that derived and reused an IV from an MD5 hash, undermining the intended encryption properties.

If encrypted data must be searchable, investigate appropriate cryptographic indexing rather than reusing IVs or creating deterministic encryption without understanding the security trade-offs.

---

# Phase 25 - Secure Randomness

Search:

```bash
rg 'md5\(|sha1\(|uniqid\(|rand\(|mt_rand\(|tempnam\(|str_shuffle\(|shuffle\(|array_rand\(' app routes
```

These functions are not automatically vulnerabilities.

Determine whether the value is security-sensitive.

Security-sensitive randomness includes:

```text
verification codes
passwords
API keys
reset tokens
invite tokens
secret URLs
recovery codes
nonces
```

Prefer:

```php
random_int()
Str::random()
Str::password()
random_bytes()
```

as appropriate.

The previous Canary audit found `rand(100000, 999999)` being used for verification codes.

---

# Phase 26 - Secrets and Git History

Scanning the current working tree is NOT enough.

Inspect Git history.

Use tooling such as:

```text
Gitleaks
TruffleHog
```

where available.

Look for:

```text
API keys
database credentials
AWS keys
OAuth secrets
email provider credentials
payment secrets
JWT secrets
private keys
.env files
.env.example
service-account files
```

Report locations without printing secret values.

A secret removed from the current branch may remain available in Git history.

If a real secret was ever committed:

1. treat it as compromised
2. rotate/revoke it
3. remove it from current code
4. consider Git history cleanup where appropriate

The Canary audit found active credentials in repository history, including credentials originally committed in `.env.example`.

---

# Phase 27 - PII and Production Data in Source Control

Search repositories for information that looks like:

```text
customer exports
CSV imports
SQL dumps
email lists
phone numbers
addresses
prescriptions
health data
test fixtures copied from production
database snapshots
```

Production PII should not be casually copied into:

```text
Git
development
staging
fixtures
CI artifacts
developer laptops
```

The Canary audit found sensitive information inside a committed CSV file.

Review both current files and Git history.

---

# Phase 28 - Configuration Exposure

Validate security-critical configuration during application boot where appropriate.

Look for:

```text
missing signing secrets
blank webhook keys
placeholder API secrets
incorrect environment
unsafe defaults
```

A production application should fail clearly rather than silently run with missing critical security configuration.

Never print secret configuration values.

---

# Phase 29 - Internal Laravel Tooling

Explicitly enumerate:

```text
/horizon
/telescope
/pulse
/_ignition
debugbar
health endpoints
queue dashboards
admin dashboards
```

Test as:

```text
unauthenticated user
ordinary authenticated user
wrong tenant
administrator
```

The Canary audit previously found Horizon accessible to ordinary authenticated users, exposing queued jobs and potentially sensitive data.

Do not rely solely on:

```text
APP_ENV
IP restrictions
security through obscurity
```

Verify actual authorisation.

---

# Phase 30 - Error and Debug Information

Trigger safe errors.

Test:

```text
invalid model IDs
invalid JSON
invalid enums
bad file uploads
bad signatures
expired tokens
missing records
invalid webhook payloads
```

Production responses must not expose:

```text
stack traces
database queries
filesystem paths
environment variables
credentials
internal network addresses
secrets
```

Check:

```text
APP_DEBUG=false
APP_ENV=production
```

but also test actual responses.

---
