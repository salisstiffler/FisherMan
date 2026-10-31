# 🎣 FisherMan (钓鱼佬) - AI Assistant & Agent Context

This repository is a production-ready, cross-platform mobile and web application designed for fishing enthusiasts. It features spot exploration, barometric bite index forecasting, catch bragging logs, and an angler social network.

This document serves as the master index for AI agents (Cursor, Claude, Copilot, Antigravity, ChatGPT, etc.) working on this codebase.

---

## 🏛️ Repository Architecture

- **`fisherman_app/`**: Flutter 3.47+ / Dart 3.13+ client application targeting Android, iOS, Windows, Linux, macOS, and Web.
  - State Management: `Provider` pattern (`ChangeNotifierProvider`).
  - Architecture: Layered MVC/Feature-based (`core/`, `models/`, `providers/`, `views/`).
  - Mapping: `flutter_map` + OpenStreetMap tiles with `latlong2`.
  - Charting: `fl_chart`.
  - Image handling: `image_picker` + HTTP multipart upload.
  - Theming: Full Material 3 with Dynamic Light and Dark themes (`ThemeMode.system`).

- **`fisherman_server/`**: Node.js 22+ / Express 4.x backend server.
  - Database: Native `node:sqlite` (`DatabaseSync`), WAL mode, foreign keys enabled.
  - Auth: JWT with dual-token architecture (`accessToken` 7d, `refreshToken` 30d).
  - Middleware: Bearer token auth (`authenticate`, `optionalAuth`), Multer file uploads.
  - Health endpoint: `GET /health`.

- **`docs/`**: Official project documentation.
  - `API_DOCUMENTATION.md`: REST API reference.
  - `RELEASE_CHECKLIST.md`: Multi-platform release SOP.
  - `PRIVACY_POLICY.md`: Privacy & data handling compliance.

- **`docs/ai/`**: Deep-dive knowledge base documents for AI assistants.
  - `docs/ai/ARCHITECTURE.md`: Detailed system architecture, state flow & lifecycle.
  - `docs/ai/DATABASE_SCHEMA.md`: SQLite tables, columns, relations & seeds.
  - `docs/ai/API_CONTRACT.md`: Full API payload structures and response envelopes.
  - `docs/ai/DEVELOPMENT_GUIDE.md`: Build commands, testing standards, and conventions.

---

## 🔑 Crucial Coding Guidelines & Invariants

1. **Flutter Compatibility**:
   - SDK: Dart 3.13.7 / Flutter 3.47.8.
   - Do NOT use deprecated `Color.withOpacity(x)`. ALWAYS use `Color.withValues(alpha: x)`.
   - All models MUST provide `fromJson` and `toJson`.
   - Maintain strict `flutter analyze` clean status (0 warnings, 0 errors).

2. **Backend & SQLite Invariants**:
   - The server uses Node.js 22 built-in `DatabaseSync` from `node:sqlite` (no node-gyp or sqlite3 native addon required).
   - Queries use prepared statements: `db.prepare('...').run(...)` or `.get(...)` or `.all(...)`.
   - Soft errors and fallbacks must return standard JSON envelope: `{ code: 200|400|401|403|404|500, message: string, data: any }`.

3. **Authentication & Roles**:
   - Public read: Spots, Catches, Stats, Weather, Users public profiles.
   - Protected write: Spot creation, Catch posting, Likes, Comments, Reviews, Profile updates, Uploads.
   - Guest Mode: Handled via dummy user in `AuthProvider` (id: 9999) without network write privileges.
