#!/bin/bash

# CodeReview CLI Git Hooks 安装脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CodeReview CLI Git Hooks 安装 ===${NC}"

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}错误：当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 获取仓库根目录
REPO_ROOT=$(git rev-parse --show-toplevel)
echo "仓库根目录: $REPO_ROOT"

# 创建 hooks 目录（如果不存在）
HOOKS_DIR="$REPO_ROOT/.git/hooks"
if [ ! -d "$HOOKS_DIR" ]; then
    mkdir -p "$HOOKS_DIR"
fi

# 安装 post-commit hook
echo -e "${YELLOW}→ 安装 post-commit hook...${NC}"
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash

# 获取 Git 仓库根目录
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# 如果不在 Git 仓库中，退出
if [ -z "$REPO_ROOT" ]; then
    echo "错误：不在 Git 仓库中"
    exit 1
fi

# 加载环境变量（如果存在）
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null
fi

if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null
fi

if [ -f "$HOME/.profile" ]; then
    source "$HOME/.profile" 2>/dev/null
fi

# 尝试从项目环境文件加载
if [ -f "$REPO_ROOT/.env" ]; then
    source "$REPO_ROOT/.env" 2>/dev/null
fi

# 检查 post-commit 脚本是否存在
if [ ! -f "$REPO_ROOT/githooks/post-commit" ]; then
    echo "错误：post-commit 脚本不存在: $REPO_ROOT/githooks/post-commit"
    exit 1
fi

# 执行 post-commit hook
"$REPO_ROOT/githooks/post-commit"
EOF

# 安装 pre-push hook
echo -e "${YELLOW}→ 安装 pre-push hook...${NC}"
cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash

# 获取 Git 仓库根目录
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# 如果不在 Git 仓库中，退出
if [ -z "$REPO_ROOT" ]; then
    echo "错误：不在 Git 仓库中"
    exit 1
fi

# 加载环境变量（如果存在）
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null
fi

if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc" 2>/dev/null
fi

if [ -f "$HOME/.profile" ]; then
    source "$HOME/.profile" 2>/dev/null
fi

# 尝试从项目环境文件加载
if [ -f "$REPO_ROOT/.env" ]; then
    source "$REPO_ROOT/.env" 2>/dev/null
fi

# 检查 pre-push 脚本是否存在
if [ ! -f "$REPO_ROOT/githooks/pre-push" ]; then
    echo "错误：pre-push 脚本不存在: $REPO_ROOT/githooks/pre-push"
    exit 1
fi

# 执行 pre-push hook
"$REPO_ROOT/githooks/pre-push"
EOF

# 设置执行权限
chmod +x "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/pre-push"

echo -e "${GREEN}✓ Git hooks 安装完成${NC}"

# 检查环境变量配置
echo -e "\n${YELLOW}=== 环境变量检查 ===${NC}"

if [ -z "$GITLAB_PERSONAL_ACCESS_TOKEN" ]; then
    echo -e "${YELLOW}⚠ 未检测到 GITLAB_PERSONAL_ACCESS_TOKEN 环境变量${NC}"
    echo "请按以下步骤配置："
    echo "1. 复制 .env.example 为 .env"
    echo "2. 在 .env 文件中设置你的 GitLab Personal Access Token"
    echo "3. 或者在你的 shell 配置文件中设置环境变量"
    echo ""
    echo "示例："
    echo "cp .env.example .env"
    echo "# 然后编辑 .env 文件"
else
    echo -e "${GREEN}✓ GITLAB_PERSONAL_ACCESS_TOKEN 已配置${NC}"
fi

# 检查 Gemini CLI
if command -v gemini &> /dev/null; then
    echo -e "${GREEN}✓ Gemini CLI 已安装${NC}"
else
    echo -e "${YELLOW}⚠ 未检测到 Gemini CLI${NC}"
    echo "安装 Gemini CLI 以启用智能 MR 生成功能："
    echo "npm install -g @google/generative-ai-cli"
fi

echo -e "\n${GREEN}=== 安装完成 ===${NC}"
echo "现在你可以："
echo "1. 使用 git commit 触发自动代码审查"
echo "2. 使用 git push 触发自动 MR 创建"
echo "3. 在 VS Code 和终端中都能正常工作"
