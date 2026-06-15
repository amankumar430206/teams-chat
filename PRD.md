# Product Requirements Document — Real-Time Team Chat App

## Overview
A production-grade Flutter team chat application built as an interview demonstration. It showcases real-time WebSocket communication, REST API integration, clean architecture, and a polished Material 3 UI.

---

## Goals
- Demonstrate proficiency in Flutter, Dart, and Riverpod
- Show clean architecture with clear separation of concerns
- Implement production patterns: error handling, reconnection logic, local caching, state management

---

## User Stories

| # | As a user...                                              | Priority |
|---|-----------------------------------------------------------|----------|
| 1 | I can log in with credentials to access the chat         | P0       |
| 2 | I can see a list of available chat rooms                 | P0       |
| 3 | I can see who is currently online                        | P1       |
| 4 | I can send and receive messages in real time             | P0       |
| 5 | I can see when someone else is typing                    | P1       |
| 6 | I can see delivery status of my messages (sent/delivered)| P1       |
| 7 | I can scroll through previous message history            | P1       |
| 8 | I can toggle between light and dark mode                 | P2       |

---

## Technical Architecture

### Folder Structure (Clean Architecture)
```
lib/
├── core/          # Shared infrastructure (network, theme, router, utils)
├── data/          # Data layer (API clients, models, repository implementations)
├── domain/        # Domain layer (entities — pure Dart, no framework deps)
└── presentation/  # UI layer (screens, providers, widgets)
```

### State Management
- **Riverpod 2.x** (`AsyncNotifier`, `Notifier`, family providers)
- Each feature owns its providers; no global mutable singletons
- `AsyncValue<T>` used for loading/error/data states in the UI

### Navigation
- **go_router 14.x** with auth-based redirect
- Router refreshes automatically on auth state changes

### Networking
- **Dio 5.x** with an interceptor that injects the Bearer token
- **web_socket_channel 3.x** for real-time messaging with auto-reconnect

### Local Storage
- **SharedPreferences** for auth token, user data, and cached messages

---

## APIs Used

| Purpose         | Endpoint                                      | Method |
|-----------------|-----------------------------------------------|--------|
| Login           | https://dummyjson.com/auth/login              | POST   |
| Fetch users     | https://dummyjson.com/users?limit=20          | GET    |
| WebSocket       | wss://echo.websocket.events                   | WS     |

> **Note:** Message history is mock-generated locally (no public chat history API exists). The WebSocket echo server is used to simulate message delivery confirmation.

---

## WebSocket Message Protocol

```json
// Chat message
{ "type": "chat_message", "id": "uuid", "roomId": "general",
  "senderId": 1, "senderName": "Emily", "senderAvatar": "url",
  "content": "Hello!", "timestamp": "ISO8601" }

// Typing event
{ "type": "typing", "roomId": "general", "senderId": 1,
  "senderName": "Emily", "isTyping": true }
```

---

## Message Delivery Flow
```
User sends message → status: sending
WebSocket.sink.add()  → status: sent
Echo received back    → status: delivered
Connection lost       → status: failed
```

---

## Bonus Features
- Dark mode support (persisted via SharedPreferences)
- Local message cache (messages survive app restarts within session)
- WebSocket auto-reconnect with exponential backoff indicator
- Simulated "other user" typing + messages for demo realism
