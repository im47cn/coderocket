#!/bin/bash

# CodeRocket Banner Display
# 显示项目 banner 和版本信息，参考 Gemini CLI 的精美设计

# 基础颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# 渐变色定义（模仿 Gemini CLI 的蓝绿渐变，使用 256 色）
GRAD_1='\033[38;5;39m'   # 亮蓝色
GRAD_2='\033[38;5;45m'   # 青蓝色
GRAD_3='\033[38;5;51m'   # 青色
GRAD_4='\033[38;5;87m'   # 浅青色
GRAD_5='\033[38;5;123m'  # 浅蓝绿色
GRAD_6='\033[38;5;159m'  # 很浅的青色

# 获取终端宽度
get_terminal_width() {
    tput cols 2>/dev/null || echo 80
}

# 获取版本信息
get_version() {
    if [ -f "$HOME/.coderocket/VERSION" ]; then
        cat "$HOME/.coderocket/VERSION" | tr -d '\n'
    elif [ -f "./VERSION" ]; then
        cat "./VERSION" | tr -d '\n'
    else
        echo "1.0.2"
    fi
}

# 精美的 CodeRocket ASCII Art（类似 Gemini 的像素风格）
show_banner() {
    local width=$(get_terminal_width)

    # 根据终端宽度选择不同的 banner
    if [ "$width" -ge 100 ]; then
        show_long_banner
    else
        show_short_banner
    fi
}

# 长版本 Banner（宽终端使用）
show_long_banner() {
    echo ""
    echo -e "${GRAD_1} ███            ██████  ██████  ██████  ███████ ██████   ██████   ██████ ██   ██ ███████ ████████ ${NC}"
    echo -e "${GRAD_2}░░░███         ██      ██    ██ ██   ██ ██      ██   ██ ██    ██ ██      ██  ██  ██         ██    ${NC}"
    echo -e "${GRAD_3}  ░░░███       ██      ██    ██ ██   ██ █████   ██████  ██    ██ ██      █████   █████      ██    ${NC}"
    echo -e "${GRAD_4}    ░░░███     ██      ██    ██ ██   ██ ██      ██   ██ ██    ██ ██      ██  ██  ██         ██    ${NC}"
    echo -e "${GRAD_5}     ███░       ██████  ██████  ██████  ███████ ██   ██  ██████   ██████ ██   ██ ███████    ██    ${NC}"
    echo -e "${GRAD_6}   ███░                                                                                            ${NC}"
    echo -e "${GRAD_1} ███░                                                                                              ${NC}"
    echo -e "${GRAD_2}░░░                                                                                                ${NC}"
    echo ""

    # 版本和兼容性信息
    local version=$(get_version)
    echo -e "${GRAD_5}🚀 AI 驱动的代码审查工具${NC}"
    echo -e "${GRAY}版本: ${version}${NC}"
    echo -e "${GRAY}兼容命令: coderocket, codereview-cli, cr${NC}"
    echo ""
}

# 短版本 Banner（窄终端使用）
show_short_banner() {
    echo ""
    echo -e "${GRAD_1} ██████  ██████  ██████  ███████ ██████   ██████   ██████ ██   ██ ███████ ████████ ${NC}"
    echo -e "${GRAD_2}██      ██    ██ ██   ██ ██      ██   ██ ██    ██ ██      ██  ██  ██         ██    ${NC}"
    echo -e "${GRAD_3}██      ██    ██ ██   ██ █████   ██████  ██    ██ ██      █████   █████      ██    ${NC}"
    echo -e "${GRAD_4}██      ██    ██ ██   ██ ██      ██   ██ ██    ██ ██      ██  ██  ██         ██    ${NC}"
    echo -e "${GRAD_5} ██████  ██████  ██████  ███████ ██   ██  ██████   ██████ ██   ██ ███████    ██    ${NC}"
    echo ""

    # 版本和兼容性信息
    local version=$(get_version)
    echo -e "${GRAD_5}🚀 AI 驱动的代码审查工具${NC}"
    echo -e "${GRAY}版本: ${version}${NC}"
    echo -e "${GRAY}兼容命令: coderocket, codereview-cli, cr${NC}"
    echo ""
}

# 迷你 Banner（单行显示）
show_mini_banner() {
    echo -e "${GRAD_3}CodeRocket 🚀 - AI 驱动的代码审查工具${NC}"
}

# 启动信息显示
show_startup_info() {
    show_banner
    echo -e "${YELLOW}💡 提示：${NC}"
    echo -e "${WHITE}  • 在 Git 仓库中运行可直接进行代码审查${NC}"
    echo -e "${WHITE}  • 使用 ${BOLD}coderocket help${NC} 查看所有命令${NC}"
    echo -e "${WHITE}  • 使用 ${BOLD}coderocket config${NC} 配置 AI 服务${NC}"
    echo ""
}

# 安装 Banner
show_install_banner() {
    show_banner
    echo -e "${GRAD_5}🚀 一键安装脚本${NC}"
    echo ""
}

# 显示错误 banner
show_error_banner() {
    local error_msg="$1"
    echo -e "${RED}${BOLD}❌ CodeRocket 错误${NC}"
    echo -e "${RED}${error_msg}${NC}"
    echo ""
}

# 显示成功 banner
show_success_banner() {
    local success_msg="$1"
    echo -e "${GREEN}${BOLD}✅ CodeRocket${NC}"
    echo -e "${GREEN}${success_msg}${NC}"
    echo ""
}

# 如果直接运行此脚本
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    case "${1:-startup}" in
        "banner")
            show_banner
            ;;
        "mini")
            show_mini_banner
            ;;
        "startup")
            show_startup_info
            ;;
        "error")
            show_error_banner "$2"
            ;;
        "success")
            show_success_banner "$2"
            ;;
        "install")
            show_install_banner
            ;;
        *)
            show_startup_info
            ;;
    esac
fi
