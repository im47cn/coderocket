#!/bin/bash

# 测试提示词文档创建功能
# 用于验证安装脚本的新行为

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 测试提示词文档创建功能 ===${NC}"

# 创建临时测试目录
TEST_DIR="/tmp/codereview-cli-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo -e "${YELLOW}→ 创建测试环境: $TEST_DIR${NC}"

# 初始化Git仓库
git init
echo "# Test Project" > README.md
git add README.md
git commit -m "Initial commit"

echo -e "${GREEN}✓ Git仓库初始化完成${NC}"

# 模拟安装目录
MOCK_INSTALL_DIR="$TEST_DIR/.codereview-cli"
mkdir -p "$MOCK_INSTALL_DIR/prompts"

# 创建模拟的提示词文档
cat > "$MOCK_INSTALL_DIR/prompts/git-commit-review-prompt.md" << 'EOF'
# Git Commit Review Prompt

这是一个测试用的代码审查提示词文档。

## 审查要点

1. 代码质量
2. 安全性
3. 性能
4. 可维护性

请根据以上要点进行代码审查。
EOF

echo -e "${GREEN}✓ 模拟安装环境创建完成${NC}"

# 从原始脚本中提取setup_project_prompts函数进行测试
setup_project_prompts() {
    local INSTALL_DIR="$MOCK_INSTALL_DIR"
    
    # 询问是否需要创建项目级提示词文档
    echo ""
    echo "是否需要创建项目级的代码审查提示词文档？"
    echo "  - 选择 'y': 在当前项目创建 prompts/git-commit-review-prompt.md，可自定义审查规则"
    echo "  - 选择 'n': 使用全局默认提示词，无需在项目中创建文件"
    echo ""
    read -p "创建项目级提示词文档? (y/N): " create_prompts
    
    if [[ "$create_prompts" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}→ 创建项目级提示词文档...${NC}"
        # 创建prompts目录并复制提示词文档
        mkdir -p ./prompts
        if cp "$INSTALL_DIR/prompts/git-commit-review-prompt.md" ./prompts/; then
            echo -e "${GREEN}✓ 提示词文档已创建: ./prompts/git-commit-review-prompt.md${NC}"
            echo -e "${BLUE}  您可以编辑此文件来自定义代码审查规则${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ 提示词文档创建失败，将使用全局默认提示词${NC}"
            return 1
        fi
    else
        echo -e "${BLUE}✓ 将使用全局默认提示词，无需创建项目文件${NC}"
        return 0
    fi
}

# 测试函数
echo -e "\n${BLUE}=== 开始测试 ===${NC}"
echo "测试目录: $TEST_DIR"
echo "当前目录内容:"
ls -la

# 运行测试
setup_project_prompts

# 检查结果
echo -e "\n${BLUE}=== 测试结果 ===${NC}"
echo "当前目录内容:"
ls -la

if [ -d "./prompts" ]; then
    echo -e "${GREEN}✓ prompts目录已创建${NC}"
    if [ -f "./prompts/git-commit-review-prompt.md" ]; then
        echo -e "${GREEN}✓ 提示词文档已创建${NC}"
        echo "文档内容预览:"
        head -5 "./prompts/git-commit-review-prompt.md"
    else
        echo -e "${RED}✗ 提示词文档未创建${NC}"
    fi
else
    echo -e "${BLUE}ℹ prompts目录未创建（用户选择使用全局默认）${NC}"
fi

# 清理测试环境
echo -e "\n${YELLOW}→ 清理测试环境...${NC}"
cd /
rm -rf "$TEST_DIR"
echo -e "${GREEN}✓ 测试完成${NC}"
