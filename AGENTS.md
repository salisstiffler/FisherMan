# AGENTS.md — AI Coding Assistant Guidance

This project is **「钓鱼佬」(FisherMan)**, a full-stack, production-ready fishing companion application comprising a **Flutter cross-platform client** and a **Node.js/Express SQLite server**.

When modifying, extending, or debugging this repository, adhere strictly to the rules below.

---

## 1. Quick Reference & Context
- Master AI Knowledge Base: [docs/ai/README.md](docs/ai/README.md)
- System Architecture: [docs/ai/ARCHITECTURE.md](docs/ai/ARCHITECTURE.md)
- Database Schema: [docs/ai/DATABASE_SCHEMA.md](docs/ai/DATABASE_SCHEMA.md)
- API Contract: [docs/ai/API_CONTRACT.md](docs/ai/API_CONTRACT.md)
- Development & Testing: [docs/ai/DEVELOPMENT_GUIDE.md](docs/ai/DEVELOPMENT_GUIDE.md)

---

## 2. Invariants & Rules

1. **Flutter/Dart Rule**:
   - `flutter analyze` must produce `No issues found!`.
   - Never use `Color.withOpacity(x)`. Use `Color.withValues(alpha: x)`.
   - The app supports both Light and Dark mode via `AppTheme` and `ThemeMode.system`. Keep UI elements compatible.

2. **Backend/Node.js Rule**:
   - Built on **Node.js 22** using native `node:sqlite` (`DatabaseSync`). Do NOT introduce SQLite native bindings like `better-sqlite3` or `sqlite3` which require node-gyp C++ compilation.
   - All endpoints return `{ code, message, data }`.
   - Pass all integration tests in `fisherman_server/test/api.test.js`.

3. **Git Hygiene**:
   - Keep working directory clean.
   - Run tests before finalizing changes.
