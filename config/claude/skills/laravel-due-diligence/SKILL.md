---
name: laravel-due-diligence
description: Conduct a thorough due diligence check through a Laravel application
---

# Laravel Application Due Diligence

Use this skill when reviewing an existing Laravel application before an agency takes responsibility for maintaining, supporting, extending, rescuing, or rebuilding it.

The goal is not to critique every stylistic choice. The goal is to identify:

* material technical risks;
* security or data integrity concerns;
* code that will be difficult or expensive to maintain;
* barriers to onboarding a new development team;
* future upgrade concerns;
* operational and deployment risks;
* areas where the client may face unexpected cost;
* whether the application is safe and practical for the agency to take over.

## Review principles

Approach the review as an experienced Laravel technical lead conducting commercial due diligence.

Prioritise findings based on their practical impact.

Do not report minor formatting preferences as major concerns.

Do not recommend rebuilding simply because the code is unfamiliar or imperfect.

Distinguish between:

* objectively dangerous code;
* genuine maintainability concerns;
* technical debt that can be managed;
* optional improvements;
* personal preference.

Where possible, reference exact files, classes, methods, packages, configuration, or code patterns.

Do not make assumptions that cannot be supported by the repository.

If infrastructure, production configuration, database access, deployment pipelines, external services, or environment variables are unavailable, clearly state that those areas could not be verified.

## Begin by establishing context

Identify:

* Laravel version;
* PHP version and required extensions;
* application purpose;
* repository structure;
* major domains or modules;
* authentication approach;
* tenancy model, if applicable;
* database technology;
* queue technology;
* cache and session technology;
* file storage;
* search providers;
* payment providers;
* major third-party integrations;
* frontend technology;
* deployment and hosting configuration;
* automated test coverage;
* CI/CD configuration.

Review:

* `composer.json`;
* `composer.lock`;
* `package.json`;
* `.env.example`;
* application configuration;
* service providers;
* route files;
* middleware;
* models;
* migrations;
* controllers;
* actions and services;
* jobs;
* commands;
* listeners;
* policies;
* requests;
* resources;
* tests;
* deployment files;
* Docker configuration;
* CI workflows;
* infrastructure configuration included in the repository.

## Laravel and PHP versions

Determine whether the Laravel and PHP versions are:

* currently supported;
* approaching end of support;
* already unsupported;
* preventing package or infrastructure upgrades.

Check for:

* large Laravel version gaps;
* deprecated Laravel APIs;
* deprecated PHP syntax or behaviour;
* upgrade blockers;
* tightly coupled framework internals;
* overwritten vendor behaviour;
* old authentication scaffolding;
* legacy Laravel Mix builds;
* outdated queue, mail, filesystem, or broadcasting configuration.

Explain the likely difficulty of upgrading.

Classify an upgrade as:

* routine;
* moderate;
* substantial;
* high-risk.

Do not classify an upgrade based only on version numbers. Consider application size, test coverage, package compatibility, framework customisation, and use of deprecated behaviour.

## Dependency review

Review production and development dependencies.

Identify:

* abandoned packages;
* unmaintained packages;
* packages with known security concerns;
* packages pinned to old versions;
* packages blocking Laravel or PHP upgrades;
* packages installed from forks or custom repositories;
* packages used for functionality that Laravel now provides natively;
* overlapping packages serving the same purpose;
* packages whose usage is deeply embedded throughout the application;
* private packages that may not remain accessible;
* packages requiring commercial licences;
* packages present in `composer.json` but apparently unused;
* code that depends on undocumented behaviour in a package.

Check whether lock files are committed and consistent.

Do not state that a package is abandoned or insecure without evidence available from the repository or dependency metadata. Where live package information is unavailable, identify it as requiring external verification.

## Architecture and code organisation

Assess whether the application has understandable boundaries and predictable conventions.

Review for:

* controllers containing substantial business logic;
* very large models;
* large service classes with unrelated responsibilities;
* duplicated business rules;
* circular dependencies;
* unclear module boundaries;
* excessive global helpers;
* excessive static access;
* service container misuse;
* unnecessary repositories or abstractions;
* domain logic coupled directly to HTTP requests;
* domain logic coupled directly to Eloquent persistence;
* actions with hidden side effects;
* business processes spread across observers, events, jobs, and model hooks;
* inconsistent approaches to similar features;
* dead or abandoned code paths;
* commented-out code;
* temporary fixes that became permanent;
* unexplained feature flags;
* multiple generations of architecture existing side by side.

Pay special attention to code that is technically functional but difficult for a new team to reason about safely.

## Laravel-specific concerns

Review for problematic use of:

* model observers;
* global scopes;
* accessors and mutators with side effects;
* boot methods;
* route model binding;
* service providers;
* facades;
* macros;
* queued jobs;
* event listeners;
* scheduled commands;
* middleware;
* policies and gates;
* traits;
* casts;
* custom authentication guards;
* custom database connections;
* multi-tenancy logic;
* morph relationships;
* pivot models;
* database transactions.

Identify hidden behaviour that would surprise a developer making an apparently unrelated change.

Look for:

* queries triggered by serialization;
* accessors performing database queries;
* model events creating external side effects;
* jobs dispatched before transactions commit;
* jobs receiving unserialisable or unstable data;
* jobs without retry or failure handling;
* scheduled tasks that can overlap;
* commands that are not idempotent;
* external calls made synchronously during user requests;
* route closures containing production logic;
* logic placed in Blade templates;
* direct environment-variable access outside configuration files.

## Database and data integrity

Review migrations, models, queries, relationships, and write operations.

Identify:

* missing foreign keys;
* missing unique constraints;
* nullable fields that appear operationally required;
* inconsistent enum or status values;
* string statuses spread throughout the codebase;
* unsafe schema changes;
* destructive migrations;
* migrations that cannot run safely on a large production database;
* missing indexes;
* indexes that do not match common query patterns;
* N+1 query risks;
* unbounded queries;
* loading large datasets into memory;
* `SELECT *` usage in performance-critical paths;
* race conditions;
* duplicate record risks;
* missing transactions;
* transactions held open during external API calls;
* reliance on application validation without database constraints;
* soft-delete inconsistencies;
* timezone inconsistencies;
* money stored using floating-point types;
* data transformations that may lose precision;
* identifiers exposed sequentially where that creates a concern.

Flag any operation that could silently corrupt, duplicate, delete, or misattribute customer data.

## Security

Review for:

* missing authorisation;
* authentication bypasses;
* insecure direct object references;
* mass-assignment risks;
* unsafe file uploads;
* unrestricted file types;
* public storage of private documents;
* path traversal;
* SQL injection;
* raw queries using interpolated input;
* command injection;
* unsafe deserialization;
* cross-site scripting;
* unescaped HTML;
* CSRF bypasses;
* insecure webhook handling;
* missing webhook signature verification;
* replayable webhooks;
* secrets committed to the repository;
* sensitive data logged;
* personal information exposed in exceptions;
* overly permissive CORS;
* weak password or token handling;
* tokens stored in plaintext;
* insecure reset or invitation flows;
* missing rate limiting;
* privilege escalation paths;
* administrative routes exposed without appropriate controls;
* debug tooling accessible in production;
* unsafe impersonation functionality.

Do not claim the application is secure merely because no obvious issue was found.

Separate confirmed vulnerabilities from areas requiring penetration testing or infrastructure verification.

## External integrations

Identify all external systems and assess:

* how credentials are managed;
* whether timeouts are configured;
* whether failures are retried;
* whether retries can duplicate actions;
* whether idempotency is implemented;
* whether responses are validated;
* whether API version changes may break the integration;
* whether webhook authenticity is verified;
* whether integration code is isolated;
* whether there are useful logs and failure alerts;
* whether sandbox and production environments are separated;
* whether a vendor dependency represents a business continuity risk.

Pay particular attention to:

* payments;
* accounting;
* fulfilment;
* messaging;
* email;
* identity providers;
* CRMs;
* healthcare systems;
* government systems;
* file transfer;
* scheduled imports and exports.

## Queues and background processing

Determine:

* queue driver;
* number and purpose of queues;
* worker configuration;
* retry policy;
* failed-job handling;
* timeout configuration;
* job uniqueness;
* idempotency;
* monitoring;
* Horizon configuration, if used;
* whether long-running tasks occur synchronously.

Look for:

* jobs that can run twice and create duplicate outcomes;
* jobs that silently fail;
* jobs retrying permanent failures;
* large models or payloads serialized into jobs;
* stale model state;
* jobs dependent on request-scoped data;
* missing `afterCommit` behaviour where required;
* queue priorities that could starve critical work;
* no mechanism to replay or reconcile failed integrations.

## Performance and scalability

Identify current or likely bottlenecks.

Review for:

* N+1 queries;
* repeated expensive queries;
* missing eager loading;
* unbounded exports;
* large synchronous reports;
* excessive API calls;
* ineffective caching;
* unsafe cache invalidation;
* session affinity assumptions;
* application state stored on a single server;
* local filesystem dependence;
* long-running HTTP requests;
* memory-heavy collection operations;
* large database tables without suitable indexes;
* expensive observers or accessors;
* repeated rendering or serialization work;
* queue workloads that cannot scale independently.

Avoid speculative claims about scale. Explain the conditions under which an issue would become material.

## Testing

Assess:

* whether tests exist;
* test types;
* meaningful coverage of critical business workflows;
* reliability of the tests;
* whether tests can run locally;
* test isolation;
* use of production-like services;
* excessive mocking;
* brittle assertions;
* missing tests around payments, permissions, calculations, imports, exports, and state transitions.

Do not use test count as a proxy for quality.

Determine whether the test suite gives an incoming agency enough confidence to change the application safely.

Classify the safety net as:

* strong;
* reasonable;
* limited;
* effectively absent.

## Developer experience and maintainability

Assess whether a competent Laravel developer can:

* install the application;
* understand required services;
* obtain safe development data;
* run migrations;
* run tests;
* run queues;
* run scheduled tasks;
* build frontend assets;
* understand deployment;
* diagnose failures.

Review documentation for accuracy rather than mere existence.

Identify undocumented setup steps, hidden dependencies, hardcoded paths, machine-specific configuration, and reliance on knowledge held by the previous developer.

## Deployment and operations

Review any available deployment configuration.

Assess:

* deployment reproducibility;
* zero-downtime safety;
* migration safety;
* rollback strategy;
* environment separation;
* secret management;
* worker restarts;
* scheduler configuration;
* cache clearing;
* asset building;
* health checks;
* backups;
* log aggregation;
* exception monitoring;
* uptime monitoring;
* queue monitoring;
* database monitoring;
* alerting;
* disaster recovery.

Highlight where operational conclusions cannot be made from application code alone.

## Code quality classification

For each finding, assign one severity:

### Critical

A current risk of:

* security compromise;
* data loss or corruption;
* material privacy breach;
* incorrect financial outcomes;
* major production outage;
* inability to operate or deploy safely.

### High

A serious concern likely to cause:

* expensive incidents;
* unreliable releases;
* major upgrade difficulty;
* repeated production failures;
* substantial support burden;
* inability for the agency to maintain the application confidently.

### Medium

A meaningful maintainability, reliability, performance, or onboarding issue that should be planned and addressed.

### Low

A contained issue or worthwhile improvement with limited immediate business impact.

### Observation

Relevant context that is not itself a defect.

## Required output

Produce a due diligence report using the following structure.

# Laravel Due Diligence Report

## 1. Executive Summary

Provide a concise commercial and technical assessment.

Include:

* overall health;
* takeover difficulty;
* most serious risks;
* likely short-term stabilisation work;
* likely medium-term investment;
* whether the application appears maintainable;
* whether there is any reason the agency should not take responsibility for it.

Use one overall rating:

* Low Risk
* Low-to-Moderate Risk
* Moderate Risk
* Moderate-to-High Risk
* High Risk

## 2. Application Profile

Summarise:

* Laravel version;
* PHP version;
* frontend stack;
* database;
* queues;
* cache;
* hosting and deployment information available;
* major integrations;
* test position;
* notable architectural patterns.

## 3. Immediate Red Flags

List only the issues that need urgent attention before or immediately after takeover.

For each issue include:

* severity;
* title;
* evidence;
* business or technical impact;
* recommended action.

## 4. Detailed Findings

Group findings under:

* Security
* Framework and PHP Lifecycle
* Dependencies
* Architecture and Code Quality
* Database and Data Integrity
* Integrations
* Queues and Scheduled Work
* Performance and Scalability
* Testing
* Deployment and Operations
* Developer Experience
* Documentation and Knowledge Transfer

For each finding include:

* severity;
* affected files or components;
* description;
* impact;
* recommendation;
* estimated remediation size: Small, Medium, Large, or Unknown.

Do not provide hour estimates unless explicitly requested.

## 5. Upgrade and Lifecycle Assessment

Explain:

* current support status;
* required Laravel and PHP upgrades;
* major package blockers;
* likely upgrade complexity;
* recommended sequencing.

## 6. Takeover Risks

Explain what the incoming agency needs before accepting full responsibility.

Examples include:

* production access;
* hosting access;
* error monitoring;
* third-party credentials;
* database backups;
* deployment documentation;
* former developer handover;
* vendor account ownership;
* test data;
* infrastructure diagrams;
* known incident history.

## 7. Recommended Plan

Organise recommendations into:

### Before Takeover

Access, backups, ownership, security, and critical operational protections.

### First 30 Days

Critical fixes, observability, deployment confidence, documentation, and stabilisation.

### Next 90 Days

High-value maintainability, lifecycle, testing, and architectural work.

### Longer Term

Strategic improvements that are valuable but not urgent.

## 8. Positive Findings

Call out code, architecture, tests, documentation, or operational practices that are genuinely strong.

## 9. Unknowns and Limitations

Clearly state what could not be verified.

## 10. Final Recommendation

Choose one:

* Safe to take over in its current state.
* Safe to take over with a defined stabilisation phase.
* Take over only after critical conditions are addressed.
* High-risk takeover requiring commercial protections.
* Do not take responsibility without substantial remediation or further investigation.

Explain the reasoning in practical agency terms.

## Behaviour requirements

Be direct but fair.

Do not exaggerate findings to make the report sound valuable.

Do not bury severe findings beneath minor code-quality comments.

Do not produce a generic Laravel checklist without inspecting the actual repository.

Do not describe normal Laravel conventions as problems.

Do not demand perfect architecture.

Focus on whether the application can be safely understood, operated, changed, and supported by a new agency.
