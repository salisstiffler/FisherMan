# 🛠️ AI Development Guide & Operations

This document outlines command workflows, testing standards, environment configuration, and verification protocols for AI models interacting with this project.

---

## 1. Environment & Pre-requisites

- **Operating System**: Windows / Linux / macOS compatible.
- **Node.js**: v22.0.0 or higher required (uses `node:sqlite` Native DatabaseSync).
- **Flutter SDK**: 3.47.8 / Dart 3.13.7.
- **Git**: Working tree should be maintained cleanly with descriptive commit messages.

---

## 2. Command Reference

### Backend (`fisherman_server`)

```bash
# Navigate to backend
cd fisherman_server

# Install dependencies (only Express, bcryptjs, cors, jsonwebtoken, multer)
npm install

# Start development server on http://localhost:8080
npm start

# Run the 9-test automated integration test suite
node test/api.test.js
# Or via npm
npm test
```

### Flutter Client (`fisherman_app`)

```bash
# Navigate to Flutter app
cd fisherman_app

# Fetch pub dependencies
flutter pub get

# Static analysis (MUST be 0 issues)
flutter analyze

# Unit & Widget tests
flutter test

# Run on Chrome
flutter run -d chrome

# Build production web bundle
flutter build web --release
```

---

## 3. Testing Rules for AI Agents

1. **Never skip testing**: Before proposing completion or pushing commits, execute:
   - `node test/api.test.js` from `fisherman_server/`
   - `flutter analyze` from `fisherman_app/`
   - `flutter test` from `fisherman_app/`

2. **Database Resilience**:
   - The SQLite database file is `fisherman_server/fisherman.db`.
   - Seed data is inserted automatically on first launch if the `users` table is empty.
   - Test suites execute against temporary in-memory or transient test ports.

3. **Color Standards**:
   - Do NOT use `Color.withOpacity(alpha)` as it triggers deprecation warnings in current Flutter releases.
   - Use `Color.withValues(alpha: alpha)` exclusively.

4. **Network Fallbacks**:
   - Both `CatchesProvider` and `SpotsProvider` contain fallback seed data in memory.
   - If the backend is unreachable or the user enters Guest Mode, the app seamlessly degrades to offline mock data without crashing.
