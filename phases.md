# Implementation Phases

---

## Phase 1 — Foundation & Authentication ✅
**Goal:** Project scaffolding, design system, and working auth flow.

### Deliverables
- `pubspec.yaml` with all dependencies pinned
- Folder structure (core / data / domain / presentation)
- `AppColors`, `AppTextStyles`, `AppTheme` (light + dark)
- `go_router` navigation with auth redirect
- `Dio` HTTP client with auth interceptor
- `SharedPreferences` wrapper (`LocalStorage`)
- Login screen (gradient hero, validation, loading state)
- `AuthNotifier` (AsyncNotifier) — login, logout, token persistence
- Reusable `AppButton`, `AppTextField`, `AppLoading`, `AppErrorView`

**Done when:** A user can log in with DummyJSON credentials, the token is persisted, and the app redirects correctly on cold start.

---

## Phase 2 — Chat Rooms & User Directory 🔄
**Goal:** Home screen with room list, online users, and message history.

### Deliverables
- `UsersApi` — fetch users from DummyJSON `/users`
- `UserEntity`, `ChatRoomEntity`, `MessageEntity` — domain models
- Simulated online/offline status (deterministic random from user ID)
- `HomeNotifier` — generates group rooms + DM rooms from user list
- Home screen:
  - Header with current user avatar + name + dark-mode toggle
  - Search bar (client-side filter)
  - "Online Now" horizontal scroller (`OnlineUsersBar`)
  - Chat room list (`ChatRoomTile` — unread badge, last message preview)
- `UserAvatar` — initials fallback, online status ring
- Mock message history generator (deterministic by roomId seed)

**Done when:** Home screen loads with rooms and online users; tapping a room shows the chat screen with pre-populated history.

---

## Phase 3 — Real-Time Chat & WebSocket 🔜
**Goal:** Full real-time messaging experience.

### Deliverables
- `WebSocketService` (`Notifier`) — connect, send, stream messages, auto-reconnect
- `ChatNotifier` (family `Notifier`) — per-room message state
- Chat screen:
  - Bubble layout (my messages right-aligned, others left-aligned)
  - Avatar + name for each sender (grouped by sender/time)
  - Message timestamp
  - Delivery status icon (sending / sent / delivered)
  - Auto-scroll to latest message
- `MessageInputBar` — text field, send button, typing event dispatch
- `TypingIndicatorWidget` — animated dots, "X is typing…"
- Simulated other-user activity (typing + message after delay)
- Local message cache (SharedPreferences, restored on re-enter)
- Connection lost banner with reconnecting state

**Done when:** Messages send in real time, typing indicator appears, delivery receipts update, and messages survive a chat screen re-entry.

---

## Dependency Summary

```yaml
flutter_riverpod: ^2.5.1   # State management
go_router: ^14.2.7         # Navigation
dio: ^5.4.3                # HTTP
web_socket_channel: ^3.0.1 # WebSocket
shared_preferences: ^2.2.3 # Local storage
intl: ^0.19.0              # Date formatting
uuid: ^4.4.0               # Message IDs
```
