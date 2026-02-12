# Agemily (家庭小助手)

专为家中老人和小孩打造的跨平台 AI 聊天应用。基于 Claude 和 Gemini，支持自动记忆、语音朗读和智能模型路由。

## 功能特性

- **AI 对话** — 流式响应，支持 Markdown 渲染、思考过程展示和图片输入
- **自动记忆** — 自动从对话中提取关键事实，评分排序后注入后续对话上下文
- **智能模型路由** — 日常问答自动使用 Claude Sonnet 4.5，医药、法律、分析等复杂问题自动切换至 Gemini 3 Pro
- **语音朗读** — 点击任意助手消息即可朗读（自动识别中英文）
- **上下文管理** — Token 跟踪、消息截断和自动压缩，确保不超出上下文窗口
- **多会话** — 支持多个并行对话，自动生成会话标题
- **离线恢复** — 检测网络状态，断网后恢复连接时自动重试

## 快速开始

### 前置要求

- Flutter SDK ≥ 3.10.8
- Xcode（iOS 开发）
- Android SDK（Android 开发）

### 安装

```bash
git clone https://github.com/sofish/agemily.git
cd agemily
flutter pub get
```

#### 本地开发

从模板创建 `.env` 配置文件：

```bash
cp .env.example .env
# 编辑 .env，填入你的 API 密钥和接口地址
```

`.env` 文件**仅在调试模式**下加载（`flutter run`）。你的凭证只留在本地，不会打包进发布版本。

```bash
flutter run
```

#### 发布构建

发布版本**不会**读取 `.env`。用户在首次启动时通过应用内引导页输入 API 密钥。

```bash
# iOS
flutter build ios --release

# Android APK（含代码混淆）
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

## 项目结构

```
lib/
├── main.dart                  # 启动引导、闪屏、调试模式 .env 加载
├── app.dart                   # GoRouter 路由、应用生命周期（后台时提取记忆）
├── core/
│   ├── models/                # Message, Session, MemoryNote, LlmConfig, Usage
│   └── services/              # LLM 客户端, AgentRunner, MemoryManager, ContextManager
├── data/
│   ├── database/              # Drift ORM — 表定义、DAO、迁移
│   └── api/
├── providers/                 # Riverpod 状态管理（聊天、会话、设置、Agent）
└── ui/
    ├── chat/                  # 聊天界面、消息气泡、输入栏、模型选择器
    ├── settings/              # API 配置、系统提示词、记忆管理
    ├── sessions/              # 会话列表
    └── shared/                # 主题、国际化
```

## 技术栈

- **Flutter** + **Riverpod** 状态管理
- **Drift**（SQLite）本地持久化
- **FlutterSecureStorage** API 密钥安全存储
- **Dio** 流式 HTTP 请求
- **flutter_tts** 语音合成
- **GoRouter** 路由导航

## 配置

### `.env`（仅调试模式）

| 变量 | 说明 |
|---|---|
| `LLM_API_KEY` | API 密钥（调试模式下自动加载） |
| `LLM_API_BASE` | API 接口地址（调试模式下自动加载） |

### 应用内设置

API 密钥、接口地址、系统提示词和模型选择均可在应用内通过 **设置 > API 配置** 修改。发布版本中，这是配置凭证的唯一方式。

## 许可证

MIT
