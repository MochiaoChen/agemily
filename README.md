# Agemily (家庭小助手)

A cross-platform AI chat app built for elderly family members and children. Powered by Claude and Gemini, with automatic memory, text-to-speech, and intelligent model routing.

## Features

- **AI Chat** — Streaming responses with markdown rendering, thinking block visualization, and image input
- **Auto Memory** — Extracts key facts from conversations, scores and ranks them, and injects relevant context into future chats
- **Smart Model Routing** — Automatically selects Claude Sonnet 4.5 for daily use or Gemini 3 Pro for complex queries (medical, legal, analytical)
- **Text-to-Speech** — Tap any assistant message to hear it read aloud (auto-detects Chinese/English)
- **Context Management** — Token tracking, message truncation, and automatic compaction to stay within context limits
- **Multi-Session** — Multiple concurrent conversations with auto-generated titles
- **Offline Resilience** — Detects network state and auto-retries failed messages on reconnection

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.10.8
- Xcode (for iOS)
- Android SDK (for Android)

### Setup

```bash
git clone https://github.com/sofish/agemily.git
cd agemily
flutter pub get
```

#### Local Development

For local development, create a `.env` file from the example template:

```bash
cp .env.example .env
# Edit .env with your API key and base URL
```

The `.env` file is loaded **only in debug mode** (`flutter run`). Your credentials stay on your machine and are never bundled into release builds.

```bash
flutter run
```

#### Release Builds

Release builds do **not** read `.env`. Users enter their API key through the in-app onboarding screen on first launch.

```bash
# iOS
flutter build ios --release

# Android APK (with code obfuscation)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

## Project Structure

```
lib/
├── main.dart                  # Bootstrap, splash screen, debug-only .env loading
├── app.dart                   # GoRouter, app lifecycle (memory extraction on background)
├── core/
│   ├── models/                # Message, Session, MemoryNote, LlmConfig, Usage
│   └── services/              # LLM client, AgentRunner, MemoryManager, ContextManager
├── data/
│   ├── database/              # Drift ORM — tables, DAOs, migrations
│   └── api/
├── providers/                 # Riverpod providers (chat, session, settings, agent)
└── ui/
    ├── chat/                  # Chat screen, message bubbles, input bar, model selector
    ├── settings/              # API config, system prompt, memory management
    ├── sessions/              # Session list
    └── shared/                # Theme, localization
```

## Tech Stack

- **Flutter** + **Riverpod** for state management
- **Drift** (SQLite) for local persistence
- **FlutterSecureStorage** for API key storage
- **Dio** for streaming HTTP
- **flutter_tts** for text-to-speech
- **GoRouter** for navigation

## Configuration

### `.env` (debug only)

| Variable | Description |
|---|---|
| `LLM_API_KEY` | Your API key (auto-loaded in debug mode) |
| `LLM_API_BASE` | API base URL (auto-loaded in debug mode) |

### In-app settings

API key, base URL, system prompt, and model selection can all be configured in-app via **Settings > API Config**. In release builds, this is the only way to configure credentials.

## License

MIT
