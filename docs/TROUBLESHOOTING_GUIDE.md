# CodeRocket 故障排除指南

## 🔧 概述

本指南提供了 CodeRocket 常见问题的诊断和解决方案，帮助您快速解决使用过程中遇到的问题。

## 🚨 常见问题分类

### 📦 安装相关问题

#### 问题1：安装脚本下载失败

**症状**：
```bash
curl: (7) Failed to connect to raw.githubusercontent.com
```

**解决方案**：
```bash
# 方案A：使用代理
export https_proxy=http://your-proxy:port
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash

# 方案B：手动下载
wget https://github.com/im47cn/coderocket-cli/archive/main.zip
unzip main.zip
cd coderocket-main
./install.sh

# 方案C：使用镜像源
curl -fsSL https://gitee.com/im47cn/coderocket-cli/raw/main/install.sh | bash
```

#### 问题2：权限不足

**症状**：
```bash
Permission denied: /usr/local/bin/coderocket
```

**解决方案**：
```bash
# 方案A：使用sudo安装全局命令
sudo curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash

# 方案B：使用用户命令（推荐，无需sudo）
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash
# 安装脚本会自动创建用户命令并配置PATH

# 方案C：手动设置PATH（如果自动配置失败）
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**说明**：
- v1.0.4+ 版本的安装脚本会自动创建用户命令并配置PATH
- 即使全局命令安装失败，用户命令也能正常工作
- 用户命令位于 `~/.local/bin/` 目录，无需管理员权限

#### 问题3：命令找不到

**症状**：
```bash
❯ cr
zsh: command not found: cr

❯ coderocket
command not found: coderocket
```

**解决方案**：
```bash
# 方案A：使用完整路径（立即可用）
~/.local/bin/cr help
~/.local/bin/cr version
~/.local/bin/coderocket setup

# 方案B：设置PATH（当前会话）
export PATH="$HOME/.local/bin:$PATH"
cr help

# 方案C：永久设置PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 方案D：重新安装（自动配置PATH）
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash
```

**验证修复**：
```bash
# 检查用户命令是否存在
ls -la ~/.local/bin/cr

# 检查PATH配置
echo $PATH | grep -o "$HOME/.local/bin"

# 测试命令
cr version
```

#### 问题4：Node.js版本过低

**症状**：
```bash
Error: Node.js version 12.x is not supported
```

**解决方案**：
```bash
# 使用nvm升级Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# 或使用包管理器
# Ubuntu/Debian
sudo apt update && sudo apt install nodejs npm

# macOS
brew install node

# CentOS/RHEL
sudo yum install nodejs npm
```

### 🤖 AI服务配置问题

#### 问题4：Gemini API密钥无效

**症状**：
```bash
Error: Invalid API key for Gemini service
```

**解决方案**：
```bash
# 1. 重新配置API密钥
gemini config --reset

# 2. 验证API密钥格式
echo $GEMINI_API_KEY | grep -E '^[A-Za-z0-9_-]+$'

# 3. 测试API连接
echo "测试" | gemini

# 4. 检查API配额
curl -H "Authorization: Bearer $GEMINI_API_KEY" \
     https://generativelanguage.googleapis.com/v1/models
```

#### 问题5：AI服务超时

**症状**：
```bash
Timeout: AI service call exceeded 30 seconds
```

**解决方案**：
```bash
# 1. 增加超时时间
echo "AI_TIMEOUT=60" >> .env

# 2. 检查网络连接
ping google.com
curl -I https://generativelanguage.googleapis.com

# 3. 使用备用服务
echo "AI_SERVICE=opencode" >> .ai-config

# 4. 启用重试机制
echo "AI_MAX_RETRIES=5" >> .env
```

#### 问题6：多AI服务冲突

**症状**：
```bash
Error: Multiple AI services configured
```

**解决方案**：
```bash
# 1. 检查当前配置
./lib/ai-service-manager.sh status

# 2. 清理配置
rm -f .ai-config
rm -f ~/.coderocket/ai-config

# 3. 重新配置单一服务
./lib/ai-config.sh select

# 4. 验证配置
./lib/ai-service-manager.sh test
```

### 🔗 Git Hooks 问题

#### 问题7：Hook不执行

**症状**：
- 提交代码后没有审查报告
- 推送代码时没有MR创建提示

**诊断步骤**：
```bash
# 1. 检查Hook文件是否存在
ls -la .git/hooks/post-commit
ls -la .git/hooks/pre-push

# 2. 检查执行权限
stat .git/hooks/post-commit
stat .git/hooks/pre-push

# 3. 手动执行Hook
./githooks/post-commit
./githooks/pre-push
```

**解决方案**：
```bash
# 1. 重新安装Hooks
./install-hooks.sh

# 2. 修复权限
chmod +x .git/hooks/post-commit
chmod +x .git/hooks/pre-push

# 3. 检查Hook内容
head -10 .git/hooks/post-commit

# 4. 全局安装用户重新设置
coderocket setup
```

#### 问题8：Hook路径错误

**症状**：
```bash
Error: /path/to/lib/ai-service-manager.sh not found
```

**解决方案**：
```bash
# 1. 使用快速修复脚本
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/fix-hooks.sh -o fix-hooks.sh
chmod +x fix-hooks.sh
./fix-hooks.sh

# 2. 手动修复路径
# 编辑 .git/hooks/post-commit
vim .git/hooks/post-commit
# 更新REPO_ROOT变量

# 3. 重新安装
rm -rf .git/hooks/post-commit .git/hooks/pre-push
./install-hooks.sh
```

### 🔐 GitLab集成问题

#### 问题9：GitLab Token无效

**症状**：
```bash
Error: 401 Unauthorized - Invalid GitLab token
```

**解决方案**：
```bash
# 1. 验证Token格式
echo $GITLAB_PERSONAL_ACCESS_TOKEN | grep -E '^glpat-[A-Za-z0-9_-]+$'

# 2. 测试Token权限
curl -H "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN" \
     "$GITLAB_API_URL/user"

# 3. 重新创建Token
# 登录GitLab → Settings → Access Tokens
# 权限：api, read_repository, write_repository

# 4. 更新配置
echo "GITLAB_PERSONAL_ACCESS_TOKEN=new-token" > .env
```

#### 问题10：MR创建失败

**症状**：
```bash
Error: Failed to create merge request
```

**诊断和解决**：
```bash
# 1. 检查项目ID
./lib/mr-generator.sh get-project-id

# 2. 检查分支状态
git branch -a
git status

# 3. 手动测试API
curl -X POST \
  -H "PRIVATE-TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"source_branch":"test","target_branch":"main","title":"Test MR"}' \
  "$GITLAB_API_URL/projects/PROJECT_ID/merge_requests"

# 4. 检查网络连接
ping gitlab.com
curl -I $GITLAB_API_URL
```

### 📁 文件系统问题

#### 问题11：审查报告生成失败

**症状**：
```bash
Error: Cannot write to review_logs directory
```

**解决方案**：
```bash
# 1. 检查目录权限
ls -ld review_logs/
stat review_logs/

# 2. 创建目录并设置权限
mkdir -p review_logs
chmod 755 review_logs

# 3. 检查磁盘空间
df -h .

# 4. 自定义日志目录
echo "REVIEW_LOGS_DIR=/tmp/codereview-logs" >> .env
mkdir -p /tmp/codereview-logs
```

#### 问题12：配置文件冲突

**症状**：
```bash
Warning: Multiple configuration files found
```

**解决方案**：
```bash
# 1. 查看所有配置文件
find . -name ".ai-config" -o -name ".env" -o -name "ai-config"
find ~ -name ".coderocket" -type d

# 2. 检查配置优先级
./lib/ai-config.sh show all

# 3. 清理重复配置
rm -f ./.ai-config.backup
rm -f ./.env.backup

# 4. 统一配置
./lib/ai-config.sh configure gemini project
```

## 🔍 高级诊断工具

### 系统诊断脚本

创建诊断脚本 `diagnose.sh`：
```bash
#!/bin/bash
echo "=== CodeRocket 系统诊断 ==="

echo "1. 系统信息："
uname -a
node --version
git --version

echo "2. 安装状态："
which coderocket
ls -la ~/.coderocket/

echo "3. AI服务状态："
./lib/ai-service-manager.sh status

echo "4. Git Hooks状态："
ls -la .git/hooks/post-commit .git/hooks/pre-push

echo "5. 配置信息："
./lib/ai-config.sh show all

echo "6. 网络连接："
ping -c 1 google.com
curl -I https://api.github.com

echo "=== 诊断完成 ==="
```

### 日志分析

```bash
# 启用详细日志
export DEBUG=1

# 查看系统日志
tail -f /var/log/system.log | grep codereview

# 查看Git操作日志
git log --oneline -10

# 查看Hook执行日志
ls -la review_logs/
```

### 性能分析

```bash
# 测量Hook执行时间
time ./githooks/post-commit

# 测量AI服务响应时间
time echo "测试" | gemini

# 监控资源使用
top -p $(pgrep -f codereview)
```

## 🛠️ 预防性维护

### 定期检查

```bash
# 每周执行的维护脚本
#!/bin/bash
echo "=== 每周维护检查 ==="

# 1. 检查更新
coderocket update --check

# 2. 清理旧日志
find review_logs/ -name "*.md" -mtime +30 -delete

# 3. 验证配置
./lib/ai-config.sh validate

# 4. 测试AI服务
./lib/ai-service-manager.sh test

echo "=== 维护完成 ==="
```

### 备份重要配置

```bash
# 备份脚本
#!/bin/bash
BACKUP_DIR="$HOME/coderocket-backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# 备份配置
cp -r ~/.coderocket "$BACKUP_DIR/"
cp .env "$BACKUP_DIR/" 2>/dev/null
cp .ai-config "$BACKUP_DIR/" 2>/dev/null

# 备份重要日志
cp -r review_logs "$BACKUP_DIR/" 2>/dev/null

echo "备份完成: $BACKUP_DIR"
```

## 📞 获取帮助

### 自助资源

1. **查看帮助文档**：
```bash
coderocket help
./lib/ai-service-manager.sh help
```

2. **运行测试套件**：
```bash
./test-ai-services.sh
```

3. **查看示例配置**：
```bash
cat .env.example
```

### 社区支持

1. **GitHub Issues**: [提交问题](https://github.com/im47cn/coderocket-cli/issues)
2. **讨论区**: [GitHub Discussions](https://github.com/im47cn/coderocket-cli/discussions)
3. **文档**: [完整文档](README.md)

### 报告Bug

提交Bug时请包含：
```bash
# 收集系统信息
./diagnose.sh > system-info.txt

# 收集错误日志
DEBUG=1 ./githooks/post-commit 2>&1 | tee error.log

# 收集配置信息
./lib/ai-config.sh show all > config.txt
```

---

**记住：大多数问题都有简单的解决方案，不要害怕尝试！** 🛠️✨
