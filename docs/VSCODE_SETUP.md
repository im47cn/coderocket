# VS Code Git Hooks 设置指南

本指南帮助你在 VS Code 中正确设置和使用 Git hooks。

## 🚀 快速设置

### 1. 运行安装脚本

```bash
./install-hooks.sh
```

### 2. 配置环境变量

#### 方式一：项目级配置（推荐）

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，设置你的 GitLab Token
# GITLAB_PERSONAL_ACCESS_TOKEN=your_token_here
```

#### 方式二：全局配置

在你的 shell 配置文件中添加：

```bash
# ~/.bashrc 或 ~/.zshrc
export GITLAB_PERSONAL_ACCESS_TOKEN="your_token_here"
export GITLAB_API_URL="https://gitlab.yeepay.com/api/v4"
```

### 3. 重启 VS Code

重启 VS Code 以加载新的环境变量。

## 🔧 功能验证

### 测试 Post-Commit Hook（代码审查）

1. 在 VS Code 中修改任意文件
2. 使用 VS Code 的 Git 面板提交代码
3. 查看是否生成了审查报告文件

### 测试 Pre-Push Hook（MR 创建）

1. 在 VS Code 中推送代码到 GitLab
2. 查看是否出现 MR 创建提示
3. 选择是否创建 MR

## 🐛 故障排除

### 问题：VS Code 中 hooks 不执行

**解决方案：**
1. 确保运行了 `./install-hooks.sh`
2. 检查 `.git/hooks/` 目录下的文件权限
3. 重启 VS Code

### 问题：环境变量未加载

**解决方案：**
1. 使用项目级 `.env` 文件（推荐）
2. 确保 VS Code 从正确的目录启动
3. 重启 VS Code

### 问题：Gemini CLI 不可用

**解决方案：**
```bash
# 安装 Gemini CLI
npm install -g @google/generative-ai-cli

# 配置 API 密钥
gemini config
```

## 📋 检查清单

- [ ] 运行了 `./install-hooks.sh`
- [ ] 配置了 `GITLAB_PERSONAL_ACCESS_TOKEN`
- [ ] 安装了 Gemini CLI
- [ ] 重启了 VS Code
- [ ] 测试了提交和推送功能

## 🎯 功能特性

### 智能代码审查
- ✅ 每次提交自动触发
- ✅ 生成详细的审查报告
- ✅ 支持多种编程语言

### 智能 MR 创建
- ✅ 推送时自动提示
- ✅ 使用 Gemini AI 生成标题和描述
- ✅ 支持多种分支类型

### VS Code 兼容性
- ✅ 完全支持 VS Code Git 工具
- ✅ 自动环境变量加载
- ✅ 健壮的错误处理

## 💡 提示

1. **首次使用**：建议先在终端测试功能是否正常
2. **环境变量**：项目级 `.env` 文件比全局配置更可靠
3. **权限问题**：如果遇到权限问题，重新运行安装脚本
4. **调试**：查看 VS Code 的输出面板获取详细错误信息

## 📞 支持

如果遇到问题，请：
1. 检查本指南的故障排除部分
2. 运行 `./install-hooks.sh` 重新安装
3. 查看项目 README 获取更多信息
