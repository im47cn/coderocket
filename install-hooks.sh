#!/bin/bash

# CodeRocket Git Hooks 安装脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== CodeRocket Git Hooks 安装 ===${NC}"

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}错误：当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 获取仓库根目录
REPO_ROOT=$(git rev-parse --show-toplevel)
echo "仓库根目录: $REPO_ROOT"

# 获取配置值的函数
get_config_value() {
    local key=$1
    local default_value=$2
    local value=""

    # 优先级：环境变量 > 项目配置 > 全局配置 > 默认值
    if [ ! -z "${!key}" ]; then
        value="${!key}"
    elif [ -f "$REPO_ROOT/.ai-config" ]; then
        value=$(grep "^$key=" "$REPO_ROOT/.ai-config" 2>/dev/null | cut -d'=' -f2)
    elif [ -f "$HOME/.coderocket/ai-config" ]; then
        value=$(grep "^$key=" "$HOME/.coderocket/ai-config" 2>/dev/null | cut -d'=' -f2)
    elif [ -f "$REPO_ROOT/.env" ]; then
        value=$(grep "^$key=" "$REPO_ROOT/.env" 2>/dev/null | cut -d'=' -f2)
    fi

    if [ -z "$value" ]; then
        value="$default_value"
    fi

    echo "$value"
}

# 获取代码审查时机配置
REVIEW_TIMING=$(get_config_value "REVIEW_TIMING" "post-commit")
echo "代码审查时机: $REVIEW_TIMING"

# 创建 hooks 目录（如果不存在）
HOOKS_DIR="$REPO_ROOT/.git/hooks"
if [ ! -d "$HOOKS_DIR" ]; then
    mkdir -p "$HOOKS_DIR"
fi

# 根据配置安装相应的代码审查hook
if [ "$REVIEW_TIMING" = "pre-commit" ]; then
    echo -e "${YELLOW}→ 安装 pre-commit hook (提交前审查)...${NC}"
    cat > "$HOOKS_DIR/pre-commit" << 'EOF'
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

# 查找 pre-commit 脚本
PRE_COMMIT_SCRIPT=""
if [ -f "$REPO_ROOT/githooks/pre-commit" ]; then
    PRE_COMMIT_SCRIPT="$REPO_ROOT/githooks/pre-commit"
elif [ -f "$HOME/.coderocket/githooks/pre-commit" ]; then
    PRE_COMMIT_SCRIPT="$HOME/.coderocket/githooks/pre-commit"
else
    echo "错误：pre-commit 脚本不存在"
    echo "请确保 CodeRocket 已正确安装"
    exit 1
fi

# 执行 pre-commit hook
"$PRE_COMMIT_SCRIPT"
EOF
    chmod +x "$HOOKS_DIR/pre-commit"
    echo -e "${GREEN}✓ pre-commit hook 安装完成${NC}"
else
    echo -e "${YELLOW}→ 安装 post-commit hook (提交后审查)...${NC}"
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

# 查找 post-commit 脚本
POST_COMMIT_SCRIPT=""
if [ -f "$REPO_ROOT/githooks/post-commit" ]; then
    POST_COMMIT_SCRIPT="$REPO_ROOT/githooks/post-commit"
elif [ -f "$HOME/.coderocket/githooks/post-commit" ]; then
    POST_COMMIT_SCRIPT="$HOME/.coderocket/githooks/post-commit"
else
    echo "错误：post-commit 脚本不存在"
    echo "请确保 CodeRocket 已正确安装"
    exit 1
fi

# 执行 post-commit hook
"$POST_COMMIT_SCRIPT"
EOF
    chmod +x "$HOOKS_DIR/post-commit"
    echo -e "${GREEN}✓ post-commit hook 安装完成${NC}"
fi

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

# 查找 pre-push 脚本
PRE_PUSH_SCRIPT=""
if [ -f "$REPO_ROOT/githooks/pre-push" ]; then
    PRE_PUSH_SCRIPT="$REPO_ROOT/githooks/pre-push"
elif [ -f "$HOME/.coderocket/githooks/pre-push" ]; then
    PRE_PUSH_SCRIPT="$HOME/.coderocket/githooks/pre-push"
else
    echo "错误：pre-push 脚本不存在"
    echo "请确保 CodeRocket 已正确安装"
    exit 1
fi

# 执行 pre-push hook，传递所有参数
"$PRE_PUSH_SCRIPT" "$@"
EOF

# 设置执行权限
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

# 检查AI服务
echo -e "\n${YELLOW}=== AI服务检查 ===${NC}"

# 检查当前配置的AI服务
if [ -f "lib/ai-service-manager.sh" ]; then
    source lib/ai-service-manager.sh
    show_ai_service_status
else
    # 备用检查
    if command -v gemini &> /dev/null; then
        echo -e "${GREEN}✓ Gemini CLI 已安装${NC}"
    else
        echo -e "${YELLOW}⚠ 未检测到 Gemini CLI${NC}"
        echo "安装 Gemini CLI: npm install -g @google/gemini-cli"
    fi

    if command -v opencode &> /dev/null; then
        echo -e "${GREEN}✓ OpenCode CLI 已安装${NC}"
    else
        echo -e "${YELLOW}⚠ 未检测到 OpenCode CLI${NC}"
        echo "安装 OpenCode CLI: npm install -g @opencode/cli"
    fi

    if command -v claudecode &> /dev/null; then
        echo -e "${GREEN}✓ ClaudeCode CLI 已安装${NC}"
    else
        echo -e "${YELLOW}⚠ 未检测到 ClaudeCode CLI${NC}"
        echo "安装 ClaudeCode CLI: npm install -g @claudecode/cli"
    fi
fi

echo -e "\n${GREEN}=== 安装完成 ===${NC}"
echo "现在你可以："
if [ "$REVIEW_TIMING" = "pre-commit" ]; then
    echo "1. 使用 git commit 触发提交前代码审查（可能阻止有问题的提交）"
else
    echo "1. 使用 git commit 触发提交后代码审查"
fi
echo "2. 使用 git push 触发自动 MR 创建"
echo "3. 在 VS Code 和终端中都能正常工作"
echo ""
echo "💡 提示：可以使用 './lib/ai-config.sh timing' 来更改代码审查时机"
