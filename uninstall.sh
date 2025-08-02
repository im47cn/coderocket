#!/bin/bash

# CodeRocket CLI 卸载脚本
# 完全移除 CodeRocket CLI 及其所有组件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
INSTALL_DIR="$HOME/.coderocket"
USER_BIN_DIR="$HOME/.local/bin"
GLOBAL_BIN_DIR="/usr/local/bin"
GIT_TEMPLATE_DIR="$HOME/.git-templates"

# 显示横幅
show_uninstall_banner() {
    echo -e "${RED}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    CodeRocket CLI 卸载                      ║"
    echo "║                                                              ║"
    echo "║  ⚠️  警告：此操作将完全移除 CodeRocket CLI                   ║"
    echo "║      包括所有配置、日志和 Git hooks                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查是否安装了 CodeRocket
check_installation() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}⚠️  CodeRocket CLI 似乎未安装或已被移除${NC}"
        echo "安装目录不存在: $INSTALL_DIR"
        
        # 检查是否有残留的全局命令
        local has_global_commands=false
        for cmd in coderocket codereview-cli cr; do
            if [ -f "$GLOBAL_BIN_DIR/$cmd" ] || [ -f "$USER_BIN_DIR/$cmd" ]; then
                has_global_commands=true
                break
            fi
        done
        
        if [ "$has_global_commands" = true ]; then
            echo -e "${BLUE}但发现了残留的命令文件，继续清理...${NC}"
        else
            echo -e "${GREEN}✓ 系统中未发现 CodeRocket CLI 相关文件${NC}"
            exit 0
        fi
    fi
}

# 确认卸载
confirm_uninstall() {
    echo -e "${YELLOW}即将卸载以下内容：${NC}"
    echo ""
    
    # 显示将要删除的内容
    echo -e "${CYAN}📁 安装目录：${NC}"
    if [ -d "$INSTALL_DIR" ]; then
        echo "  ✓ $INSTALL_DIR"
    else
        echo "  - $INSTALL_DIR (不存在)"
    fi
    
    echo -e "\n${CYAN}🔧 全局命令：${NC}"
    for cmd in coderocket codereview-cli cr; do
        if [ -f "$GLOBAL_BIN_DIR/$cmd" ]; then
            echo "  ✓ $GLOBAL_BIN_DIR/$cmd"
        else
            echo "  - $GLOBAL_BIN_DIR/$cmd (不存在)"
        fi
    done
    
    echo -e "\n${CYAN}👤 用户命令：${NC}"
    for cmd in coderocket codereview-cli cr; do
        if [ -f "$USER_BIN_DIR/$cmd" ]; then
            echo "  ✓ $USER_BIN_DIR/$cmd"
        else
            echo "  - $USER_BIN_DIR/$cmd (不存在)"
        fi
    done
    
    echo -e "\n${CYAN}🔗 Git 模板：${NC}"
    if [ -d "$GIT_TEMPLATE_DIR" ]; then
        echo "  ✓ $GIT_TEMPLATE_DIR"
    else
        echo "  - $GIT_TEMPLATE_DIR (不存在)"
    fi
    
    echo -e "\n${CYAN}⚙️  Shell 配置：${NC}"
    echo "  • 将从 shell 配置文件中移除 PATH 配置"
    echo "  • 将恢复配置文件备份（如果存在）"
    
    echo ""
    echo -e "${RED}⚠️  注意：此操作不可逆！${NC}"
    echo ""
    
    read -p "确定要继续卸载吗？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}取消卸载${NC}"
        exit 0
    fi
}

# 移除安装目录
remove_install_directory() {
    echo -e "\n${BLUE}🗑️  移除安装目录...${NC}"
    
    if [ -d "$INSTALL_DIR" ]; then
        # 显示目录大小
        local dir_size=$(du -sh "$INSTALL_DIR" 2>/dev/null | cut -f1 || echo "未知")
        echo -e "${YELLOW}  目录大小: $dir_size${NC}"
        
        if rm -rf "$INSTALL_DIR"; then
            echo -e "${GREEN}  ✓ 已删除: $INSTALL_DIR${NC}"
        else
            echo -e "${RED}  ✗ 删除失败: $INSTALL_DIR${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}  - 目录不存在: $INSTALL_DIR${NC}"
    fi
}

# 移除全局命令
remove_global_commands() {
    echo -e "\n${BLUE}🔧 移除全局命令...${NC}"
    
    local removed_count=0
    local failed_count=0
    
    for cmd in coderocket codereview-cli cr; do
        local cmd_file="$GLOBAL_BIN_DIR/$cmd"
        
        if [ -f "$cmd_file" ]; then
            if [ -w "$GLOBAL_BIN_DIR" ]; then
                if rm -f "$cmd_file"; then
                    echo -e "${GREEN}  ✓ 已删除: $cmd_file${NC}"
                    removed_count=$((removed_count + 1))
                else
                    echo -e "${RED}  ✗ 删除失败: $cmd_file${NC}"
                    failed_count=$((failed_count + 1))
                fi
            else
                echo -e "${YELLOW}  需要管理员权限删除: $cmd_file${NC}"
                if sudo rm -f "$cmd_file"; then
                    echo -e "${GREEN}  ✓ 已删除: $cmd_file${NC}"
                    removed_count=$((removed_count + 1))
                else
                    echo -e "${RED}  ✗ 删除失败: $cmd_file${NC}"
                    failed_count=$((failed_count + 1))
                fi
            fi
        else
            echo -e "${YELLOW}  - 不存在: $cmd_file${NC}"
        fi
    done
    
    echo -e "${CYAN}  全局命令清理完成: 删除 $removed_count 个，失败 $failed_count 个${NC}"
}

# 移除用户命令
remove_user_commands() {
    echo -e "\n${BLUE}👤 移除用户命令...${NC}"
    
    local removed_count=0
    
    for cmd in coderocket codereview-cli cr; do
        local cmd_file="$USER_BIN_DIR/$cmd"
        
        if [ -f "$cmd_file" ]; then
            if rm -f "$cmd_file"; then
                echo -e "${GREEN}  ✓ 已删除: $cmd_file${NC}"
                removed_count=$((removed_count + 1))
            else
                echo -e "${RED}  ✗ 删除失败: $cmd_file${NC}"
            fi
        else
            echo -e "${YELLOW}  - 不存在: $cmd_file${NC}"
        fi
    done
    
    # 如果用户 bin 目录为空，询问是否删除
    if [ -d "$USER_BIN_DIR" ] && [ -z "$(ls -A "$USER_BIN_DIR" 2>/dev/null)" ]; then
        echo -e "${YELLOW}  用户 bin 目录为空，是否删除？${NC}"
        read -p "  删除 $USER_BIN_DIR? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if rmdir "$USER_BIN_DIR"; then
                echo -e "${GREEN}  ✓ 已删除空目录: $USER_BIN_DIR${NC}"
            fi
        fi
    fi
    
    echo -e "${CYAN}  用户命令清理完成: 删除 $removed_count 个${NC}"
}

# 检测用户的 shell
detect_user_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$FISH_VERSION" ]; then
        echo "fish"
    else
        # 从环境变量或进程信息推断
        local shell_name=$(basename "$SHELL" 2>/dev/null || echo "bash")
        echo "$shell_name"
    fi
}

# 获取 shell 配置文件路径
get_shell_config_file() {
    local shell_name="$1"
    local config_file=""

    case "$shell_name" in
        "bash")
            config_file="$HOME/.bashrc"
            # 在 macOS 上，bash 通常使用 .bash_profile
            if [[ "$OSTYPE" == "darwin"* ]] && [ -f "$HOME/.bash_profile" ]; then
                config_file="$HOME/.bash_profile"
            fi
            ;;
        "zsh")
            config_file="$HOME/.zshrc"
            ;;
        "fish")
            config_file="$HOME/.config/fish/config.fish"
            ;;
        *)
            # 默认使用 bash 配置
            config_file="$HOME/.bashrc"
            ;;
    esac

    echo "$config_file"
}

# 清理 shell 配置
clean_shell_config() {
    echo -e "\n${BLUE}⚙️  清理 shell 配置...${NC}"

    local user_shell=$(detect_user_shell)
    local rc_file=$(get_shell_config_file "$user_shell")

    echo -e "${YELLOW}  检测到 shell: $user_shell${NC}"
    echo -e "${YELLOW}  配置文件: $rc_file${NC}"

    if [ ! -f "$rc_file" ]; then
        echo -e "${YELLOW}  - 配置文件不存在${NC}"
        return 0
    fi

    # 检查是否有 CodeRocket 相关配置
    if ! grep -q "CodeRocket\|\.local/bin" "$rc_file" 2>/dev/null; then
        echo -e "${YELLOW}  - 未发现 CodeRocket 相关配置${NC}"
        return 0
    fi

    # 创建备份
    local backup_file="${rc_file}.backup.uninstall.$(date +%Y%m%d_%H%M%S)"
    if cp "$rc_file" "$backup_file"; then
        echo -e "${GREEN}  ✓ 已备份配置文件: $backup_file${NC}"
    else
        echo -e "${RED}  ✗ 备份配置文件失败${NC}"
        return 1
    fi

    # 移除 CodeRocket 相关配置
    local temp_file=$(mktemp)
    local removed_lines=0

    # 使用 awk 移除 CodeRocket 相关行
    awk '
    BEGIN { in_coderocket_block = 0 }
    /# CodeRocket PATH 配置/ { in_coderocket_block = 1; next }
    /export PATH=.*\.local\/bin/ && in_coderocket_block { in_coderocket_block = 0; next }
    /set -gx PATH.*\.local\/bin/ && in_coderocket_block { in_coderocket_block = 0; next }
    !in_coderocket_block { print }
    ' "$rc_file" > "$temp_file"

    # 计算移除的行数
    local original_lines=$(wc -l < "$rc_file")
    local new_lines=$(wc -l < "$temp_file")
    removed_lines=$((original_lines - new_lines))

    if [ $removed_lines -gt 0 ]; then
        if mv "$temp_file" "$rc_file"; then
            echo -e "${GREEN}  ✓ 已移除 $removed_lines 行 CodeRocket 配置${NC}"
        else
            echo -e "${RED}  ✗ 更新配置文件失败${NC}"
            rm -f "$temp_file"
            return 1
        fi
    else
        echo -e "${YELLOW}  - 未发现需要移除的配置${NC}"
        rm -f "$temp_file"
    fi

    # 检查是否有安装时的备份文件需要恢复
    local install_backup_pattern="${rc_file}.backup.[0-9]*_[0-9]*"
    local latest_backup=""

    for backup in $install_backup_pattern; do
        if [ -f "$backup" ]; then
            latest_backup="$backup"
        fi
    done

    if [ -n "$latest_backup" ]; then
        echo -e "${YELLOW}  发现安装时的备份文件: $latest_backup${NC}"
        read -p "  是否恢复到安装前的配置？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if cp "$latest_backup" "$rc_file"; then
                echo -e "${GREEN}  ✓ 已恢复到安装前的配置${NC}"
                # 清理安装时的备份文件
                rm -f $install_backup_pattern
                echo -e "${GREEN}  ✓ 已清理安装时的备份文件${NC}"
            else
                echo -e "${RED}  ✗ 恢复配置失败${NC}"
            fi
        fi
    fi
}

# 移除 Git 模板
remove_git_templates() {
    echo -e "\n${BLUE}🔗 移除 Git 模板...${NC}"

    if [ -d "$GIT_TEMPLATE_DIR" ]; then
        # 检查是否只包含 CodeRocket 相关内容
        local has_other_content=false

        # 检查 hooks 目录
        if [ -d "$GIT_TEMPLATE_DIR/hooks" ]; then
            for hook in "$GIT_TEMPLATE_DIR/hooks"/*; do
                if [ -f "$hook" ] && ! grep -q "CodeRocket\|coderocket" "$hook" 2>/dev/null; then
                    has_other_content=true
                    break
                fi
            done
        fi

        # 检查其他文件
        for item in "$GIT_TEMPLATE_DIR"/*; do
            if [ -f "$item" ] || ([ -d "$item" ] && [ "$(basename "$item")" != "hooks" ]); then
                has_other_content=true
                break
            fi
        done

        if [ "$has_other_content" = true ]; then
            echo -e "${YELLOW}  Git 模板目录包含其他内容，只删除 CodeRocket 相关文件${NC}"

            # 只删除 CodeRocket 相关的 hooks
            local removed_hooks=0
            if [ -d "$GIT_TEMPLATE_DIR/hooks" ]; then
                for hook in "$GIT_TEMPLATE_DIR/hooks"/*; do
                    if [ -f "$hook" ] && grep -q "CodeRocket\|coderocket" "$hook" 2>/dev/null; then
                        if rm -f "$hook"; then
                            echo -e "${GREEN}    ✓ 已删除: $(basename "$hook")${NC}"
                            removed_hooks=$((removed_hooks + 1))
                        fi
                    fi
                done
            fi

            echo -e "${CYAN}  删除了 $removed_hooks 个 CodeRocket hooks${NC}"
        else
            echo -e "${YELLOW}  Git 模板目录只包含 CodeRocket 内容，删除整个目录${NC}"
            if rm -rf "$GIT_TEMPLATE_DIR"; then
                echo -e "${GREEN}  ✓ 已删除: $GIT_TEMPLATE_DIR${NC}"
            else
                echo -e "${RED}  ✗ 删除失败: $GIT_TEMPLATE_DIR${NC}"
            fi
        fi

        # 检查并移除全局 Git 配置
        local git_template_config=$(git config --global init.templatedir 2>/dev/null || echo "")
        if [ "$git_template_config" = "$GIT_TEMPLATE_DIR" ]; then
            echo -e "${YELLOW}  移除全局 Git 模板配置${NC}"
            if git config --global --unset init.templatedir; then
                echo -e "${GREEN}  ✓ 已移除 Git 全局模板配置${NC}"
            else
                echo -e "${RED}  ✗ 移除 Git 全局模板配置失败${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}  - Git 模板目录不存在${NC}"
    fi
}

# 备份项目hooks
backup_project_hooks() {
    local project_dir="$1"
    local hooks_dir="$project_dir/.git/hooks"
    local backup_dir="$project_dir/.git/hooks.backup.coderocket.$(date +%Y%m%d_%H%M%S)"

    if [ ! -d "$hooks_dir" ]; then
        return 1
    fi

    # 只备份包含 CodeRocket 的 hooks
    local has_coderocket_hooks=false
    for hook in "$hooks_dir"/*; do
        if [ -f "$hook" ] && grep -q "CodeRocket\|coderocket" "$hook" 2>/dev/null; then
            has_coderocket_hooks=true
            break
        fi
    done

    if [ "$has_coderocket_hooks" = false ]; then
        return 1
    fi

    # 创建备份目录
    if mkdir -p "$backup_dir" 2>/dev/null; then
        # 复制所有 hooks（保持权限）
        for hook in "$hooks_dir"/*; do
            if [ -f "$hook" ]; then
                cp -p "$hook" "$backup_dir/" 2>/dev/null || true
            fi
        done
        echo "$backup_dir"
        return 0
    else
        return 1
    fi
}

# 扫描并清理项目 hooks（增强版）
clean_project_hooks() {
    echo -e "\n${BLUE}🔍 扫描项目 Git hooks...${NC}"

    # 询问是否扫描项目 hooks
    echo -e "${YELLOW}是否扫描并清理项目中的 CodeRocket Git hooks？${NC}"
    echo "这将搜索项目目录并移除 CodeRocket 相关的 hooks"
    echo ""
    echo -e "${CYAN}可选操作模式：${NC}"
    echo "  1) 自动搜索常见目录"
    echo "  2) 手动指定项目路径"
    echo "  3) 跳过项目 hooks 清理"
    echo ""
    read -p "请选择操作模式 (1/2/3): " -n 1 -r
    echo

    case $REPLY in
        1)
            echo -e "${BLUE}选择：自动搜索模式${NC}"
            clean_project_hooks_auto
            ;;
        2)
            echo -e "${BLUE}选择：手动指定模式${NC}"
            clean_project_hooks_manual
            ;;
        3|*)
            echo -e "${BLUE}跳过项目 hooks 清理${NC}"
            return 0
            ;;
    esac
}

# 自动搜索并清理项目hooks
clean_project_hooks_auto() {
    echo -e "${YELLOW}  自动搜索项目目录...${NC}"

    # 扩展的搜索目录列表
    local search_dirs=(
        "$HOME/Projects"
        "$HOME/projects"
        "$HOME/workspace"
        "$HOME/work"
        "$HOME/code"
        "$HOME/src"
        "$HOME/git"
        "$HOME/repos"
        "$HOME/Documents/Projects"
        "$HOME/Documents/projects"
        "$HOME/Desktop"
        "$HOME/Downloads"
        "/Users/Shared"
        "$(pwd)"  # 当前目录
    )

    # 允许用户添加自定义搜索目录
    echo ""
    echo -e "${CYAN}是否添加自定义搜索目录？${NC}"
    read -p "输入额外的搜索路径（回车跳过）: " custom_dir
    if [ -n "$custom_dir" ] && [ -d "$custom_dir" ]; then
        search_dirs+=("$custom_dir")
        echo -e "${GREEN}  ✓ 已添加: $custom_dir${NC}"
    fi

    local found_projects=()
    local search_errors=()
    local total_searched=0

    echo -e "\n${YELLOW}  开始搜索项目...${NC}"

    for search_dir in "${search_dirs[@]}"; do
        if [ -d "$search_dir" ]; then
            echo -e "${CYAN}    搜索: $search_dir${NC}"

            # 使用 timeout 防止搜索时间过长
            local search_timeout=30  # 30秒超时

            # 查找 Git 仓库（限制深度避免搜索太久）
            while IFS= read -r -d '' git_dir; do
                local project_dir=$(dirname "$git_dir")
                local hooks_dir="$git_dir/hooks"
                total_searched=$((total_searched + 1))

                # 显示搜索进度（每10个项目显示一次）
                if [ $((total_searched % 10)) -eq 0 ]; then
                    echo -e "${CYAN}      已搜索 $total_searched 个仓库...${NC}"
                fi

                # 检查是否有 CodeRocket hooks
                local has_coderocket_hooks=false
                if [ -d "$hooks_dir" ]; then
                    for hook in "$hooks_dir"/*; do
                        if [ -f "$hook" ] && grep -q "CodeRocket\|coderocket" "$hook" 2>/dev/null; then
                            has_coderocket_hooks=true
                            break
                        fi
                    done
                fi

                if [ "$has_coderocket_hooks" = true ]; then
                    found_projects+=("$project_dir")
                    echo -e "${GREEN}      ✓ 发现: $(basename "$project_dir")${NC}"
                fi

            done < <(timeout $search_timeout find "$search_dir" -maxdepth 3 -name ".git" -type d -print0 2>/dev/null || echo "")

            # 检查搜索是否超时
            if [ $? -eq 124 ]; then
                search_errors+=("$search_dir (搜索超时)")
                echo -e "${YELLOW}      ⚠️ 搜索超时: $search_dir${NC}"
            fi
        else
            echo -e "${YELLOW}    跳过不存在的目录: $search_dir${NC}"
        fi
    done

    echo -e "${CYAN}  搜索完成: 检查了 $total_searched 个 Git 仓库${NC}"

    # 显示搜索错误（如果有）
    if [ ${#search_errors[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}⚠️ 搜索警告：${NC}"
        for error in "${search_errors[@]}"; do
            echo "  • $error"
        done
    fi

    if [ ${#found_projects[@]} -eq 0 ]; then
        echo -e "${GREEN}  ✓ 未发现包含 CodeRocket hooks 的项目${NC}"
        return 0
    fi

    # 显示发现的项目
    echo -e "\n${YELLOW}📋 发现 ${#found_projects[@]} 个包含 CodeRocket hooks 的项目：${NC}"
    for i in "${!found_projects[@]}"; do
        local project="${found_projects[$i]}"
        local project_name=$(basename "$project")
        local hooks_count=$(find "$project/.git/hooks" -type f -exec grep -l "CodeRocket\|coderocket" {} \; 2>/dev/null | wc -l)
        echo "  $((i+1)). $project_name ($hooks_count 个 hooks) - $project"
    done

    # 提供清理选项
    echo ""
    echo -e "${CYAN}清理选项：${NC}"
    echo "  1) 全部清理（推荐）"
    echo "  2) 逐个选择清理"
    echo "  3) 备份后清理"
    echo "  4) 跳过清理"
    echo ""
    read -p "请选择清理方式 (1/2/3/4): " -n 1 -r
    echo

    case $REPLY in
        1)
            echo -e "${BLUE}选择：全部清理${NC}"
            process_projects_batch "${found_projects[@]}"
            ;;
        2)
            echo -e "${BLUE}选择：逐个选择清理${NC}"
            process_projects_selective "${found_projects[@]}"
            ;;
        3)
            echo -e "${BLUE}选择：备份后清理${NC}"
            process_projects_with_backup "${found_projects[@]}"
            ;;
        4|*)
            echo -e "${BLUE}跳过项目 hooks 清理${NC}"
            return 0
            ;;
    esac
}

# 批量处理项目hooks
process_projects_batch() {
    local projects=("$@")
    local cleaned_projects=0
    local failed_projects=0

    echo -e "\n${BLUE}🚀 开始批量清理 ${#projects[@]} 个项目...${NC}"

    for i in "${!projects[@]}"; do
        local project="${projects[$i]}"
        local project_name=$(basename "$project")
        local progress=$((i + 1))

        echo -e "\n${CYAN}[$progress/${#projects[@]}] 清理项目: $project_name${NC}"

        if clean_single_project "$project"; then
            cleaned_projects=$((cleaned_projects + 1))
        else
            failed_projects=$((failed_projects + 1))
            echo -e "${RED}    ✗ 清理失败${NC}"
        fi
    done

    echo -e "\n${GREEN}📊 批量清理完成：${NC}"
    echo "  • ✅ 成功清理: $cleaned_projects 个项目"
    echo "  • ❌ 清理失败: $failed_projects 个项目"
}

# 选择性处理项目hooks
process_projects_selective() {
    local projects=("$@")
    local cleaned_projects=0
    local skipped_projects=0

    echo -e "\n${BLUE}🎯 逐个选择清理模式${NC}"

    for i in "${!projects[@]}"; do
        local project="${projects[$i]}"
        local project_name=$(basename "$project")
        local hooks_count=$(find "$project/.git/hooks" -type f -exec grep -l "CodeRocket\|coderocket" {} \; 2>/dev/null | wc -l)

        echo -e "\n${YELLOW}项目 $((i+1))/${#projects[@]}: $project_name${NC}"
        echo "  路径: $project"
        echo "  CodeRocket hooks: $hooks_count 个"

        # 显示具体的hooks
        echo "  包含的 hooks:"
        find "$project/.git/hooks" -type f -exec grep -l "CodeRocket\|coderocket" {} \; 2>/dev/null | while read hook; do
            echo "    • $(basename "$hook")"
        done

        echo ""
        read -p "  是否清理此项目的 hooks？(y/N/q): " -n 1 -r
        echo

        case $REPLY in
            [Yy])
                if clean_single_project "$project"; then
                    cleaned_projects=$((cleaned_projects + 1))
                else
                    echo -e "${RED}    ✗ 清理失败${NC}"
                fi
                ;;
            [Qq])
                echo -e "${BLUE}    用户退出选择模式${NC}"
                break
                ;;
            *)
                echo -e "${BLUE}    跳过此项目${NC}"
                skipped_projects=$((skipped_projects + 1))
                ;;
        esac
    done

    echo -e "\n${GREEN}📊 选择性清理完成：${NC}"
    echo "  • ✅ 清理项目: $cleaned_projects 个"
    echo "  • ⏭️ 跳过项目: $skipped_projects 个"
}

# 备份后处理项目hooks
process_projects_with_backup() {
    local projects=("$@")
    local cleaned_projects=0
    local backup_failed=0

    echo -e "\n${BLUE}💾 备份后清理模式${NC}"
    echo -e "${YELLOW}将为每个项目创建 hooks 备份${NC}"

    for i in "${!projects[@]}"; do
        local project="${projects[$i]}"
        local project_name=$(basename "$project")
        local progress=$((i + 1))

        echo -e "\n${CYAN}[$progress/${#projects[@]}] 处理项目: $project_name${NC}"

        # 创建备份
        local backup_dir=$(backup_project_hooks "$project")
        if [ $? -eq 0 ] && [ -n "$backup_dir" ]; then
            echo -e "${GREEN}    ✓ 备份创建: $backup_dir${NC}"

            # 清理hooks
            if clean_single_project "$project"; then
                cleaned_projects=$((cleaned_projects + 1))
                echo -e "${GREEN}    ✓ 清理完成，备份已保存${NC}"
            else
                echo -e "${RED}    ✗ 清理失败，但备份已保存${NC}"
            fi
        else
            echo -e "${RED}    ✗ 备份失败，跳过清理${NC}"
            backup_failed=$((backup_failed + 1))
        fi
    done

    echo -e "\n${GREEN}📊 备份清理完成：${NC}"
    echo "  • ✅ 成功处理: $cleaned_projects 个项目"
    echo "  • ❌ 备份失败: $backup_failed 个项目"
    echo -e "\n${CYAN}💡 提示：备份文件位于各项目的 .git/hooks.backup.coderocket.* 目录${NC}"
}

# 清理单个项目的hooks
clean_single_project() {
    local project="$1"
    local hooks_dir="$project/.git/hooks"
    local project_name=$(basename "$project")
    local removed_hooks=0
    local failed_hooks=0

    if [ ! -d "$hooks_dir" ]; then
        echo -e "${YELLOW}    ⚠️ hooks 目录不存在${NC}"
        return 1
    fi

    # 清理 CodeRocket hooks
    for hook in "$hooks_dir"/*; do
        if [ -f "$hook" ] && grep -q "CodeRocket\|coderocket" "$hook" 2>/dev/null; then
            local hook_name=$(basename "$hook")

            # 尝试删除hook
            if rm -f "$hook" 2>/dev/null; then
                echo -e "${GREEN}      ✓ 删除 hook: $hook_name${NC}"
                removed_hooks=$((removed_hooks + 1))
            else
                echo -e "${RED}      ✗ 删除失败: $hook_name (权限不足?)${NC}"
                failed_hooks=$((failed_hooks + 1))
            fi
        fi
    done

    # 检查是否还有其他 CodeRocket 相关文件
    local coderocket_files=$(find "$hooks_dir" -name "*coderocket*" -o -name "*CodeRocket*" 2>/dev/null | wc -l)
    if [ $coderocket_files -gt 0 ]; then
        echo -e "${YELLOW}      ⚠️ 发现 $coderocket_files 个其他 CodeRocket 相关文件${NC}"
        find "$hooks_dir" -name "*coderocket*" -o -name "*CodeRocket*" 2>/dev/null | while read file; do
            echo "        • $(basename "$file")"
        done
    fi

    if [ $removed_hooks -gt 0 ]; then
        echo -e "${GREEN}    ✅ 清理完成: 删除 $removed_hooks 个 hooks${NC}"
        if [ $failed_hooks -gt 0 ]; then
            echo -e "${YELLOW}    ⚠️ 部分失败: $failed_hooks 个 hooks 删除失败${NC}"
        fi
        return 0
    elif [ $failed_hooks -gt 0 ]; then
        echo -e "${RED}    ❌ 清理失败: $failed_hooks 个 hooks 无法删除${NC}"
        return 1
    else
        echo -e "${YELLOW}    ℹ️ 未发现需要清理的 hooks${NC}"
        return 0
    fi
}

# 手动指定项目路径模式
clean_project_hooks_manual() {
    echo -e "${YELLOW}  手动指定项目路径模式${NC}"
    echo "请输入要清理的项目路径（支持多个路径，用空格分隔）"
    echo ""

    local manual_projects=()

    while true; do
        read -p "项目路径（回车完成输入）: " project_path

        if [ -z "$project_path" ]; then
            break
        fi

        # 展开路径（支持 ~ 和相对路径）
        project_path=$(eval echo "$project_path")

        if [ ! -d "$project_path" ]; then
            echo -e "${RED}  ✗ 目录不存在: $project_path${NC}"
            continue
        fi

        if [ ! -d "$project_path/.git" ]; then
            echo -e "${RED}  ✗ 不是 Git 仓库: $project_path${NC}"
            continue
        fi

        # 检查是否有 CodeRocket hooks
        local has_coderocket_hooks=false
        if [ -d "$project_path/.git/hooks" ]; then
            for hook in "$project_path/.git/hooks"/*; do
                if [ -f "$hook" ] && grep -q "CodeRocket\|coderocket" "$hook" 2>/dev/null; then
                    has_coderocket_hooks=true
                    break
                fi
            done
        fi

        if [ "$has_coderocket_hooks" = false ]; then
            echo -e "${YELLOW}  ⚠️ 未发现 CodeRocket hooks: $project_path${NC}"
            read -p "  是否仍要添加到清理列表？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                continue
            fi
        fi

        manual_projects+=("$project_path")
        echo -e "${GREEN}  ✓ 已添加: $(basename "$project_path")${NC}"
    done

    if [ ${#manual_projects[@]} -eq 0 ]; then
        echo -e "${BLUE}未指定任何项目，跳过清理${NC}"
        return 0
    fi

    echo -e "\n${YELLOW}📋 将清理以下 ${#manual_projects[@]} 个项目：${NC}"
    for i in "${!manual_projects[@]}"; do
        local project="${manual_projects[$i]}"
        echo "  $((i+1)). $(basename "$project") - $project"
    done

    echo ""
    read -p "确认清理这些项目？(y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        process_projects_batch "${manual_projects[@]}"
    else
        echo -e "${BLUE}取消清理${NC}"
    fi
}

# 清理其他残留文件
clean_other_files() {
    echo -e "\n${BLUE}🧹 清理其他残留文件...${NC}"

    local cleaned_files=0

    # 清理可能的日志文件
    local log_dirs=(
        "$HOME/.cache/coderocket"
        "$HOME/.local/share/coderocket"
        "/tmp/coderocket*"
    )

    for log_pattern in "${log_dirs[@]}"; do
        for log_path in $log_pattern; do
            if [ -e "$log_path" ]; then
                if rm -rf "$log_path"; then
                    echo -e "${GREEN}  ✓ 已删除: $log_path${NC}"
                    cleaned_files=$((cleaned_files + 1))
                else
                    echo -e "${RED}  ✗ 删除失败: $log_path${NC}"
                fi
            fi
        done
    done

    # 清理可能的配置文件
    local config_files=(
        "$HOME/.codereview-cli"  # 旧版本兼容
    )

    for config_file in "${config_files[@]}"; do
        if [ -e "$config_file" ]; then
            echo -e "${YELLOW}  发现旧版本配置: $config_file${NC}"
            read -p "  是否删除？(y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if rm -rf "$config_file"; then
                    echo -e "${GREEN}  ✓ 已删除: $config_file${NC}"
                    cleaned_files=$((cleaned_files + 1))
                fi
            fi
        fi
    done

    if [ $cleaned_files -eq 0 ]; then
        echo -e "${YELLOW}  - 未发现其他残留文件${NC}"
    else
        echo -e "${CYAN}  清理完成: 删除 $cleaned_files 个文件/目录${NC}"
    fi
}

# 显示卸载完成信息
show_completion_message() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 卸载完成！                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BLUE}📋 卸载摘要：${NC}"
    echo "• ✅ 移除了安装目录和所有文件"
    echo "• ✅ 清理了全局和用户命令"
    echo "• ✅ 恢复了 shell 配置文件"
    echo "• ✅ 移除了 Git 模板和 hooks"
    echo "• ✅ 清理了残留文件"
    echo ""

    echo -e "${YELLOW}📝 注意事项：${NC}"
    echo "• 请重新打开终端或运行 'source ~/.zshrc' (或 ~/.bashrc) 使配置生效"
    echo "• 如果有其他项目仍在使用 CodeRocket hooks，请手动清理"
    echo "• 配置文件备份已保存，如需恢复可手动操作"
    echo ""

    echo -e "${CYAN}🔗 相关链接：${NC}"
    echo "• 项目主页: https://github.com/im47cn/coderocket-cli"
    echo "• 重新安装: curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash"
    echo ""

    echo -e "${GREEN}感谢使用 CodeRocket CLI！${NC}"
}

# 主函数
main() {
    show_uninstall_banner

    # 检查安装状态
    check_installation

    # 确认卸载
    confirm_uninstall

    echo -e "\n${BLUE}🚀 开始卸载 CodeRocket CLI...${NC}"

    # 执行卸载步骤
    remove_install_directory
    remove_global_commands
    remove_user_commands
    clean_shell_config
    remove_git_templates
    clean_project_hooks
    clean_other_files

    # 显示完成信息
    show_completion_message
}

# 错误处理
trap 'echo -e "${RED}卸载过程中发生错误${NC}"; exit 1' ERR

# 只在直接执行时运行主逻辑（不是被 source 时）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 检查参数
    case "${1:-}" in
        "--help"|"-h")
            echo "CodeRocket CLI 卸载脚本 v2.0"
            echo ""
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --help, -h     显示此帮助信息"
            echo "  --force        强制卸载，不询问确认"
            echo ""
            echo "此脚本将完全移除 CodeRocket CLI 及其所有组件，包括："
            echo "• 安装目录 (~/.coderocket)"
            echo "• 全局和用户命令"
            echo "• Shell 配置中的 PATH 设置"
            echo "• Git 模板和 hooks"
            echo "• 残留的配置和日志文件"
            echo ""
            echo "项目 hooks 清理功能："
            echo "• 🔍 智能搜索：自动扫描常见项目目录"
            echo "• 📝 手动指定：支持手动输入项目路径"
            echo "• 🎯 选择清理：逐个项目确认清理"
            echo "• 💾 备份保护：清理前自动备份 hooks"
            echo "• ⚠️ 异常处理：完善的错误处理和恢复机制"
            echo ""
            echo "安全特性："
            echo "• 配置文件自动备份和恢复"
            echo "• 详细的卸载预览和确认"
            echo "• 智能识别，避免误删其他内容"
            echo "• 支持部分失败后的手动清理"
            exit 0
            ;;
        "--force")
            # 跳过确认，直接卸载
            show_uninstall_banner
            check_installation
            echo -e "\n${YELLOW}强制卸载模式，跳过确认...${NC}"
            echo -e "\n${BLUE}🚀 开始卸载 CodeRocket CLI...${NC}"
            remove_install_directory
            remove_global_commands
            remove_user_commands
            clean_shell_config
            remove_git_templates
            clean_project_hooks
            clean_other_files
            show_completion_message
            ;;
        "")
            # 正常卸载流程
            main
            ;;
        *)
            echo -e "${RED}错误：未知参数 '$1'${NC}"
            echo "使用 '$0 --help' 查看帮助信息"
            exit 1
            ;;
    esac
fi
