#!/bin/bash

# CodeReview CLI Hooks 修复脚本
# 用于修复hooks路径问题

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== CodeReview CLI Hooks 修复脚本 ===${NC}"

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ 错误：当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 获取仓库根目录
REPO_ROOT=$(git rev-parse --show-toplevel)
echo "仓库根目录: $REPO_ROOT"

# 检查全局安装
GLOBAL_INSTALL_DIR="$HOME/.codereview-cli"
if [ ! -d "$GLOBAL_INSTALL_DIR" ]; then
    echo -e "${RED}❌ 错误：CodeReview CLI 未全局安装${NC}"
    echo "请先运行全局安装："
    echo "curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/install.sh | bash"
    exit 1
fi

echo -e "${GREEN}✓ 找到全局安装: $GLOBAL_INSTALL_DIR${NC}"

# 创建 hooks 目录
HOOKS_DIR="$REPO_ROOT/.git/hooks"
mkdir -p "$HOOKS_DIR"

# 修复 post-commit hook
echo -e "${YELLOW}→ 修复 post-commit hook...${NC}"
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash

# 获取 Git 仓库根目录
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# 如果不在 Git 仓库中，退出
if [ -z "$REPO_ROOT" ]; then
    echo "❌ 错误：不在 Git 仓库中"
    exit 1
fi

# 安全地加载必要的环境变量
# 只加载项目相关的环境变量，避免全局profile污染

# 加载项目环境文件
if [ -f "$REPO_ROOT/.env" ]; then
    # 只加载以特定前缀开头的环境变量，避免污染
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # 只加载AI和GitLab相关的环境变量
        if [[ $key =~ ^(AI_|GITLAB_|GEMINI_|OPENCODE_|CLAUDECODE_) ]]; then
            export "$key=$value"
        fi
    done < "$REPO_ROOT/.env" 2>/dev/null
fi

# 加载全局CodeReview CLI配置
if [ -f "$HOME/.codereview-cli/env" ]; then
    while IFS='=' read -r key value; do
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        if [[ $key =~ ^(AI_|GITLAB_|GEMINI_|OPENCODE_|CLAUDECODE_) ]]; then
            export "$key=$value"
        fi
    done < "$HOME/.codereview-cli/env" 2>/dev/null
fi

# 查找 post-commit 脚本
POST_COMMIT_SCRIPT=""
if [ -f "$REPO_ROOT/githooks/post-commit" ]; then
    POST_COMMIT_SCRIPT="$REPO_ROOT/githooks/post-commit"
elif [ -f "$HOME/.codereview-cli/githooks/post-commit" ]; then
    POST_COMMIT_SCRIPT="$HOME/.codereview-cli/githooks/post-commit"
else
    echo "❌ 错误：post-commit 脚本不存在"
    echo "请确保 CodeReview CLI 已正确安装"
    exit 1
fi

# 执行 post-commit hook
"$POST_COMMIT_SCRIPT"
EOF

# 修复 pre-push hook
echo -e "${YELLOW}→ 修复 pre-push hook...${NC}"
cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash

# 获取 Git 仓库根目录
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# 如果不在 Git 仓库中，退出
if [ -z "$REPO_ROOT" ]; then
    echo "❌ 错误：不在 Git 仓库中"
    exit 1
fi

# 安全地加载必要的环境变量
# 只加载项目相关的环境变量，避免全局profile污染

# 加载项目环境文件
if [ -f "$REPO_ROOT/.env" ]; then
    # 只加载以特定前缀开头的环境变量，避免污染
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # 只加载AI和GitLab相关的环境变量
        if [[ $key =~ ^(AI_|GITLAB_|GEMINI_|OPENCODE_|CLAUDECODE_) ]]; then
            export "$key=$value"
        fi
    done < "$REPO_ROOT/.env" 2>/dev/null
fi

# 加载全局CodeReview CLI配置
if [ -f "$HOME/.codereview-cli/env" ]; then
    while IFS='=' read -r key value; do
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        if [[ $key =~ ^(AI_|GITLAB_|GEMINI_|OPENCODE_|CLAUDECODE_) ]]; then
            export "$key=$value"
        fi
    done < "$HOME/.codereview-cli/env" 2>/dev/null
fi

# 查找 pre-push 脚本
PRE_PUSH_SCRIPT=""
if [ -f "$REPO_ROOT/githooks/pre-push" ]; then
    PRE_PUSH_SCRIPT="$REPO_ROOT/githooks/pre-push"
elif [ -f "$HOME/.codereview-cli/githooks/pre-push" ]; then
    PRE_PUSH_SCRIPT="$HOME/.codereview-cli/githooks/pre-push"
else
    echo "❌ 错误：pre-push 脚本不存在"
    echo "请确保 CodeReview CLI 已正确安装"
    exit 1
fi

# 执行 pre-push hook，传递所有参数
"$PRE_PUSH_SCRIPT" "$@"
EOF

# 设置执行权限
chmod +x "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/pre-push"

echo -e "${GREEN}✓ Git hooks 修复完成${NC}"

# 验证安装
echo -e "\n${YELLOW}=== 验证安装 ===${NC}"

# 检查hooks文件
if [ -x "$HOOKS_DIR/post-commit" ]; then
    echo -e "${GREEN}✓ post-commit hook 已安装并可执行${NC}"
else
    echo -e "${RED}❌ post-commit hook 安装失败${NC}"
fi

if [ -x "$HOOKS_DIR/pre-push" ]; then
    echo -e "${GREEN}✓ pre-push hook 已安装并可执行${NC}"
else
    echo -e "${RED}❌ pre-push hook 安装失败${NC}"
fi

# 检查全局脚本
if [ -f "$HOME/.codereview-cli/githooks/post-commit" ]; then
    echo -e "${GREEN}✓ 全局 post-commit 脚本存在${NC}"
else
    echo -e "${RED}❌ 全局 post-commit 脚本不存在${NC}"
fi

if [ -f "$HOME/.codereview-cli/githooks/pre-push" ]; then
    echo -e "${GREEN}✓ 全局 pre-push 脚本存在${NC}"
else
    echo -e "${RED}❌ 全局 pre-push 脚本不存在${NC}"
fi

# 检查AI服务管理器
if [ -f "$HOME/.codereview-cli/lib/ai-service-manager.sh" ]; then
    echo -e "${GREEN}✓ AI服务管理器存在${NC}"
else
    echo -e "${RED}❌ AI服务管理器不存在${NC}"
fi

echo -e "\n${BLUE}=== 修复完成 ===${NC}"
echo "现在你可以："
echo "1. 使用 git commit 触发自动代码审查"
echo "2. 使用 git push 触发自动 MR 创建"
echo ""
echo "如果仍有问题，请检查："
echo "1. 环境变量配置 (GITLAB_PERSONAL_ACCESS_TOKEN)"
echo "2. AI服务配置 (gemini config)"
echo "3. 网络连接"
