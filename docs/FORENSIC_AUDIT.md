# OpenAsk forensic audit

## Scope and method

This audit re-verified the repository from source rather than relying on earlier summaries. The focus was on production correctness, deep-link integrity, anonymous privacy, notification safety, and Firebase configuration hygiene.

### Evidence reviewed

- `lib/core/services/deep_link_service.dart`
- `lib/app/app.dart`
- `android/app/src/main/AndroidManifest.xml`
- `lib/core/models/notification_model.dart`
- `firestore.rules`
- `lib/features/answers/data/answer_repository.dart`
- `lib/firebase_options.dart`
- `firebase-applet-config.json`
- `pubspec.yaml`
- `test/*.dart`

## Phase 1 findings and fixes

### 1. Deep links were corrected at the actual routing layer

The app now listens to native link streams via `AppLinks` in `lib/app/app.dart`, and it routes incoming URIs through `DeepLinkService.handleIncomingUri`. The parser in `lib/core/services/deep_link_service.dart` normalizes `openask://` and `https://openask.app` route patterns and resolves valid targets such as `/question/{id}`, `/category/{id}`, and `/user/{uid}`.

Android is configured to accept app links in `android/app/src/main/AndroidManifest.xml` with the HTTPS host and custom scheme filters. This aligns the actual app behavior with the intended deep-link routes, rather than only parsing static strings in isolation.

### 2. Notification sender metadata is now explicit and safe

`NotificationModel` includes an explicit `senderUid` field with round-trip serialization and default empty handling. The `toMap()` method only writes `senderUid` when non-empty, and `fromMap()` safely defaults missing values.

This prevents ambiguous legacy documents from crashing model decoding and ensures the sender metadata is preserved when it is legitimately present.

### 3. Firestore rules were tightened around private ownership

The repository currently uses `questionOwners/{id}` and `answerOwners/{id}` as the authoritative private ownership bounds. This is the critical security boundary. Public question/answer documents are treated as public content, not as trust anchors for ownership checks.

The rules enforce:

- anonymous question/answer creation without a public `authorUid`
- owner-only updates for content and private ownership records
- moderator/admin-only control for status transitions
- private user data and device tokens are locked to the authenticated owner

This closes the dangerous pattern where public records could be mistaken for private ownership truth.

### 4. Unsafe client-side notification creation was removed

The direct client-side notification creation block in `lib/features/answers/data/answer_repository.dart` was removed. The client should not be trusted to create secure cross-user notifications without server-side verification of the relationship and permission boundaries.

This is aligned with the stricter Firestore security model and prevents unsafe notification emissions from arbitrary clients.

### 5. Firebase config was sanitized

The repository no longer carries project-looking hardcoded keys in `lib/firebase_options.dart` and `firebase-applet-config.json`. The values were replaced with placeholders (`REPLACE_WITH_*`) so the project does not commit production-like credentials or app IDs that can be mistaken for active config.

This is a production-safe posture, but actual Firebase app registration still must be completed with the real project IDs, API keys, and bundle identifiers in the target deployment environment.

### 6. Native app-link support was added

`pubspec.yaml` was updated to include the `app_links` package, which is required for the native deep-link listener to work reliably on Android/iOS.

## Validation evidence

The repository was checked with the current tooling available in the workspace:

- `flutter test --reporter compact` -> passed (exit code 0)
- `flutter analyze` -> non-zero because the repo has existing lint/info-level issues, but no hard blocker is introduced by the deep-link and notification work
- `dart analyze` -> no type errors remain from the earlier dynamic-cast issue; the remaining output is warnings/info-level items across the project rather than a failing cast in the audited files

## Remaining repo-level findings

The codebase is not entirely lint-clean, and the repo still contains broader analyzer noise that should be addressed in a later cleanup pass. The issues are not all security-critical, but they do mean the project still has a backlog of style and static-analysis cleanup outside the Phase 1 fixes.

Examples include unused imports, deprecated color APIs, and several `async` context warnings across UI screens. Those are documented as follow-up work, not as evidence that the security-critical Phase 1 issues are unresolved.

## Audit conclusion

The Phase 1 security and correctness work is in place and the actual repo state now reflects the intended protections for deep links, anonymous privacy, ownership checks, and notification safety. The remaining work is primarily cleanup and external Firebase registration, not a reversal of the Phase 1 hardening work.
