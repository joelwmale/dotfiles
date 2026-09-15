---
name: react-native-due-diligence
description: Conduct a thorough due diligence check through a React Native project
---

# React Native Application Due Diligence

Use this skill when reviewing an existing React Native application before an agency takes responsibility for maintaining, supporting, upgrading, rescuing, or extending it.

The goal is to determine whether the application can be safely maintained and released by a new team.

Focus on:

* React Native and platform lifecycle risks;
* iOS and Android build viability;
* dependency health;
* code quality and maintainability;
* release and signing risks;
* native-module concerns;
* security and privacy;
* API reliability;
* performance;
* testing;
* knowledge-transfer requirements;
* likely future maintenance cost.

This is commercial and technical due diligence, not a stylistic code review.

## Review principles

Approach the repository as a senior React Native engineer taking ownership from another team.

Prioritise issues that could:

* prevent a release;
* break after an iOS or Android update;
* block React Native upgrades;
* expose customer information;
* cause app-store rejection;
* make builds irreproducible;
* create expensive ongoing maintenance;
* make the application unsafe to change.

Distinguish between:

* confirmed defects;
* serious risks;
* manageable technical debt;
* optional improvements;
* coding preferences.

Support findings with repository evidence.

Where information is unavailable, clearly state what could not be verified.

## Establish the application profile

Determine:

* React Native version;
* React version;
* Node version;
* package manager;
* package-manager version;
* TypeScript usage;
* iOS deployment target;
* Android minimum SDK;
* Android target SDK;
* Android compile SDK;
* Java or Kotlin versions;
* Gradle version;
* Android Gradle Plugin version;
* Xcode and Swift expectations;
* CocoaPods version;
* Hermes usage;
* New Architecture usage;
* Expo or bare React Native;
* Expo SDK version, if applicable;
* navigation library;
* state-management approach;
* API layer;
* authentication method;
* analytics;
* push notifications;
* crash reporting;
* over-the-air update mechanism;
* CI/CD;
* automated testing;
* release process.

Review:

* `package.json`;
* lock files;
* `ios/Podfile`;
* `Podfile.lock`;
* Xcode project settings;
* entitlements;
* privacy manifests;
* `Info.plist`;
* Android Gradle files;
* Android manifest;
* ProGuard or R8 rules;
* native source code;
* Babel configuration;
* Metro configuration;
* TypeScript configuration;
* environment handling;
* CI workflows;
* Fastlane configuration;
* app-store metadata or release scripts included in the repository.

## Framework and platform lifecycle

Assess whether the React Native version is:

* current enough to maintain safely;
* behind but manageable;
* significantly outdated;
* dependent on unsupported platform tooling;
* likely to fail future iOS or Android submissions.

Review for compatibility between:

* React Native;
* React;
* Node;
* Gradle;
* Android Gradle Plugin;
* Java;
* Kotlin;
* CocoaPods;
* Xcode;
* iOS deployment target;
* Android SDK targets;
* Expo SDK, where applicable.

Identify:

* major React Native upgrade gaps;
* deprecated React Native APIs;
* old native project structures;
* pre-autolinking package configuration;
* legacy architecture assumptions;
* obsolete Gradle syntax;
* unsupported Android target SDK;
* old iOS APIs;
* dependencies incompatible with modern Xcode;
* packages that do not support the New Architecture;
* upgrade blockers caused by custom native code.

Classify the upgrade as:

* routine;
* moderate;
* substantial;
* high-risk.

Consider dependency compatibility, native modifications, test coverage, build automation, and the size of the version gap.

## Dependency review

Review runtime and development dependencies.

Identify:

* abandoned packages;
* deprecated packages;
* packages no longer compatible with supported React Native versions;
* packages requiring manual native linking;
* native packages with limited maintenance;
* packages pinned to forks, branches, Git URLs, or local paths;
* packages with post-install patches;
* packages requiring modifications inside `node_modules`;
* duplicate libraries performing the same role;
* packages that substantially increase binary size;
* dependencies that require risky platform permissions;
* packages likely to fail during an Xcode, Gradle, or SDK upgrade;
* Expo packages incompatible with the current Expo SDK;
* libraries with unclear commercial licensing;
* apparently unused packages.

Review `patch-package` files carefully.

Treat a patch as a takeover concern when it:

* changes important runtime behaviour;
* fixes a build issue that could reappear on upgrade;
* is poorly documented;
* modifies an abandoned package;
* cannot be safely reapplied to newer versions.

Do not state that a package is abandoned or insecure unless this can be established. Flag packages requiring external verification where live package information is unavailable.

## Build reproducibility

Determine whether a new developer can produce working iOS and Android builds.

Review for:

* documented Node and package-manager versions;
* committed lock files;
* deterministic dependency installation;
* CocoaPods consistency;
* Ruby or Bundler configuration;
* Java version management;
* Gradle wrapper;
* environment-specific build configuration;
* hardcoded local file paths;
* undocumented native setup;
* missing configuration files;
* secrets required during compilation;
* manually installed SDKs;
* custom Xcode build phases;
* custom Gradle tasks;
* scripts that depend on developer machines;
* files excluded from source control but required to build.

Treat non-reproducible builds as a significant commercial risk.

## iOS review

Assess:

* Xcode project health;
* workspace and CocoaPods configuration;
* deployment target;
* bundle identifiers;
* build configurations;
* schemes;
* signing approach;
* capabilities;
* entitlements;
* associated domains;
* push notification configuration;
* keychain access groups;
* background modes;
* URL schemes;
* privacy usage descriptions;
* privacy manifests;
* app transport security exceptions;
* native Swift or Objective-C code;
* custom native modules;
* AppDelegate customisation;
* scene lifecycle handling;
* universal links;
* deep linking;
* build scripts;
* archive and release viability.

Look for:

* certificates or profiles tied to former developers;
* undocumented Apple Developer access requirements;
* missing App Store Connect ownership;
* expired signing assumptions;
* custom native changes likely to be overwritten during upgrades;
* broad permissions without clear need;
* incorrect privacy declarations;
* APIs likely to trigger App Store review concerns;
* dependencies that fail on current Xcode versions.

## Android review

Assess:

* application ID;
* namespace configuration;
* build variants;
* product flavours;
* signing configuration;
* keystore ownership;
* minimum, target, and compile SDK versions;
* Gradle wrapper;
* Android Gradle Plugin;
* Java and Kotlin compatibility;
* manifest permissions;
* intent filters;
* deep links;
* network security configuration;
* backup behaviour;
* exported components;
* foreground services;
* notification permissions;
* ProGuard and R8;
* native Java or Kotlin code;
* custom native modules;
* Google services configuration;
* Play Integrity or SafetyNet usage;
* release bundle configuration.

Look for:

* signing keys controlled by a former developer;
* secrets committed in Gradle files;
* release builds using debug configuration;
* outdated target SDK requirements;
* insecure exported activities or services;
* deprecated background execution patterns;
* dependencies using obsolete Android support libraries;
* missing obfuscation rules causing release-only crashes;
* architecture or ABI limitations;
* Play Console ownership concerns.

## Architecture and code quality

Assess whether the JavaScript or TypeScript application has understandable boundaries.

Review for:

* very large screens or components;
* business logic embedded directly in UI components;
* API calls spread throughout the component tree;
* duplicated state;
* duplicated business rules;
* inconsistent navigation patterns;
* deeply nested prop drilling;
* excessive global state;
* unclear ownership of server and local state;
* inconsistent state-management approaches;
* uncontrolled side effects;
* hooks with hidden or unstable dependencies;
* effects causing render loops;
* stale closure risks;
* unstable callbacks passed through large trees;
* inconsistent error handling;
* inconsistent loading states;
* race conditions;
* dead code;
* abandoned screens;
* old and new architectural patterns mixed together;
* JavaScript and TypeScript boundaries that reduce type safety;
* widespread `any`;
* ignored TypeScript errors;
* disabled linting;
* large numbers of suppression comments.

Do not penalise the application merely for not using a particular state-management library or folder structure.

Assess whether the existing approach is consistent, understandable, and safe to extend.

## React-specific concerns

Look for:

* incorrect effect dependencies;
* effects used for derived state;
* state duplicated from props;
* unstable list keys;
* expensive renders;
* unnecessary rerenders;
* missing memoisation only where performance impact is credible;
* context providers causing broad rerenders;
* async effects without cancellation;
* state updates after unmount;
* navigation actions from stale screens;
* event listeners not removed;
* timers not cleared;
* subscriptions not cleaned up;
* incorrect use of refs;
* hooks called conditionally;
* non-deterministic component behaviour.

Do not recommend memoisation everywhere. Only report it where there is evidence of a meaningful issue.

## Navigation and application state

Assess:

* navigation structure;
* nested navigator complexity;
* authentication transitions;
* deep-link handling;
* notification navigation;
* route typing;
* restoration after process termination;
* back-button behaviour;
* modal behaviour;
* logout and token-expiry flows.

Look for:

* inaccessible screens;
* invalid navigation states;
* duplicated screens across navigators;
* authentication state racing against navigation;
* deep links bypassing expected checks;
* sensitive screens remaining in navigation history after logout;
* route parameters trusted without validation.

## API and networking

Review:

* API client structure;
* base URL configuration;
* environment handling;
* authentication headers;
* token refresh;
* retry policy;
* request cancellation;
* timeouts;
* offline behaviour;
* connectivity handling;
* response validation;
* pagination;
* upload handling;
* error transformation;
* certificate pinning, if used;
* logging of request and response data.

Identify:

* API calls without timeouts;
* endless token-refresh loops;
* concurrent refresh race conditions;
* failed requests being retried unsafely;
* duplicate submissions;
* secrets embedded in the client;
* reliance on client-side checks for authorisation;
* sensitive information logged;
* responses trusted without shape validation;
* poor handling of API version changes;
* production and staging endpoints mixed together.

Remember that secrets distributed inside a mobile application cannot be treated as secret.

## Authentication and secure storage

Assess:

* credential storage;
* access-token storage;
* refresh-token storage;
* biometric authentication;
* keychain or keystore use;
* logout behaviour;
* token revocation;
* session expiry;
* device registration;
* password reset;
* invitation flows;
* multi-factor authentication;
* account switching.

Identify:

* sensitive tokens stored in AsyncStorage or other plaintext storage;
* tokens included in logs;
* authentication state retained after logout;
* app content visible in task-switcher previews where inappropriate;
* weak local access controls presented as server-side security;
* sensitive screens accessible through deep links without state checks.

## Security and privacy

Review for:

* hardcoded credentials;
* exposed API keys;
* personal information in logs;
* insecure local storage;
* screenshots containing sensitive information;
* unsafe WebViews;
* JavaScript enabled unnecessarily in WebViews;
* unvalidated WebView navigation;
* insecure deep links;
* overly broad permissions;
* clipboard exposure;
* insecure file storage;
* insecure database storage;
* weak certificate validation;
* disabled transport security;
* production debug menus;
* development endpoints included in release builds;
* analytics collecting sensitive fields;
* crash reports containing personal information.

Separate confirmed application issues from areas requiring backend, penetration, device, or infrastructure testing.

## Native modules and custom native code

Identify every custom or unusual native integration.

For each, assess:

* purpose;
* ownership;
* documentation;
* test coverage;
* dependency on private SDKs;
* compatibility with current tooling;
* compatibility with future React Native versions;
* New Architecture compatibility;
* likelihood of being overwritten during an upgrade;
* whether specialist iOS or Android knowledge is required.

Treat undocumented native modifications as a material takeover concern.

## Offline behaviour and persistence

Assess:

* local databases;
* AsyncStorage;
* persisted Redux or state stores;
* cached API data;
* offline queues;
* conflict resolution;
* migrations of local data;
* data encryption;
* behaviour after app upgrades;
* behaviour after logout;
* stale-data handling.

Look for:

* incompatible persistence migrations;
* corrupted-state recovery problems;
* personal data remaining after logout;
* offline actions replaying more than once;
* data conflicts silently overwriting server state.

## Push notifications, links, and background behaviour

Review:

* push provider;
* token registration;
* token refresh;
* notification permission flows;
* foreground handling;
* background handling;
* killed-state handling;
* notification routing;
* deep links;
* universal links;
* Android app links;
* background fetch;
* background location;
* foreground services.

Look for:

* duplicate device tokens;
* notifications opening the wrong screen;
* links bypassing authentication checks;
* background tasks that violate platform restrictions;
* unreliable assumptions about JavaScript execution while the app is terminated.

## Performance

Assess:

* startup time;
* bundle size;
* unnecessary synchronous startup work;
* large images;
* image caching;
* long lists;
* list virtualization;
* excessive rerenders;
* JavaScript-thread blocking;
* animation performance;
* bridge-heavy operations;
* memory leaks;
* retained event listeners;
* large local datasets;
* expensive parsing;
* slow navigation transitions;
* release-mode performance differences.

Avoid speculative performance claims without evidence.

Distinguish between likely user-facing problems and theoretical optimisation opportunities.

## Error handling and observability

Determine whether the team can diagnose production problems.

Review:

* crash reporting;
* handled-error reporting;
* source maps;
* native symbol uploads;
* release tracking;
* logging;
* breadcrumbs;
* API error visibility;
* user-facing fallback states;
* error boundaries;
* global error handlers;
* alerting;
* app-version reporting.

Look for errors that are swallowed, displayed only with generic alerts, or impossible to correlate with a specific release.

## Testing

Assess:

* unit tests;
* component tests;
* integration tests;
* end-to-end tests;
* iOS and Android coverage;
* critical workflow coverage;
* build validation;
* release smoke testing;
* test reliability;
* test setup documentation.

Pay attention to:

* authentication;
* onboarding;
* payments;
* bookings;
* messaging;
* uploads;
* push notifications;
* offline behaviour;
* deep links;
* permissions;
* account deletion;
* state restoration.

Do not use test count as a proxy for quality.

Classify the application safety net as:

* strong;
* reasonable;
* limited;
* effectively absent.

## CI/CD and release management

Review:

* CI workflows;
* build automation;
* Fastlane;
* EAS Build or EAS Submit;
* signing setup;
* secret management;
* environment selection;
* versioning;
* build numbers;
* release branches;
* source-map upload;
* symbol upload;
* automated tests;
* staged rollout;
* rollback options;
* over-the-air updates.

Identify:

* releases that can only be made from one developer's computer;
* undocumented manual steps;
* signing assets controlled by the former agency;
* production credentials stored locally;
* no reliable relationship between source commits and released binaries;
* unsafe OTA update practices;
* OTA updates capable of creating native and JavaScript version mismatches.

## Ownership and account access

Explicitly identify the accounts and assets the client must control:

* Apple Developer account;
* App Store Connect;
* Google Play Console;
* Android upload key;
* Android app-signing configuration;
* APNs keys or certificates;
* Firebase;
* Google Cloud;
* push-notification providers;
* analytics;
* crash reporting;
* deep-link providers;
* code-signing repositories;
* CI/CD accounts;
* Expo account;
* EAS project;
* OTA update service;
* domain and associated-link files;
* backend environments;
* third-party SDK accounts.

A technically healthy repository can still be a high-risk takeover if account ownership is unclear.

## Severity levels

For each finding, assign one severity.

### Critical

A current risk of:

* security compromise;
* privacy breach;
* inability to release the application;
* loss of signing or store access;
* major data loss;
* severe production failure;
* app-store removal.

### High

A serious concern likely to create:

* substantial upgrade difficulty;
* recurring production failures;
* inability to support modern iOS or Android versions;
* expensive specialist maintenance;
* unreliable releases;
* major support burden.

### Medium

A meaningful maintainability, reliability, performance, testing, or onboarding concern that should be planned.

### Low

A contained issue or worthwhile improvement with limited immediate business impact.

### Observation

Relevant context that is not itself a defect.

## Required output

Produce the report using this structure.

# React Native Due Diligence Report

## 1. Executive Summary

Provide a concise commercial and technical assessment.

Include:

* overall application health;
* whether both platforms appear buildable and releasable;
* takeover difficulty;
* framework and platform lifecycle position;
* major native or dependency risks;
* likely short-term stabilisation work;
* likely medium-term investment;
* whether the app is practical for a new agency to maintain.

Use one overall rating:

* Low Risk
* Low-to-Moderate Risk
* Moderate Risk
* Moderate-to-High Risk
* High Risk

## 2. Application Profile

Summarise:

* React Native version;
* React version;
* Expo or bare workflow;
* TypeScript position;
* navigation;
* state management;
* API approach;
* iOS platform details;
* Android platform details;
* major native modules;
* testing;
* CI/CD;
* release approach.

## 3. Immediate Red Flags

List only issues requiring urgent attention before or immediately after takeover.

For each include:

* severity;
* title;
* evidence;
* impact;
* recommended action.

## 4. Platform Viability

Provide separate assessments for:

### iOS

* build viability;
* signing;
* platform compatibility;
* app-store concerns;
* native risks.

### Android

* build viability;
* signing;
* SDK compliance;
* Play Store concerns;
* native risks.

Do not state that a platform is releasable unless the build and release configuration provides sufficient evidence.

## 5. Detailed Findings

Group findings under:

* Framework and Platform Lifecycle
* Dependencies
* Build Reproducibility
* iOS
* Android
* Architecture and Code Quality
* State and Navigation
* API and Authentication
* Security and Privacy
* Native Modules
* Offline Storage
* Push Notifications and Deep Links
* Performance
* Error Handling and Observability
* Testing
* CI/CD and Releases
* Account and Asset Ownership
* Documentation and Knowledge Transfer

For each finding include:

* severity;
* affected files or components;
* description;
* impact;
* recommendation;
* estimated remediation size: Small, Medium, Large, or Unknown.

Do not provide hour estimates unless explicitly requested.

## 6. Upgrade Assessment

Explain:

* current React Native lifecycle position;
* target version or upgrade direction;
* major dependency blockers;
* native-code blockers;
* likely iOS and Android tooling changes;
* New Architecture implications;
* likely upgrade complexity;
* recommended sequencing.

## 7. Maintainability Assessment

Explain:

* how confidently a new developer can change the application;
* consistency of architecture;
* TypeScript effectiveness;
* test safety net;
* native knowledge required;
* likely ongoing maintenance burden;
* areas dependent on former-developer knowledge.

## 8. Takeover Requirements

List what the agency needs before accepting release responsibility.

Include relevant items such as:

* App Store Connect access;
* Apple Developer access;
* Play Console access;
* signing keys;
* certificates;
* Firebase;
* environment values;
* backend access;
* CI/CD;
* Expo or EAS access;
* analytics;
* crash reporting;
* push-notification services;
* production API documentation;
* release history;
* former developer handover.

## 9. Recommended Plan

Organise recommendations into:

### Before Takeover

Ownership, access, signing, backups, security, and proof that builds can be produced.

### First 30 Days

Build reproduction, release rehearsal, observability, critical fixes, and documentation.

### Next 90 Days

Framework upgrades, dependency remediation, testing, and architectural improvements.

### Longer Term

Strategic improvements that reduce ongoing maintenance cost.

## 10. Positive Findings

Identify code, architecture, platform configuration, tests, automation, or documentation that is genuinely strong.

## 11. Unknowns and Limitations

Clearly state what could not be verified.

## 12. Final Recommendation

Choose one:

* Safe to take over in its current state.
* Safe to take over with a defined stabilisation phase.
* Take over only after critical conditions are addressed.
* High-risk takeover requiring commercial protections.
* Do not accept release responsibility without substantial remediation or further investigation.

Explain the recommendation in practical agency terms.

## Behaviour requirements

Be direct, commercially aware, and fair.

Do not exaggerate harmless technical debt.

Do not report normal React Native platform complexity as a defect.

Do not automatically recommend a rewrite because the application is outdated.

Do not assume a successful development build means the app can be released.

Do not assume repository access means the client owns signing keys, store accounts, or third-party services.

Focus on whether a new agency can reliably build, release, diagnose, upgrade, and maintain the application.
