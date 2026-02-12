[**中文文档**](./README.zh-CN.md)

# Agemily

A cross-platform AI chat app built for elderly family members and children. Powered by Claude and Gemini with automatic memory, voice readback, web search, and intelligent model routing.

## Features

- **AI Chat** — Streaming responses with Markdown rendering, extended thinking display, and image input
- **Web Search** — Real-time web search via the Anthropic `web_search` tool; togglable in settings
- **Auto Memory** — Automatically extracts key facts from conversations, scores and ranks them, then injects relevant context into future turns
- **Smart Model Routing** — Everyday questions use Claude Sonnet 4.5; complex topics (medical, legal, analytical) automatically switch to Gemini 3 Pro
- **Voice Readback** — Tap any assistant message to hear it read aloud (auto-detects Chinese / English)
- **Context Management** — Token tracking, message truncation, and automatic compaction to stay within the context window
- **Multi-Session** — Parallel conversations with auto-generated titles
- **Offline Recovery** — Detects connectivity changes and auto-retries after reconnection

## Quick Start

### Prerequisites

- Flutter SDK >= 3.10.8
- Xcode (for iOS)
- Android SDK (for Android)

### Install

```bash
git clone https://github.com/sofish/agemily.git
cd agemily
flutter pub get
```

#### Local Development

Create a `.env` file from the template:

```bash
cp .env.example .env
# Edit .env with your API key and base URL
```

The `.env` file is **only loaded in debug mode** (`flutter run`). Credentials stay local and are never bundled into release builds.

```bash
flutter run
```

#### Release Build

Release builds do **not** read `.env`. Users enter their API key through the in-app onboarding screen on first launch.

```bash
# iOS
flutter build ios --release

# Android APK (with obfuscation)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

## Project Structure

```
lib/
├── main.dart                  # Bootstrap, splash, debug-mode .env loading
├── app.dart                   # GoRouter routes, app lifecycle (background memory extraction)
├── core/
│   ├── models/                # Message, Session, MemoryNote, LlmConfig, Usage
│   └── services/              # LLM client, AgentRunner, MemoryManager, ContextManager
├── data/
│   ├── database/              # Drift ORM — table definitions, DAOs, migrations
│   └── api/
├── providers/                 # Riverpod state management (chat, session, settings, agent)
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

### `.env` (debug mode only)

| Variable | Description |
|---|---|
| `LLM_API_KEY` | API key (auto-loaded in debug mode) |
| `LLM_API_BASE` | API base URL (auto-loaded in debug mode) |

### In-App Settings

API key, base URL, system prompt, model selection, and web search toggle can all be changed under **Settings > API Config**. In release builds this is the only way to configure credentials.

## License

MIT
