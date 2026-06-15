# Teams Chat — Real-Time Flutter Chat App

A production-grade real-time team chat application built as an interview task. Demonstrates clean architecture, Riverpod state management, WebSocket communication, and a polished Material 3 UI.

---

## Screenshots

| Login | Home | Chat |
|-------|------|------|
| Gradient hero, demo credentials hint | Online users bar, room list, dark mode toggle | Message bubbles, typing indicator, delivery status |

---

## Features

- **Authentication** — Login via DummyJSON REST API with token persistence
- **Chat Rooms** — 4 group channels + 5 DM rooms generated from the user directory
- **Online / Offline Status** — User presence ring indicators throughout the UI
- **Real-Time Messaging** — WebSocket connection with optimistic UI updates
- **Message Delivery Status** — `sending → sent → delivered` lifecycle with icons
- **Typing Indicator** — Animated bouncing dots with contextual label ("X is typing…")
- **Message History** — Deterministic mock history per room, cached locally
- **Dark Mode** — Full light/dark theme toggle, persisted across sessions
- **Auto-Reconnect** — WebSocket reconnects automatically (up to 5 attempts, 3 s delay)
- **Local Cache** — Messages survive screen re-entry via SharedPreferences

---

## Tech Stack

| Layer | Library | Version |
|-------|---------|---------|
| State management | `flutter_riverpod` | ^2.5.1 |
| Navigation | `go_router` | ^14.2.7 |
| HTTP | `dio` | ^5.4.3 |
| WebSocket | `web_socket_channel` | ^3.0.1 |
| Local storage | `shared_preferences` | ^2.2.3 |
| Date formatting | `intl` | ^0.19.0 |
| Message IDs | `uuid` | ^4.4.0 |

---

## Architecture

Clean architecture with four layers. No layer imports anything above it.

```
lib/
├── core/                          # Shared infrastructure
│   ├── constants/                 # AppConstants, ApiConstants, StorageKeys
│   ├── errors/                    # Sealed AppException hierarchy
│   ├── network/                   # DioClient (auth interceptor), WebSocketService
│   ├── router/                    # AppRouter (go_router + auth redirect)
│   ├── theme/                     # AppColors, AppTextStyles, AppTheme, ThemeModeNotifier
│   └── utils/                     # DateFormatter, StringExtensions
│
├── data/                          # Data layer
│   ├── datasources/
│   │   ├── local/                 # LocalStorage (typed SharedPreferences wrapper)
│   │   └── remote/                # AuthApi, UsersApi (Dio)
│   ├── models/                    # UserModel, MessageModel (JSON serde, extend entities)
│   └── repositories/              # AuthRepository, ChatRepository
│
├── domain/                        # Business logic — pure Dart, zero framework deps
│   └── entities/                  # UserEntity, MessageEntity, ChatRoomEntity
│
└── presentation/                  # UI layer
    ├── features/
    │   ├── auth/                  # LoginScreen, LoginFormWidget, AuthNotifier
    │   ├── home/                  # HomeScreen, ChatRoomTile, OnlineUsersBar, HomeNotifier
    │   └── chat/                  # ChatScreen, MessageBubble, MessageInputBar,
    │                              # TypingIndicatorWidget, ChatNotifier
    └── shared/
        └── widgets/               # AppButton, AppTextField, AppLoading,
                                   # AppErrorView, UserAvatar
```

### State Management (Riverpod 2.x)

| Provider | Type | Responsibility |
|----------|------|----------------|
| `authProvider` | `AsyncNotifierProvider` | Login, logout, cold-start session restore |
| `themeModeProvider` | `NotifierProvider` | Light/dark toggle, persisted to SharedPreferences |
| `homeProvider` | `AsyncNotifierProvider` | Fetch users, build rooms, client-side search |
| `chatProvider(roomId)` | `NotifierProvider.family` | Per-room messages, WebSocket, typing, simulation |
| `webSocketProvider` | `NotifierProvider` | Connection lifecycle, message broadcast stream |
| `appRouterProvider` | `Provider` | GoRouter wired to auth stream via `refreshListenable` |

---

## APIs

| Purpose | Endpoint | Method |
|---------|----------|--------|
| Login | `https://dummyjson.com/auth/login` | POST |
| User directory | `https://dummyjson.com/users?limit=20` | GET |
| Real-time | `wss://echo.websocket.events` | WebSocket |

> The WebSocket echo server mirrors every sent frame back. The app detects its own echoed messages by ID and upgrades them from `sent → delivered` instead of inserting duplicates.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.4.0
- Dart SDK ≥ 3.4.0

### Run

```bash
git clone <repo-url>
cd teams-chat
flutter pub get
flutter run
```

### Demo Credentials

```
Username : emilys
Password : emilyspass
```

These are shown as a hint on the login screen.

---

## Project Docs

| File | Description |
|------|-------------|
| [PRD.md](PRD.md) | Full product requirements, WebSocket protocol, delivery flow |
| [phases.md](phases.md) | 3-phase implementation plan with task checklists |

---

## Commit History

Each commit maps to one architectural slice:

```
feat: add app entry point (main.dart)
feat(chat): real-time chat, WebSocket, typing indicator, delivery status
feat(home): room list, online users bar, home provider
feat(auth): login screen, provider, form widget
feat(ui/shared): reusable widget library
feat(data): datasources, models, repositories
feat(domain): pure Dart entities
feat(core): constants, errors, network, router, theme, utils
docs: PRD, phases, pubspec, analysis config
```
