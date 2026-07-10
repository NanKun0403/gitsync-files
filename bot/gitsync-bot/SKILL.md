---
name: gitsync-bot
description: "GitSync 微信 Bot — 接收文件推送到 GitHub，按需拉取发送给用户。不在服务器保留文件。"
version: 1.0.0
trigger:
  - user sends file to WeChat bot
  - user says "/list" or "/get <filename>" in WeChat
---

# GitSync WeChat Bot

## 触发条件
当用户在微信中：
1. 发送文件给 Bot
2. 发送 "/list" 或 "文件列表" 查看可下载文件
3. 发送 "/get <文件名>" 或 "发送 <文件名>" 请求下载某文件

## 操作流程

### 收到文件
1. 用户通过微信发送文件
2. Bot 接收文件
3. 使用 git clone/pull 拉取 gitsync-files 仓库
4. 将文件放入 `files/{uuid}/` 目录
5. 更新 manifest.json
6. git commit + push
7. **删除本地克隆的仓库和文件**（关键步骤）
8. 回复用户："文件 {filename} 已同步 ✅"

### 用户请求文件列表
1. 用户发送 "/list" 或 "文件列表"
2. Bot 使用 GitHub API 获取 manifest.json（不 clone 整个仓库）
3. 解析文件列表，回复用户：
   ```
   📁 当前文件列表 (共 N 个):
   1. document.pdf (2.3 MB) - 3 个版本
   2. presentation.pptx (5.1 MB) - 1 个版本
   ...
   
   发送 "/get <文件名>" 下载文件
   ```

### 用户请求下载文件
1. 用户发送 "/get document.pdf" 或 "把 document.pdf 发给我"
2. Bot 通过 GitHub API 获取 manifest.json
3. 匹配文件名
4. 通过 CDN 下载该文件到临时目录
5. 发送文件给用户
6. **立即删除临时文件**
7. 不保留任何文件在服务器上

## 核心原则
- 文件仅存在于 GitHub 仓库中
- Bot 服务器仅作中转，不留存任何文件
- 使用 GitHub API（轻量）而非 git clone（重量）进行查询
- 需要上传时才 clone 仓库，完成后立即删除

## 实现方式
在 Hermes 中作为技能运行，利用 Hermes 的 WeChat 平台能力接收文件。