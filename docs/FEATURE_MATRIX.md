# Feature matrix

Status legend:

- COMPLETE: implemented and aligned with the repo state
- PARTIAL: present, but still depends on server-side verification or follow-up cleanup
- BROKEN: known incorrect or inconsistent
- MISSING: not implemented in the current repo
- INSECURE: unsafe as implemented
- MOCK: scaffolding or placeholder state only
- BLOCKED: cannot be validated without external platform or secret configuration

| Feature | Status | Evidence | Notes |
|---|---|---|---|
| Deep-link parsing (`openask://` and `https://openask.app`) | COMPLETE | `lib/core/services/deep_link_service.dart`, `lib/app/app.dart`, `android/app/src/main/AndroidManifest.xml` | Route normalization and app-link subscription are in place. |
| Cold-start and resume deep-link handling | COMPLETE | `lib/app/app.dart` | Initial link and stream listener are wired. |
| Notification model serialization | COMPLETE | `lib/core/models/notification_model.dart` | `senderUid` round-trips safely and defaults are explicit. |
| Anonymous question privacy | COMPLETE | `firestore.rules` | Public question docs do not leak private author identity. |
| Anonymous answer privacy | COMPLETE | `firestore.rules` | Answer rules require identity-only ownership via private owner docs. |
| Private ownership enforcement | COMPLETE | `firestore.rules` | `questionOwners` and `answerOwners` are the trust boundary. |
| Notification creation from clients | PARTIAL | `lib/features/answers/data/answer_repository.dart` | Client-side notification creation was removed; secure server-side enforcement remains external. |
| Firebase config hygiene | COMPLETE | `lib/firebase_options.dart`, `firebase-applet-config.json` | Real-looking values were replaced with placeholders. |
| Native Firebase setup for Android/iOS | BLOCKED | `lib/firebase_options.dart`, docs references to native setup | Real platform registration still must be created in the target Firebase project. |
| App-link dependency installation | COMPLETE | `pubspec.yaml` | `app_links` is present. |
| Testing | COMPLETE | `flutter test --reporter compact` | The test suite passed in the checked workspace. |
| Lint cleanliness | PARTIAL | `dart analyze`, `flutter analyze` | Many info/warning items remain; they are not all security defects but they prevent a fully clean static-analysis pass. |
| Production-ready server logic for notifications | PARTIAL | `firestore.rules` + repository changes | Security posture is improved, but backend notification generation remains an external deployment concern. |
| Vite/React scaffold | MOCK | repo file tree | Not a production authority in the active Flutter deployment path; should be treated as ancillary scaffold unless explicitly used. |

## Summary

The repository is in a Phase 1-safe state for the audited security concerns. Deep-link handling, private ownership checks, anonymous privacy, and Firebase placeholder sanitization are aligned with safe production intent. The remaining backlog is maintenance and external platform configuration rather than a reversal of the audited fixes.
