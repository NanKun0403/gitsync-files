# GitSync — 跨平台文件同步应用

基于 GitHub 的跨平台文件同步工具，支持桌面端（Windows/Mac/Linux）、手机端（Android/iOS）和微信 Bot。

## 架构

```
用户客户端 (Flutter) → GitHub 仓库 → CDN 加速 (jsDelivr/Cloudflare)
                    ↘ 微信 Bot (Hermes)
```

- **文件存储**: GitHub 仓库，git 天然维护版本历史
- **元数据**: `manifest.json` 作为唯一状态源
- **CDN 加速**: 默认 jsDelivr，可选 Cloudflare Worker
- **零本地缓存**: 应用不保留文件副本，仅用户主动下载时写入

## 快速开始

### 前置条件

- Flutter SDK (>= 3.x)
- Git
- GitHub 账号

### 1. 创建 GitHub 仓库

创建一个新仓库（如 `gitsync-files`），并在根目录创建 `manifest.json`：

```json
{"files":[],"last_updated":"2024-01-01T00:00:00Z"}
```

### 2. 生成 GitHub Token

1. 访问 https://github.com/settings/tokens
2. 生成经典 Personal Access Token，勾选 `repo` 权限

### 3. 构建应用

```bash
cd app
flutter pub get
flutter build windows --release   # Windows
flutter build apk --release       # Android
flutter build ios --release       # iOS (需 Xcode)
flutter build macos --release     # macOS
```

### 4. 运行

```bash
flutter run -d windows
```

在设置页面填入 GitHub 用户名、仓库名、Token，保存后刷新即可。

## 目录结构

```
gitsync/
├── app/                          # Flutter 应用
│   └── lib/
│       ├── main.dart             # 入口
│       ├── models/               # 数据模型
│       ├── services/             # 业务服务
│       ├── providers/            # 状态管理
│       ├── screens/              # 页面
│       └── widgets/              # 组件
├── bot/                          # 微信 Bot 技能
├── cdn/                          # CDN 配置
└── docs/                         # 文档
```

## 核心功能

- **文件管理**: 上传、下载、文件列表
- **版本控制**: 每个文件版本 = git commit，支持回滚
- **PDF 编辑**: 查看、拆分 PDF
- **多端同步**: 桌面端 + 移动端 + 微信 Bot 实时同步
- **CDN 加速**: 国内用户高速下载

## CDN 配置

默认使用 jsDelivr：
```
https://cdn.jsdelivr.net/gh/{USER}/{REPO}@main/files/{uuid}/{filename}
```

可选 Cloudflare Worker：部署 `cdn/cloudflare-worker.js` 到 Cloudflare Workers。

## 技术栈

- **前端**: Flutter 3.x (Dart)
- **文件同步**: GitHub REST API + git CLI
- **CDN**: jsDelivr / Cloudflare Workers
- **微信 Bot**: Hermes Agent WeChat 平台
- **PDF**: Syncfusion Flutter PDF

## 环境要求

- Flutter SDK >= 3.0
- Dart >= 3.0
- Git >= 2.0
- 所有软件安装在项目目录内，不写入 C 盘