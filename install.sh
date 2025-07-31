#!/bin/bash

# CodeRocket 一键安装脚本
# 使用方法: curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket/main/install.sh | bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REPO_URL="https://github.com/im47cn/coderocket.git"
INSTALL_DIR="$HOME/.coderocket"
TEMP_DIR="/tmp/coderocket-install"

echo -e "${BLUE}=== CodeRocket 一键安装 ===${NC}"
echo ""

# 检查系统要求
check_requirements() {
    echo -e "${YELLOW}→ 检查系统要求...${NC}"
    
    # 检查 Git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git 未安装${NC}"
        echo "请先安装 Git: https://git-scm.com/downloads"
        exit 1
    fi
    echo -e "${GREEN}✓ Git 已安装${NC}"
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}⚠ Node.js 未安装${NC}"
        echo "将尝试安装 Node.js..."
        
        # 尝试使用不同的包管理器安装 Node.js
        if command -v brew &> /dev/null; then
            brew install node
        elif command -v apt-get &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command -v yum &> /dev/null; then
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo yum install -y nodejs
        else
            echo -e "${RED}✗ 无法自动安装 Node.js${NC}"
            echo "请手动安装 Node.js: https://nodejs.org/"
            exit 1
        fi
    fi
    echo -e "${GREEN}✓ Node.js 已安装${NC}"
    
    # 检查 Python3
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}⚠ Python3 未安装${NC}"
        echo "Python3 是 GitLab API 调用所必需的"
        
        # 尝试安装 Python3
        if command -v brew &> /dev/null; then
            brew install python3
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y python3
        elif command -v yum &> /dev/null; then
            sudo yum install -y python3
        else
            echo -e "${RED}✗ 无法自动安装 Python3${NC}"
            echo "请手动安装 Python3"
            exit 1
        fi
    fi
    echo -e "${GREEN}✓ Python3 已安装${NC}"
}

# 安装AI服务CLI工具
install_ai_services() {
    echo -e "${YELLOW}→ 安装AI服务CLI工具...${NC}"

    # 安装 Gemini CLI
    if command -v gemini &> /dev/null; then
        echo -e "${GREEN}✓ Gemini CLI 已安装${NC}"
    else
        echo -e "${YELLOW}→ 安装 Gemini CLI...${NC}"
        if npm install -g @google/gemini-cli; then
            echo -e "${GREEN}✓ Gemini CLI 安装成功${NC}"
        else
            echo -e "${YELLOW}⚠ Gemini CLI 安装失败，可稍后手动安装${NC}"
            echo "  手动安装: npm install -g @google/gemini-cli"
        fi
    fi

    # 安装 OpenCode CLI (可选)
    if command -v opencode &> /dev/null; then
        echo -e "${GREEN}✓ OpenCode CLI 已安装${NC}"
    else
        echo -e "${YELLOW}→ OpenCode CLI 未安装 (可选)${NC}"
        echo "  手动安装: npm install -g @opencode/cli"
    fi

    # 安装 ClaudeCode CLI (可选)
    if command -v claudecode &> /dev/null; then
        echo -e "${GREEN}✓ ClaudeCode CLI 已安装${NC}"
    else
        echo -e "${YELLOW}→ ClaudeCode CLI 未安装 (可选)${NC}"
        echo "  手动安装: npm install -g @claudecode/cli"
    fi
}

# 下载项目文件
download_project() {
    echo -e "${YELLOW}→ 下载项目文件...${NC}"
    
    # 清理临时目录
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # 克隆项目
    if git clone "$REPO_URL" "$TEMP_DIR"; then
        echo -e "${GREEN}✓ 项目文件下载成功${NC}"
    else
        echo -e "${RED}✗ 项目文件下载失败${NC}"
        exit 1
    fi
}

# 安装到目标目录
install_to_directory() {
    echo -e "${YELLOW}→ 安装到 $INSTALL_DIR...${NC}"

    # 创建安装目录
    mkdir -p "$INSTALL_DIR"

    # 复制文件（排除.git目录）
    rsync -av --exclude='.git' "$TEMP_DIR"/ "$INSTALL_DIR/"

    # 设置执行权限
    chmod +x "$INSTALL_DIR/install-hooks.sh"
    chmod +x "$INSTALL_DIR/githooks/post-commit"
    chmod +x "$INSTALL_DIR/githooks/pre-push"

    echo -e "${GREEN}✓ 安装完成${NC}"
}

# 创建全局命令
create_global_command() {
    echo -e "${YELLOW}→ 创建全局命令...${NC}"

    local bin_dir="/usr/local/bin"

    # 创建主命令脚本内容
    read -r -d '' cmd_content << 'EOF' || true
#!/bin/bash

# CodeRocket 全局命令
# 兼容 CodeRocket 老用户使用习惯
INSTALL_DIR="INSTALL_DIR_PLACEHOLDER"

case "\$1" in
    "setup")
        echo "🔧 为当前项目设置 CodeRocket..."
        if [ ! -d ".git" ]; then
            echo "❌ 错误：当前目录不是 Git 仓库"
            exit 1
        fi
        "\$INSTALL_DIR/install-hooks.sh"
        ;;
    "update")
        echo "🔄 更新 CodeRocket..."

        # 检查安装目录是否存在
        if [ ! -d "\$INSTALL_DIR" ]; then
            echo "❌ 错误：CodeRocket 未安装"
            echo "请先运行安装脚本："
            echo "curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket/main/install.sh | bash"
            exit 1
        fi

        # 重新下载和安装最新版本
        TEMP_DIR="/tmp/coderocket-update"
        REPO_URL="https://github.com/im47cn/coderocket.git"

        # 清理临时目录
        rm -rf "\$TEMP_DIR"
        mkdir -p "\$TEMP_DIR"

        # 下载最新版本
        if ! git clone "\$REPO_URL" "\$TEMP_DIR"; then
            echo "❌ 错误：无法下载最新版本"
            echo "请检查网络连接或手动更新："
            echo "curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket/main/install.sh | bash"
            exit 1
        fi

        # 备份当前版本（如果存在VERSION文件）
        OLD_VERSION=""
        if [ -f "\$INSTALL_DIR/VERSION" ]; then
            OLD_VERSION=\$(cat "\$INSTALL_DIR/VERSION")
        fi

        # 获取新版本
        NEW_VERSION=""
        if [ -f "\$TEMP_DIR/VERSION" ]; then
            NEW_VERSION=\$(cat "\$TEMP_DIR/VERSION")
        fi

        # 检查是否需要更新
        if [ "\$OLD_VERSION" = "\$NEW_VERSION" ] && [ ! -z "\$OLD_VERSION" ]; then
            echo "✅ 已是最新版本"
            echo "📋 当前版本: \$OLD_VERSION"
            rm -rf "\$TEMP_DIR"
            exit 0
        fi

        # 复制新文件到安装目录（排除.git目录）
        if rsync -av --exclude='.git' "\$TEMP_DIR"/ "\$INSTALL_DIR/"; then
            # 设置执行权限
            chmod +x "\$INSTALL_DIR/install-hooks.sh"
            chmod +x "\$INSTALL_DIR/githooks/post-commit"
            chmod +x "\$INSTALL_DIR/githooks/pre-push"

            echo "✅ 更新完成"
            if [ ! -z "\$NEW_VERSION" ]; then
                echo "📋 当前版本: \$NEW_VERSION"
                if [ ! -z "\$OLD_VERSION" ]; then
                    echo "📋 从版本 \$OLD_VERSION 更新到 \$NEW_VERSION"
                fi
            else
                echo "📋 当前版本: \$(cat "\$INSTALL_DIR/VERSION" 2>/dev/null || echo '未知')"
            fi
        else
            echo "❌ 更新失败"
            echo "请尝试重新安装："
            echo "curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket/main/install.sh | bash"
            exit 1
        fi

        # 清理临时目录
        rm -rf "\$TEMP_DIR"
        ;;
    "config")
        echo "⚙️ 配置AI服务..."
        if [ -f "\$INSTALL_DIR/lib/ai-config.sh" ]; then
            "\$INSTALL_DIR/lib/ai-config.sh" select
        else
            echo "请选择要配置的AI服务："
            echo "1. Gemini - gemini config"
            echo "2. OpenCode - opencode config"
            echo "3. ClaudeCode - claudecode config"
        fi
        ;;
    "timing")
        echo "⏰ 配置代码审查时机..."
        if [ -f "\$INSTALL_DIR/lib/ai-config.sh" ]; then
            "\$INSTALL_DIR/lib/ai-config.sh" timing
        else
            echo "请手动配置代码审查时机："
            echo "在 .env 文件中设置 REVIEW_TIMING=pre-commit 或 REVIEW_TIMING=post-commit"
        fi
        ;;
    "version"|"-v"|"--version")
        echo "CodeRocket v1.0.0"
        echo "安装路径: \$INSTALL_DIR"
        ;;
    "review")
        # 检查是否在 Git 仓库中
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
            echo "❌ 错误：当前目录不是 Git 仓库"
            echo "请在 Git 仓库目录中运行此命令"
            exit 1
        fi

        echo "🚀 正在执行代码审查..."

        # 获取 Git 仓库根目录
        REPO_ROOT=\$(git rev-parse --show-toplevel 2>/dev/null)

        # 检查提示词文件是否存在（优先使用项目级配置）
        PROMPT_FILE=""
        if [ -f "\$REPO_ROOT/prompts/git-commit-review-prompt.md" ]; then
            PROMPT_FILE="\$REPO_ROOT/prompts/git-commit-review-prompt.md"
        elif [ -f "\$INSTALL_DIR/prompts/git-commit-review-prompt.md" ]; then
            PROMPT_FILE="\$INSTALL_DIR/prompts/git-commit-review-prompt.md"
        else
            echo "❌ 错误：提示词文件不存在"
            echo "请运行: coderocket setup 来配置项目"
            exit 1
        fi

        # 检查 Gemini CLI 是否可用
        if ! command -v gemini &> /dev/null; then
            echo "❌ 错误：Gemini CLI 未安装"
            echo "安装命令: npm install -g @google/generative-ai-cli"
            exit 1
        fi

        # 创建 review_logs 目录（如果不存在）
        mkdir -p "\$REPO_ROOT/review_logs"

        # 切换到仓库根目录执行
        cd "\$REPO_ROOT"

        # 准备更明确的提示词
        PROMPT="请执行以下任务：
1. 你是代码审查专家，需要对最新的 git commit 进行审查
2. 使用 git --no-pager show 命令获取最新提交的详细信息
3. 根据提示词文件中的指导进行全面代码审查
4. 生成审查报告并保存到 review_logs 目录
5. 不要询问用户，直接自主执行所有步骤
6. 这是一个自动化流程，请直接开始执行"

        if cat "\$PROMPT_FILE" | gemini -p "\$PROMPT" -y; then
            echo "👌 代码审查完成"
            echo "📝 审查报告已保存到 \$REPO_ROOT/review_logs 目录"

            # 显示最新的审查报告
            LATEST_REPORT=\$(ls -t "\$REPO_ROOT/review_logs"/*.md 2>/dev/null | head -1)
            if [ -n "\$LATEST_REPORT" ]; then
                echo "📄 最新审查报告: \$(basename "\$LATEST_REPORT")"
            fi
        else
            echo "❌ 代码审查失败"
            exit 1
        fi
        ;;
    "help"|"-h"|"--help")
        # 检测当前命令名称
        CURRENT_CMD=\$(basename "\$0")
        echo "CodeRocket - AI 驱动的代码审查工具"
        echo ""
        echo "用法: \$CURRENT_CMD <命令>"
        echo ""
        echo "命令:"
        echo "  review   对当前 Git 仓库的最新提交进行代码审查"
        echo "  setup    为当前项目设置 CodeRocket hooks"
        echo "  update   更新到最新版本"
        echo "  config   配置AI服务"
        echo "  timing   配置代码审查时机（提交前/提交后）"
        echo "  version  显示版本信息"
        echo "  help     显示此帮助信息"
        echo ""
        echo "快速使用："
        echo "  cd your-git-project"
        echo "  \$CURRENT_CMD review    # 直接审查最新提交"
        echo ""
        echo "兼容命令："
        echo "  coderocket, coderocket, cr 都可以使用"
        echo ""
        echo "全局安装后，新创建的 Git 仓库会自动包含 CodeRocket"
        echo "对于现有仓库，请在仓库目录中运行: \$CURRENT_CMD setup"
        ;;
    "")
        # 无参数时的默认行为
        if git rev-parse --git-dir > /dev/null 2>&1; then
            echo "🔍 检测到 Git 仓库，开始代码审查..."
            # 重用 review 命令的逻辑
            "\$0" review
        else
            CURRENT_CMD=\$(basename "\$0")
            echo "📋 CodeRocket - AI 驱动的代码审查工具"
            echo ""
            echo "当前目录不是 Git 仓库。"
            echo ""
            echo "使用方法："
            echo "1. 在 Git 仓库中直接运行 '\$CURRENT_CMD' 进行代码审查"
            echo "2. 运行 '\$CURRENT_CMD help' 查看所有可用命令"
            echo ""
            echo "兼容命令："
            echo "  coderocket, coderocket, cr 都可以使用"
            echo ""
            echo "如需在当前目录创建 Git 仓库："
            echo "  git init"
            echo "  # 添加文件并提交"
            echo "  git add ."
            echo "  git commit -m 'Initial commit'"
            echo "  \$CURRENT_CMD  # 然后运行代码审查"
        fi
        ;;
    *)
        CURRENT_CMD=\$(basename "\$0")
        echo "❌ 未知命令: \$1"
        echo "运行 '\$CURRENT_CMD help' 查看可用命令"
        exit 1
        ;;
esac
EOF

    # 替换安装目录占位符
    cmd_content="${cmd_content//INSTALL_DIR_PLACEHOLDER/$INSTALL_DIR}"

    # 创建命令的函数
    create_command() {
        local cmd_name="$1"
        local cmd_file="$bin_dir/$cmd_name"

        if [ ! -w "$bin_dir" ]; then
            echo -e "${YELLOW}  创建 $cmd_name 命令（需要管理员权限）${NC}"
            echo "$cmd_content" | sudo tee "$cmd_file" > /dev/null
            sudo chmod +x "$cmd_file"
        else
            echo -e "${YELLOW}  创建 $cmd_name 命令${NC}"
            echo "$cmd_content" > "$cmd_file"
            chmod +x "$cmd_file"
        fi
    }

    # 创建主命令和兼容命令
    create_command "coderocket"
    create_command "coderocket"  # 兼容老用户
    create_command "cr"              # 简短别名

    echo -e "${GREEN}✓ 全局命令创建完成${NC}"
    echo -e "${BLUE}  可用命令: coderocket, coderocket, cr${NC}"
}


setup_global_hooks() {
    echo -e "${YELLOW}→ 配置全局 Git hooks 模板...${NC}"

    # 创建全局 Git hooks 模板目录
    local git_template_dir="$HOME/.git-templates/hooks"
    mkdir -p "$git_template_dir"

    # 创建全局 post-commit hook
    cat > "$git_template_dir/post-commit" << 'EOF'
#!/bin/bash

# 获取 Git 仓库根目录
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# 如果不在 Git 仓库中，退出
if [ -z "$REPO_ROOT" ]; then
    echo "❌ 错误：不在 Git 仓库中"
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

# 检查提示词文件是否存在（优先使用项目级配置）
PROMPT_FILE=""
if [ -f "$REPO_ROOT/prompts/git-commit-review-prompt.md" ]; then
    PROMPT_FILE="$REPO_ROOT/prompts/git-commit-review-prompt.md"
elif [ -f "$HOME/.coderocket/prompts/git-commit-review-prompt.md" ]; then
    PROMPT_FILE="$HOME/.coderocket/prompts/git-commit-review-prompt.md"
else
    echo "❌ 错误：提示词文件不存在"
    echo "请运行: coderocket setup 来配置项目"
    exit 1
fi

# 检查 Gemini CLI 是否可用
if ! command -v gemini &> /dev/null; then
    echo "❌ 错误：Gemini CLI 未安装"
    echo "安装命令: npm install -g @google/gemini-cli"
    exit 1
fi

# 创建 review_logs 目录（如果不存在）
mkdir -p "$REPO_ROOT/review_logs"

echo "🚀 正在执行 commit 后的代码审查..."

# 切换到仓库根目录执行
cd "$REPO_ROOT"

# 准备更明确的提示词
PROMPT="请执行以下任务：
1. 你是代码审查专家，需要对最新的 git commit 进行审查
2. 使用 git --no-pager show 命令获取最新提交的详细信息
3. 根据提示词文件中的指导进行全面代码审查
4. 生成审查报告并保存到 review_logs 目录
5. 不要询问用户，直接自主执行所有步骤
6. 这是一个自动化流程，请直接开始执行"

if cat "$PROMPT_FILE" | gemini -p "$PROMPT" -y; then
    echo "👌 代码审查完成"
    echo "📝 审查报告已保存到 $REPO_ROOT/review_logs 目录"
else
    echo "❌ 代码审查失败，但不影响提交"
fi
EOF

    # 创建全局 pre-push hook
    cp "$INSTALL_DIR/githooks/pre-push" "$git_template_dir/pre-push"

    # 设置执行权限
    chmod +x "$git_template_dir/post-commit"
    chmod +x "$git_template_dir/pre-push"

    # 配置 Git 使用全局模板
    git config --global init.templateDir "$HOME/.git-templates"

    echo -e "${GREEN}✓ 全局 Git hooks 模板配置完成${NC}"
    echo -e "${BLUE}  新创建的 Git 仓库将自动包含 CodeRocket hooks${NC}"
}

# 为现有仓库安装 hooks
setup_existing_repos() {
    echo -e "${YELLOW}→ 为现有仓库安装 hooks...${NC}"

    # 检查是否在 Git 仓库中
    if git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${BLUE}  检测到当前目录是 Git 仓库，正在安装 hooks...${NC}"
        setup_current_project
    fi

    # 询问是否为其他仓库安装
    echo ""
    echo "是否要为其他现有的 Git 仓库安装 hooks？"
    echo "1) 是 - 我会提供仓库路径"
    echo "2) 否 - 跳过"
    read -p "请选择 (1/2): " choice

    case $choice in
        1)
            while true; do
                read -p "请输入 Git 仓库路径 (或输入 'done' 完成): " repo_path
                if [ "$repo_path" = "done" ]; then
                    break
                fi

                if [ -d "$repo_path/.git" ]; then
                    echo -e "${BLUE}  为 $repo_path 安装 hooks...${NC}"
                    (cd "$repo_path" && "$INSTALL_DIR/install-hooks.sh")
                else
                    echo -e "${RED}✗ $repo_path 不是有效的 Git 仓库${NC}"
                fi
            done
            ;;
        2)
            echo -e "${BLUE}  跳过现有仓库配置${NC}"
            ;;
        *)
            echo -e "${YELLOW}  无效选择，跳过现有仓库配置${NC}"
            ;;
    esac
}

# 配置当前项目
setup_current_project() {
    # 复制必要文件到当前项目
    cp "$INSTALL_DIR/prompts/git-commit-review-prompt.md" ./prompts/ 2>/dev/null || {
        mkdir -p ./prompts
        cp "$INSTALL_DIR/prompts/git-commit-review-prompt.md" ./prompts/
    }

    cp "$INSTALL_DIR/.env.example" ./ 2>/dev/null || true

    # 运行安装脚本
    if "$INSTALL_DIR/install-hooks.sh"; then
        echo -e "${GREEN}✓ 项目配置完成${NC}"
    else
        echo -e "${YELLOW}⚠ 项目配置失败，请手动运行: $INSTALL_DIR/install-hooks.sh${NC}"
    fi
}

# 配置AI服务
configure_ai_services() {
    echo -e "${YELLOW}→ 配置AI服务...${NC}"

    # 检查是否有AI配置工具
    if [ -f "$INSTALL_DIR/lib/ai-config.sh" ]; then
        echo "使用AI配置工具进行配置..."
        "$INSTALL_DIR/lib/ai-config.sh" select
    else
        # 备用配置方式
        echo "请选择要配置的AI服务："
        echo "1. Gemini (默认)"
        echo "2. OpenCode"
        echo "3. ClaudeCode"
        echo "4. 跳过配置"

        read -p "请选择 (1-4，默认为1): " choice
        case ${choice:-1} in
            1)
                if command -v gemini &> /dev/null; then
                    echo "配置 Gemini API..."
                    echo "1. 访问 https://aistudio.google.com/app/apikey"
                    echo "2. 创建 API 密钥"
                    echo "3. 运行: gemini config"
                    echo ""
                    if gemini config; then
                        echo -e "${GREEN}✓ Gemini API 配置完成${NC}"
                    else
                        echo -e "${YELLOW}⚠ Gemini API 配置跳过${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠ Gemini CLI 未安装${NC}"
                fi
                ;;
            2)
                echo "OpenCode 配置说明："
                echo "1. 获取 OpenCode API 密钥"
                echo "2. 运行: opencode config"
                echo "3. 或设置环境变量: export OPENCODE_API_KEY='your_key'"
                ;;
            3)
                echo "ClaudeCode 配置说明："
                echo "1. 获取 ClaudeCode API 密钥"
                echo "2. 运行: claudecode config"
                echo "3. 或设置环境变量: export CLAUDECODE_API_KEY='your_key'"
                ;;
            4)
                echo -e "${YELLOW}⚠ 跳过AI服务配置${NC}"
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
    fi
}

# 显示后续步骤
show_next_steps() {
    echo ""
    echo -e "${GREEN}=== 安装完成 ===${NC}"
    echo ""
    echo "🎉 CodeRocket 已成功安装！"
    echo ""

    # 检查是否为全局安装
    if command -v coderocket &> /dev/null; then
        echo -e "${BLUE}全局安装完成！${NC}"
        echo ""
        echo -e "${BLUE}常用命令：${NC}"
        echo "• coderocket setup        - 为现有项目设置 CodeRocket"
        echo "• coderocket update       - 更新到最新版本"
        echo "• coderocket config       - 配置 AI 服务"
        echo "• coderocket help         - 查看帮助信息"
        echo ""
        echo -e "${BLUE}兼容命令：${NC}"
        echo "• coderocket, cr      - 兼容老用户使用习惯"
        echo ""
        echo -e "${BLUE}使用说明：${NC}"
        echo "1. 新创建的 Git 仓库会自动包含 CodeRocket"
        echo "2. 对于现有仓库，请在仓库目录中运行: coderocket setup"
        echo "3. 配置环境变量（可选）："
        echo "   export GITLAB_PERSONAL_ACCESS_TOKEN='your_token_here'"
        echo ""
    else
        echo -e "${BLUE}项目安装完成！${NC}"
        echo ""
        echo -e "${BLUE}后续步骤：${NC}"
        echo "1. 配置环境变量："
        echo "   cp .env.example .env"
        echo "   # 编辑 .env 文件，设置你的 GitLab Token"
        echo ""
        echo "2. 在其他项目中使用："
        echo "   cd /path/to/your/project"
        echo "   $INSTALL_DIR/install-hooks.sh"
        echo ""
    fi

    echo -e "${BLUE}文档链接：${NC}"
    echo "- 项目主页: https://github.com/im47cn/coderocket"
    echo "- VS Code 设置: $INSTALL_DIR/docs/VSCODE_SETUP.md"
    echo "- 测试指南: $INSTALL_DIR/docs/VSCODE_TEST_GUIDE.md"
    echo ""
    echo -e "${GREEN}现在你可以正常使用 git commit 和 git push 了！${NC}"
}

# 清理临时文件
cleanup() {
    echo -e "${YELLOW}→ 清理临时文件...${NC}"
    rm -rf "$TEMP_DIR"
}

# 选择安装模式
choose_install_mode() {
    echo ""
    echo -e "${BLUE}=== 选择安装模式 ===${NC}"
    echo ""
    echo -e "${GREEN}1) 全局安装（推荐）${NC}"
    echo "   ✅ 新创建的 Git 仓库自动包含 CodeRocket"
    echo "   ✅ 提供 'coderocket' 全局命令（兼容 coderocket, cr）"
    echo "   ✅ 现有仓库只需运行 'coderocket setup'"
    echo "   ✅ 一次安装，终身受益"
    echo ""
    echo -e "${YELLOW}2) 仅当前项目${NC}"
    echo "   ⚠️  只为当前项目安装"
    echo "   ⚠️  需要为每个项目单独安装"
    echo "   ⚠️  容易遗漏新项目"
    echo ""

    # 检查是否有可用的终端输入
    if [ -t 0 ]; then
        # 有终端输入，可以交互
        while true; do
            read -p "请选择安装模式 (1/2，默认为 1): " choice
            case ${choice:-1} in
                1)
                    echo -e "${GREEN}✓ 选择全局安装模式${NC}"
                    return 0
                    ;;
                2)
                    echo -e "${GREEN}✓ 选择项目安装模式${NC}"
                    return 1
                    ;;
                *)
                    echo -e "${RED}无效选择，请输入 1 或 2${NC}"
                    ;;
            esac
        done
    else
        # 没有终端输入（如通过 curl | bash），使用默认选择
        echo -e "${YELLOW}检测到非交互式环境，使用默认的全局安装模式${NC}"
        echo -e "${BLUE}如需选择安装模式，请下载脚本后本地执行：${NC}"
        echo -e "${BLUE}  wget https://raw.githubusercontent.com/im47cn/coderocket/main/install.sh${NC}"
        echo -e "${BLUE}  chmod +x install.sh${NC}"
        echo -e "${BLUE}  ./install.sh${NC}"
        echo ""
        sleep 3
        echo -e "${GREEN}✓ 使用默认的全局安装模式${NC}"
        return 0
    fi
}

# 主函数
main() {
    check_requirements
    install_ai_services
    download_project
    install_to_directory

    # 选择安装模式
    if choose_install_mode; then
        # 全局安装模式
        create_global_command
        setup_global_hooks
        setup_existing_repos
    else
        # 项目安装模式
        setup_current_project
    fi

    configure_ai_services
    cleanup
    show_next_steps
}

# 错误处理
trap 'echo -e "${RED}安装过程中发生错误${NC}"; cleanup; exit 1' ERR

# 执行主函数
main
