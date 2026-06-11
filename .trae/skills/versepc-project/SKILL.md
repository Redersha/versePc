---
name: "versepc-project"
description: "VersePC 项目知识库与工作流规则。AI 修改代码前必须调用此 skill，了解项目结构、文件位置、功能模块，避免多人同时修改冲突。完成代码修改后不要构建，提交源代码到 git 即可。"
---

# VersePC 项目知识库

## 工作流规则（必须遵守）

### 1. 修改代码后
- **不要**自动运行 `npm run build:win` 或任何构建命令
- **不要**运行 `generate-integrity.js`
- **不要**上传 `dist/` 目录或 `.exe` 安装包

### 2. 提交到 Git
- 只提交源代码（js/、css/、server.js、main.js 等）
- **同时推送到两个分支**：`git push origin master:main`
- 远程仓库默认分支是 `main`（origin/HEAD -> origin/main）

### 3. 当用户明确要求构建时
- 先清理 dist：`Remove-Item -Recurse -Force dist`
- 运行 `npm run build:win`
- 计算 SHA256 哈希：`(Get-FileHash dist\VersePC-Setup-*.exe -Algorithm SHA256).Hash`
- 计算文件大小：`$f = Get-Item dist\VersePC-Setup-*.exe; $f.Length`
- 更新 `update.json` 中的 `sha256` 和 `size`
- 提交所有变更并推送：`git push origin master:main`

### 4. 避免多人冲突
- 修改前先 `git pull` 获取最新代码
- 只修改自己负责的文件，不要同时改别人的文件
- server.js 是最大的文件（~19000 行），多人同时修改容易冲突，优先考虑拆分

---

## 项目架构

```
VersePC (Electron App)
├── main.js           → Electron 主进程（窗口、协议、IPC）
├── preload.cjs       → 安全 IPC 桥接（contextBridge）
├── server.js         → 所有业务逻辑（~19000 行）
├── index.html        → 主页面
├── ai-config.js      → AI 提供商配置（15+ 提供商）
├── sse-server.js     → SSE 流式通信
├── crashAnalyzer.js  → 游戏崩溃分析
├── agent-engine.js   → AI Agent 引擎
├── agent-worker.js   → AI Agent 工作线程
├── plugin-manager.js → 插件管理器
├── js/               → 前端 JS 模块
├── css/              → 样式表
├── img/              → 图片资源
├── installer/        → NSIS 安装器配置
└── update.json       → 版本更新配置
```

---

## 核心文件功能速查

### 服务端（server.js）— 所有业务逻辑

| 功能模块 | 关键函数 | 说明 |
|---------|---------|------|
| **网络请求** | `fetchWithProtocol()`, `downloadFileWithMirror()` | HTTP/HTTPS 统一请求，支持镜像回退 |
| **版本管理** | `getVersionManifest()`, `resolveVersionJson()`, `mergeVersionJson()` | 版本 JSON 解析与合并 |
| **游戏启动** | `buildLaunchArguments()`, `buildClasspath()`, `doLaunch()` | 启动参数构建、classpath、进程管理 |
| **依赖检查** | `checkDependencies()`, `downloadMissingDependencies()` | 缺失文件检测与下载 |
| **Forge** | `installForge()`, `verifyLoaderLibs()`, `verifyImportLibs()` | Forge 安装、库文件验证 |
| **Fabric** | `installFabric()`, `mergeFabricLoaderToVersion()` | Fabric 安装 |
| **NeoForge** | `installNeoForge()`, `mergeNeoForgeLoaderToVersion()` | NeoForge 安装 |
| **整合包** | `importModpackFromPath()`, `_importMrpack()`, `_importCurseForge()` | 整合包导入（Modrinth/CurseForge） |
| **Java** | `detectSystemJava()`, `downloadJavaAsync()`, `selectJavaForVersion()` | Java 检测与安装 |
| **账户** | `loadAccounts()`, `encryptToken()`, `decryptToken()` | 账户管理与加密 |
| **皮肤** | `fetchSkinFromSessionServer()`, `cropSkinHead()` | 皮肤获取与裁剪 |
| **联机** | `createLANRoom()`, `startTerracotta()`, `discoverUPnPGateway()` | 局域网联机 |
| **设置** | `loadSettings()`, `saveSettings()`, `loadVersionSettings()` | 设置读写 |

### 前端模块（js/）

| 文件 | 功能 | 关键函数/对象 |
|------|------|-------------|
| `app.js` | 主应用逻辑（页面导航、版本列表、启动流程、下载管理） | `navigateToPage()`, `loadVersionList()`, `dlManager`, `showToast()` |
| `api.js` | API 通信层（所有后端接口封装） | `API.getVersions()`, `API.launchGame()`, `apiGet()`, `apiPost()` |
| `ai-chat.js` | AI 聊天界面（对话、流式输出、设置） | `AIChat`, `aiNewChat()`, `aiSendMessage()` |
| `wallpaper-engine.js` | 壁纸引擎（全景图、自定义图片/视频） | `WallpaperEngine`, `PanoramaRenderer`, `initWallpaper()` |
| `modpack-import.js` | 整合包导入前端逻辑 | 整合包格式识别与导入 |
| `mod-chinese-names.js` | 模组中文名称映射 | `getModChineseName()` |
| `crashAnalyzerUI.js` | 崩溃分析 UI | `CrashAnalyzerUI` |
| `file-browser.js` | 文件浏览器组件 | `FileBrowser` |
| `utils.js` | 工具函数 | `escapeHtml()`, `formatDate()`, `formatSize()` |

### 主进程（main.js）

| 功能模块 | 关键函数 | 说明 |
|---------|---------|------|
| **协议处理** | `handleVersePCProtocol()`, `handleAPIRequest()` | versepc:// 协议路由 |
| **窗口管理** | `createWindow()`, `createEditorWindow()` | 无边框窗口 |
| **自动更新** | `initAutoUpdater()`, `fetchUpdateJson()` | 多镜像源更新 |
| **GPU 控制** | `shouldDisableGpu`, `enableGpuFile` | 硬件加速开关 |
| **IPC 注册** | `registerModsIPC()`, `registerAIChatIPC()` | 渲染进程通信 |

### 预加载脚本（preload.cjs）

| 模块 | 暴露方法 | 说明 |
|------|---------|------|
| 窗口 | `minimize()`, `maximize()`, `close()` | 窗口控制 |
| 模组 | `mods.list()`, `mods.read()`, `mods.write()` | 模组文件操作 |
| 更新 | `updater.checkForUpdates()` | 应用更新 |
| AI | `ai.chatStream()`, `ai.chatStreamSSE()` | AI 对话 |
| 终端 | `terminal.create()`, `terminal.write()` | xterm 终端 |

---

## API 端点速查（server.js）

| 端点 | 功能 |
|------|------|
| `/api/launch` | 启动游戏 |
| `/api/versions` | 版本列表 |
| `/api/install-start` | 安装版本 |
| `/api/mods/*` | 模组管理 |
| `/api/modpack/import` | 导入整合包 |
| `/api/java/*` | Java 管理 |
| `/api/fabric/install` | 安装 Fabric |
| `/api/forge/install` | 安装 Forge |
| `/api/neoforge/install` | 安装 NeoForge |
| `/api/accounts/*` | 账户管理 |
| `/api/msauth/*` | 微软登录 |
| `/api/lan/*` | 局域网联机 |
| `/api/settings` | 设置读写 |
| `/api/resources/search` | 资源搜索 |
| `/api/upload-skin` | 上传皮肤 |
| `/api/game/*` | 游戏状态 |

---

## 构建与发布流程

```bash
# 1. 清理旧构建
Remove-Item -Recurse -Force dist

# 2. 构建
npm run build:win

# 3. 计算哈希和大小
(Get-FileHash dist\VersePC-Setup-1.1.11.exe -Algorithm SHA256).Hash
(Get-Item dist\VersePC-Setup-1.1.11.exe).Length

# 4. 更新 update.json（sha256 和 size 字段）

# 5. 提交推送
git add -A
git commit -m "描述"
git push origin master:main

# 6. 手动上传安装包到 GitHub Release
```

---

## 依赖库

| 库 | 用途 | 注意事项 |
|---|------|---------|
| `sharp` | 图像处理（皮肤裁剪） | asarUnpack 中，不打包进 ASAR |
| `adm-zip` | ZIP/JAR 操作 | 整合包导入、Forge 安装 |
| `ws` | WebSocket | 局域网联机 |
| `electron-updater` | 自动更新 | 多镜像源 |
| `monaco-editor` | 代码编辑器 | AI 聊天编辑器 |
| `@xterm/xterm` | Web 终端 | 游戏日志终端 |

---

## 常见修改场景

| 需求 | 修改文件 |
|------|---------|
| 修复启动问题 | `server.js` 中 `doLaunch()`、`buildLaunchArguments()`、`checkDependencies()` |
| 修复整合包导入 | `server.js` 中 `importModpackFromPath()`、`_importMrpack()`、`_importCurseForge()` |
| 修复 Forge 安装 | `server.js` 中 `installForge()`、`verifyLoaderLibs()` |
| 修改 UI 布局 | `index.html` + `css/style.css` |
| 添加新页面 | `index.html` + `js/app.js` 中 `navigateToPage()` |
| 修改下载逻辑 | `server.js` 中 `downloadFileWithMirror()`、`cachedFetchJSON()` |
| 修改账号系统 | `server.js` 中 `loadAccounts()`、`/api/accounts/*` |
| 修改皮肤功能 | `server.js` 中 `/api/upload-skin`、`fetchSkinFromSessionServer()` |
| 修改联机功能 | `server.js` 中 `/api/lan/*`、`startTerracotta()` |
| 修改 AI 聊天 | `js/ai-chat.js` + `sse-server.js` + `agent-engine.js` |
| 修改壁纸 | `js/wallpaper-engine.js` + `css/style.css` |
| 修改设置页面 | `index.html` 中设置面板 + `js/app.js` 中设置逻辑 |
