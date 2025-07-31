# CodeRocket 快速入门指南

## 🚀 5分钟快速上手

本指南将帮助您在5分钟内完成 CodeRocket 的安装和配置，立即开始享受AI驱动的代码审查体验。

## 📋 前置要求

在开始之前，请确保您的系统满足以下要求：

- **操作系统**: macOS, Linux, 或 Windows (WSL)
- **Node.js**: 版本 >= 14.0.0
- **Git**: 版本 >= 2.0.0
- **网络连接**: 能够访问互联网和AI服务API

## ⚡ 一键安装

### 方式一：全局安装（推荐新手）

```bash
# 一键安装脚本
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash
```

安装过程中会提示选择安装模式，**建议选择"全局安装"**：
- ✅ 新项目自动启用
- ✅ 提供全局命令
- ✅ 一次安装，终身受益

### 方式二：项目级安装

```bash
# 克隆项目
git clone https://github.com/im47cn/coderocket-cli.git
cd coderocket

# 运行安装脚本
./install.sh
# 选择"项目安装"模式
```

## 🔧 快速配置

### 1. 配置AI服务（必需）

选择并配置一个AI服务：

#### 选项A：Gemini（推荐）
```bash
# 安装Gemini CLI
npm install -g @google/gemini-cli

# 配置API密钥
gemini config
# 按提示输入您的Google AI Studio API密钥
```

#### 选项B：其他AI服务
```bash
# OpenCode
npm install -g @opencode/cli
opencode config

# ClaudeCode  
npm install -g @claudecode/cli
claudecode config
```

### 2. 配置GitLab集成（可选）

如果需要自动创建MR功能：

```bash
# 设置GitLab访问令牌
export GITLAB_PERSONAL_ACCESS_TOKEN="your-gitlab-token"

# 或者创建项目配置文件
echo "GITLAB_PERSONAL_ACCESS_TOKEN=your-gitlab-token" > .env
```

**获取GitLab Token**：
1. 登录GitLab → Settings → Access Tokens
2. 创建新令牌，权限选择：`api`, `read_repository`, `write_repository`

## 🎯 验证安装

### 检查安装状态

```bash
# 全局安装验证
coderocket --version
coderocket status

# 项目安装验证
ls -la .git/hooks/
./lib/ai-service-manager.sh status
```

### 测试AI服务

```bash
# 测试Gemini
gemini --version
echo "测试提示" | gemini

# 测试其他服务
opencode --version
claudecode --version
```

## 🏃‍♂️ 立即开始使用

### 第一次代码审查

1. **修改代码**：
```bash
# 在您的项目中修改任意文件
echo "console.log('Hello CodeRocket!');" >> test.js
```

2. **提交代码**：
```bash
git add test.js
git commit -m "feat: 添加测试代码"
```

3. **查看审查结果**：
```bash
# 审查报告会自动生成在 review_logs/ 目录
ls review_logs/
cat review_logs/最新的审查报告.md
```

### 第一次MR创建

1. **创建功能分支**：
```bash
git checkout -b feature/my-first-feature
```

2. **提交更改**：
```bash
git add .
git commit -m "feat: 我的第一个功能"
```

3. **推送并创建MR**：
```bash
git push origin feature/my-first-feature
# 系统会自动提示是否创建MR
```

## 🎨 个性化配置

### 选择AI服务

```bash
# 交互式选择
./lib/ai-config.sh select

# 直接设置
echo "AI_SERVICE=gemini" > .ai-config
```

### 自定义审查规则

```bash
# 创建项目级提示词文件
mkdir -p prompts
cp ~/.coderocket/prompts/git-commit-review-prompt.md prompts/

# 编辑自定义规则
vim prompts/git-commit-review-prompt.md
```

### 配置环境变量

创建 `.env` 文件：
```bash
# AI服务配置
AI_SERVICE=gemini
AI_TIMEOUT=60
AI_MAX_RETRIES=3

# GitLab配置
GITLAB_PERSONAL_ACCESS_TOKEN=your-token
GITLAB_API_URL=https://gitlab.com/api/v4

# 调试模式
DEBUG=false
```

## 🔍 常见使用场景

### 场景1：个人项目开发

```bash
# 1. 全局安装
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash

# 2. 配置Gemini
gemini config

# 3. 开始编码
git add .
git commit -m "feat: 新功能"
# 自动触发代码审查
```

### 场景2：团队协作项目

```bash
# 1. 项目级安装
git clone https://github.com/im47cn/coderocket-cli.git
./install.sh

# 2. 团队配置
cp .env.example .env
# 编辑 .env 设置团队共享的配置

# 3. 协作开发
git checkout -b feature/team-feature
git commit -m "feat: 团队功能"
git push origin feature/team-feature
# 自动创建MR
```

### 场景3：CI/CD集成

```bash
# GitHub Actions 示例
- name: Setup CodeRocket
  run: |
    curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash
    echo "AI_SERVICE=gemini" > .ai-config

- name: Run Code Review
  run: ./githooks/post-commit
```

## 🛠️ 高级功能

### 多AI服务切换

```bash
# 查看当前服务
./lib/ai-service-manager.sh status

# 切换服务
./lib/ai-config.sh set AI_SERVICE opencode

# 测试新服务
./lib/ai-service-manager.sh test
```

### 批量处理历史提交

```bash
# 审查最近5个提交
for i in {1..5}; do
  git checkout HEAD~$i
  ./githooks/post-commit
done
```

### 自定义Hook行为

```bash
# 禁用自动MR创建
echo "DISABLE_AUTO_MR=true" >> .env

# 设置审查日志目录
echo "REVIEW_LOGS_DIR=/custom/path" >> .env
```

## 🚨 快速故障排除

### 问题1：AI服务不可用
```bash
# 检查服务状态
./lib/ai-service-manager.sh status

# 重新配置
gemini config --reset
```

### 问题2：Hook不执行
```bash
# 检查权限
chmod +x .git/hooks/post-commit
chmod +x .git/hooks/pre-push

# 重新安装
./install-hooks.sh
```

### 问题3：环境变量未加载
```bash
# 检查配置
echo $GITLAB_PERSONAL_ACCESS_TOKEN

# 重启终端或IDE
```

## 📚 下一步学习

现在您已经成功安装并配置了 CodeRocket，建议继续学习：

1. **[完整用户指南](README.md)** - 了解所有功能特性
2. **[API参考文档](docs/API_REFERENCE.md)** - 深入了解技术细节
3. **[架构概览](docs/ARCHITECTURE_OVERVIEW.md)** - 理解系统设计
4. **[部署指南](docs/DEPLOYMENT_GUIDE.md)** - 生产环境部署
5. **[贡献指南](CONTRIBUTING.md)** - 参与项目开发

## 💡 专业提示

1. **定期更新**：
```bash
# 检查更新
coderocket update
```

2. **备份配置**：
```bash
# 备份重要配置
cp -r ~/.coderocket ~/.coderocket.backup
```

3. **性能优化**：
```bash
# 设置合理的超时时间
echo "AI_TIMEOUT=30" >> .env
```

4. **团队标准化**：
```bash
# 使用项目级配置确保团队一致性
cp .env.example .env
git add .env.example
```

## 🎉 恭喜！

您已经成功完成了 CodeRocket 的快速入门！现在您可以：

- ✅ 享受AI驱动的自动代码审查
- ✅ 获得详细的代码质量报告
- ✅ 自动创建智能的GitLab MR
- ✅ 提升代码质量和开发效率

**开始您的智能代码审查之旅吧！** 🚀✨

---

如有问题，请查看 [故障排除文档](README.md#故障排除) 或 [提交Issue](https://github.com/im47cn/coderocket-cli/issues)。
