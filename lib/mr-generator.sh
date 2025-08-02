#!/bin/bash

# MR Generator Shared Module
# 共享的MR生成逻辑模块

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 生成MR标题的备用方案
#
# 功能: 根据分支命名规范生成备用MR标题
# 参数:
#   $1 - branch_name: 分支名称 (必需)
# 返回: 无 (直接输出到stdout)
# 复杂度: O(1) - 常数时间模式匹配
# 依赖: bash正则表达式匹配
# 调用者: claudecode_generate_mr_title()
# 模式匹配: 支持feature/, fix/, hotfix/, refactor/, docs/, test/前缀
# 示例:
#   generate_fallback_mr_title "feature/user-login"  # 输出: "✨ Feature: user-login"
#   generate_fallback_mr_title "fix/bug-123"         # 输出: "🐛 Fix: bug-123"
generate_fallback_mr_title() {
    local branch_name=$1

    # 使用正则表达式匹配分支命名规范，生成相应的emoji标题
    if [[ $branch_name =~ ^feature/.* ]]; then
        echo "✨ Feature: ${branch_name#feature/}"  # 移除feature/前缀
    elif [[ $branch_name =~ ^fix/.* ]]; then
        echo "🐛 Fix: ${branch_name#fix/}"  # 移除fix/前缀
    elif [[ $branch_name =~ ^hotfix/.* ]]; then
        echo "🚑 Hotfix: ${branch_name#hotfix/}"  # 移除hotfix/前缀
    elif [[ $branch_name =~ ^refactor/.* ]]; then
        echo "♻️ Refactor: ${branch_name#refactor/}"  # 移除refactor/前缀
    elif [[ $branch_name =~ ^docs/.* ]]; then
        echo "📝 Docs: ${branch_name#docs/}"  # 移除docs/前缀
    elif [[ $branch_name =~ ^test/.* ]]; then
        echo "🧪 Test: ${branch_name#test/}"  # 移除test/前缀
    else
        echo "🔀 Update: $branch_name"  # 通用更新标题
    fi
}

# 生成MR描述的备用方案
#
# 功能: 根据提交记录生成备用MR描述
# 参数:
#   $1 - commits: 提交记录字符串，格式为"hash|subject|author|date"
#   $2 - commit_count: 提交数量
# 返回: 无 (直接输出到stdout)
# 复杂度: O(n) - n为提交数量
# 依赖: echo命令, while循环, IFS分隔符处理
# 调用者: claudecode_generate_mr_description()
# 输出格式: Markdown格式的MR描述，包含变更概述和检查清单
# 示例:
#   generate_fallback_mr_description "abc123|feat: add login|user|2024-01-01" "1"
generate_fallback_mr_description() {
    local commits=$1
    local commit_count=$2

    echo "## 📋 变更概述"
    echo ""
    echo "本次合并包含 **$commit_count** 个提交，主要变更如下："
    echo ""

    # 处理提交列表 - 使用管道分隔符解析每个提交
    echo "$commits" | while IFS='|' read -r hash subject author date; do
        if [ ! -z "$hash" ]; then
            echo "- $subject"  # 输出提交主题
        fi
    done

    echo ""
    echo "## ✅ 检查清单"
    echo ""
    echo "- [ ] 代码已经过自测"
    echo "- [ ] 相关文档已更新"
    echo "- [ ] 测试用例已添加/更新"
    echo "- [ ] 无明显的性能影响"
    echo "- [ ] 符合代码规范"
}

# 通用的MR标题生成提示词
#
# 功能: 生成用于AI服务的MR标题生成提示词
# 参数:
#   $1 - commit_list: 格式化的提交列表
# 返回: 无 (直接输出到stdout)
# 复杂度: O(1) - 常数时间模板生成
# 依赖: cat命令, here document (<<EOF)
# 调用者: claudecode_generate_mr_title()
# 输出格式: 结构化的AI提示词，包含要求和示例
# 提示词要求: 中文、50字符限制、emoji支持、概括性
# 示例:
#   prompt=$(get_mr_title_prompt "- feat: add login (2024-01-01)")
get_mr_title_prompt() {
    local commit_list=$1

    # 使用here document生成结构化的AI提示词
    cat <<EOF
请根据以下 Git 提交记录，生成一个简洁有意义的 MR 标题。要求：
1. 标题应该概括主要变更内容
2. 使用中文
3. 不超过 50 个字符
4. 不需要包含提交数量
5. 可以使用适当的 emoji 图标（如 ✨ 🐛 📝 ♻️ 等）

提交记录：
$commit_list

请直接返回标题，不要包含其他解释：
EOF
}

# 通用的MR描述生成提示词
#
# 功能: 生成用于AI服务的MR描述生成提示词
# 参数:
#   $1 - commit_list: 格式化的提交列表
# 返回: 无 (直接输出到stdout)
# 复杂度: O(1) - 常数时间模板生成
# 依赖: cat命令, here document (<<EOF)
# 调用者: claudecode_generate_mr_description()
# 输出格式: 结构化的AI提示词，包含格式要求和模板
# 提示词要求: 中文、结构化、概括性、审查者友好
# 示例:
#   prompt=$(get_mr_description_prompt "- feat: add login (2024-01-01)")
get_mr_description_prompt() {
    local commit_list=$1

    # 使用here document生成结构化的AI提示词
    cat <<EOF
请根据以下 Git 提交记录，生成一个专业的 MR 描述。要求：
1. 总结主要变更内容和目标
2. 使用中文
3. 结构清晰，重点突出
4. 不要简单罗列提交，而是要概括和总结
5. 描述应该让审查者快速理解这次变更的目的和影响

提交记录：
$commit_list

请按以下格式返回：
## 📋 变更概述

[在这里写变更的总结和目标]

## 🔧 主要改进

[在这里列出主要的改进点，用简洁的要点形式]
EOF
}

# 清理和验证AI生成的标题
#
# 功能: 清理、验证和格式化AI生成的MR标题
# 参数:
#   $1 - title: 原始标题字符串 (必需)
#   $2 - max_length: 最大长度限制 (可选, 默认: 50)
# 返回: 0=验证通过, 1=标题为空
# 输出: 清理后的标题到stdout
# 复杂度: O(n) - n为标题长度
# 依赖: echo, head, sed命令
# 调用者: claudecode_generate_mr_title()
# 处理逻辑: 取首行 -> 去除首尾空白 -> 长度检查 -> 截断处理 -> 空值检查
# 示例:
#   clean_title=$(clean_and_validate_title "  很长的标题内容...  " 20)
clean_and_validate_title() {
    local title=$1
    local max_length=${2:-50}

    # 清理标题：取第一行并去除首尾空白字符
    title=$(echo "$title" | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    # 验证长度并处理超长标题
    if [ ${#title} -gt $max_length ]; then
        # 如果太长，截断并添加省略号
        title="${title:0:$((max_length-3))}..."
    fi

    # 验证是否为空
    if [ -z "$title" ]; then
        return 1
    fi

    echo "$title"
    return 0
}

# 添加检查清单到MR描述
add_checklist_to_description() {
    local description=$1
    
    echo "$description"
    echo ""
    echo "## ✅ 检查清单"
    echo ""
    echo "- [ ] 代码已经过自测"
    echo "- [ ] 相关文档已更新"
    echo "- [ ] 测试用例已添加/更新"
    echo "- [ ] 无明显的性能影响"
    echo "- [ ] 符合代码规范"
}

# 处理单个提交的情况
handle_single_commit() {
    local commits=$1
    
    # 对于单个提交，直接使用提交信息作为标题
    local title=$(echo "$commits" | cut -d'|' -f2)
    
    # 生成简单的描述
    local commit_msg=$(git log -1 --pretty=%B 2>/dev/null || echo "单个提交变更")
    local description="## 📋 变更概述

$commit_msg"
    
    echo "TITLE:$title"
    echo "DESCRIPTION:$(add_checklist_to_description "$description")"
}

# 准备提交列表给AI
prepare_commit_list() {
    local commits=$1
    local commit_list=""
    
    while IFS='|' read -r hash subject author date; do
        if [ ! -z "$hash" ]; then
            commit_list+="- $subject ($date)\n"
        fi
    done <<< "$commits"
    
    echo -e "$commit_list"
}

# 验证提交数据格式
validate_commits_format() {
    local commits=$1
    
    # 检查是否为空
    if [ -z "$commits" ]; then
        return 1
    fi
    
    # 检查格式是否正确（应该包含|分隔符）
    if ! echo "$commits" | grep -q '|'; then
        return 1
    fi
    
    return 0
}

# 主函数 - 用于测试
main() {
    case "${1:-help}" in
        "fallback-title")
            generate_fallback_mr_title "$2"
            ;;
        "fallback-description")
            generate_fallback_mr_description "$2" "$3"
            ;;
        "title-prompt")
            get_mr_title_prompt "$2"
            ;;
        "description-prompt")
            get_mr_description_prompt "$2"
            ;;
        "clean-title")
            clean_and_validate_title "$2" "$3"
            ;;
        "single-commit")
            handle_single_commit "$2"
            ;;
        "prepare-commits")
            prepare_commit_list "$2"
            ;;
        "validate-commits")
            if validate_commits_format "$2"; then
                echo "✓ 提交格式有效"
                return 0
            else
                echo "✗ 提交格式无效"
                return 1
            fi
            ;;
        "help"|*)
            echo "MR生成器共享模块"
            echo ""
            echo "用法: $0 <命令> [参数...]"
            echo ""
            echo "命令:"
            echo "  fallback-title <branch>           - 生成备用标题"
            echo "  fallback-description <commits> <count> - 生成备用描述"
            echo "  title-prompt <commits>            - 获取标题生成提示词"
            echo "  description-prompt <commits>      - 获取描述生成提示词"
            echo "  clean-title <title> [max_length]  - 清理和验证标题"
            echo "  single-commit <commits>           - 处理单个提交"
            echo "  prepare-commits <commits>         - 准备提交列表"
            echo "  validate-commits <commits>        - 验证提交格式"
            echo "  help                              - 显示帮助信息"
            ;;
    esac
}

# 如果直接执行此脚本，运行主函数
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
