# Phase 1 security architecture summary

## Design goal

The Phase 1 work focused on correctness and production safety, not on feature expansion. The intent was to ensure the app does not trust public documents for private ownership, does not accept unsafe deep-link routes, and does not create security-sensitive notifications from client code.

## Core rules

### 1. Private ownership is authoritative

The app reports ownership through private documents in:

- `questionOwners/{questionId}`
- `answerOwners/{answerId}`

These documents are the trust boundary. The public question/answer documents remain readable by all clients, but they are not used as proof of personal ownership. This preserves anonymous-posting privacy and prevents insecure fallback checks.

### 2. Anonymous content is private by default

The Firestore rules require that anonymous content omit `authorUid` from the public document. This ensures the public doc does not reveal the identity of the author while still allowing the system to maintain an internal private ownership record.

### 3. Deep links are canonicalized before navigation

`DeepLinkService` normalizes incoming URIs to a small set of supported routes. It only accepts known route types and prevents accidental navigation to arbitrary invalid internal states generated from untrusted external URLs.

### 4. Safe notification metadata is explicit

`NotificationModel.senderUid` is optional, defaults to an empty string, and is written only when present. This avoids broken or ambiguous data and makes the notification payload safe to serialize and deserialize.

### 5. Client-side notification writes are prohibited

The answer repository no longer emits notifications directly in the client. This is a deliberate hardening step because client code cannot reliably verify all trust constraints required to create a legitimate cross-user notification.

### 6. Secrets and app config are sanitized

The repo now contains placeholder Firebase information instead of real-looking project values. This reduces the risk of accidentally leaking environment-specific configuration or credentials in source control.

## Remaining external requirements

The application still needs the actual Firebase project registration, Google Services config, and deployment-specific secrets to be installed in the live environment. Those are operational security requirements, not code-level fixes.

## Validation status

- `flutter test --reporter compact` passed
- static analysis is not fully clean yet, but the remaining findings are broad project hygiene warnings rather than a Phase 1 security regression

## Outcome

The repo now has the correct Phase 1 structure for a secure and coherent deployment baseline: private ownership enforcement, anonymous privacy checks, safe deep-link parsing, explicit notification metadata, and sanitized Firebase config artifacts.
