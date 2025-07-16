#!/bin/bash

# AI Service Configuration Manager
# 管理多种AI服务的配置

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置文件路径
PROJECT_CONFIG=".ai-config"
GLOBAL_CONFIG="$HOME/.codereview-cli/ai-config"
ENV_FILE=".env"

# 支持的AI服务列表
SUPPORTED_SERVICES=("gemini" "opencode" "claudecode")

# 创建配置目录
ensure_config_dir() {
    mkdir -p "$HOME/.codereview-cli"
}

# 读取配置值
get_config_value() {
    local key=$1
    local scope=${2:-"auto"}  # auto, project, global
    local value=""
    
    case "$scope" in
        "project")
            if [ -f "$PROJECT_CONFIG" ]; then
                value=$(grep "^$key=" "$PROJECT_CONFIG" 2>/dev/null | cut -d'=' -f2-)
            fi
            ;;
        "global")
            if [ -f "$GLOBAL_CONFIG" ]; then
                value=$(grep "^$key=" "$GLOBAL_CONFIG" 2>/dev/null | cut -d'=' -f2-)
            fi
            ;;
        "auto")
            # 优先级：环境变量 > 项目配置 > 全局配置
            if [ ! -z "${!key}" ]; then
                value="${!key}"
            elif [ -f "$PROJECT_CONFIG" ]; then
                value=$(grep "^$key=" "$PROJECT_CONFIG" 2>/dev/null | cut -d'=' -f2-)
            elif [ -f "$GLOBAL_CONFIG" ]; then
                value=$(grep "^$key=" "$GLOBAL_CONFIG" 2>/dev/null | cut -d'=' -f2-)
            fi
            ;;
    esac
    
    echo "$value"
}

# 设置配置值
set_config_value() {
    local key=$1
    local value=$2
    local scope=${3:-"project"}  # project, global
    local config_file=""
    
    case "$scope" in
        "project")
            config_file="$PROJECT_CONFIG"
            ;;
        "global")
            ensure_config_dir
            config_file="$GLOBAL_CONFIG"
            ;;
        *)
            echo -e "${RED}❌ 无效的配置范围: $scope${NC}"
            return 1
            ;;
    esac
    
    # 如果配置文件不存在，创建它
    touch "$config_file"
    
    # 更新或添加配置项
    if grep -q "^$key=" "$config_file" 2>/dev/null; then
        # 更新现有配置
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^$key=.*/$key=$value/" "$config_file"
        else
            sed -i "s/^$key=.*/$key=$value/" "$config_file"
        fi
    else
        # 添加新配置
        echo "$key=$value" >> "$config_file"
    fi
    
    echo -e "${GREEN}✓ 配置已保存: $key=$value (${scope})${NC}"
}

# 显示当前配置
show_config() {
    local scope=${1:-"all"}  # all, project, global
    
    echo -e "${BLUE}=== AI服务配置 ===${NC}"
    
    if [ "$scope" = "all" ] || [ "$scope" = "project" ]; then
        echo -e "\n${YELLOW}项目配置 ($PROJECT_CONFIG):${NC}"
        if [ -f "$PROJECT_CONFIG" ]; then
            cat "$PROJECT_CONFIG" | while IFS='=' read -r key value; do
                if [ ! -z "$key" ] && [[ ! "$key" =~ ^# ]]; then
                    echo "  $key = $value"
                fi
            done
        else
            echo "  (无项目配置文件)"
        fi
    fi
    
    if [ "$scope" = "all" ] || [ "$scope" = "global" ]; then
        echo -e "\n${YELLOW}全局配置 ($GLOBAL_CONFIG):${NC}"
        if [ -f "$GLOBAL_CONFIG" ]; then
            cat "$GLOBAL_CONFIG" | while IFS='=' read -r key value; do
                if [ ! -z "$key" ] && [[ ! "$key" =~ ^# ]]; then
                    echo "  $key = $value"
                fi
            done
        else
            echo "  (无全局配置文件)"
        fi
    fi
    
    echo -e "\n${YELLOW}当前有效配置:${NC}"
    echo "  AI_SERVICE = $(get_config_value "AI_SERVICE")"
    echo "  AI_TIMEOUT = $(get_config_value "AI_TIMEOUT")"
    echo "  AI_MAX_RETRIES = $(get_config_value "AI_MAX_RETRIES")"
}

# 验证AI服务配置
validate_service_config() {
    local service=$1
    local errors=0
    
    echo -e "${BLUE}验证 $service 服务配置...${NC}"
    
    case "$service" in
        "gemini")
            local api_key=$(get_config_value "GEMINI_API_KEY")
            if [ -z "$api_key" ]; then
                echo -e "${RED}❌ 缺少 GEMINI_API_KEY${NC}"
                errors=$((errors + 1))
            fi
            ;;
        "opencode")
            local api_key=$(get_config_value "OPENCODE_API_KEY")
            local api_url=$(get_config_value "OPENCODE_API_URL")
            if [ -z "$api_key" ]; then
                echo -e "${RED}❌ 缺少 OPENCODE_API_KEY${NC}"
                errors=$((errors + 1))
            fi
            if [ -z "$api_url" ]; then
                echo -e "${RED}❌ 缺少 OPENCODE_API_URL${NC}"
                errors=$((errors + 1))
            fi
            ;;
        "claudecode")
            local api_key=$(get_config_value "CLAUDECODE_API_KEY")
            local api_url=$(get_config_value "CLAUDECODE_API_URL")
            if [ -z "$api_key" ]; then
                echo -e "${RED}❌ 缺少 CLAUDECODE_API_KEY${NC}"
                errors=$((errors + 1))
            fi
            if [ -z "$api_url" ]; then
                echo -e "${RED}❌ 缺少 CLAUDECODE_API_URL${NC}"
                errors=$((errors + 1))
            fi
            ;;
        *)
            echo -e "${RED}❌ 不支持的服务: $service${NC}"
            return 1
            ;;
    esac
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✓ $service 配置验证通过${NC}"
        return 0
    else
        echo -e "${RED}❌ $service 配置验证失败 ($errors 个错误)${NC}"
        return 1
    fi
}

# 交互式配置AI服务
configure_service_interactive() {
    local service=$1
    local scope=${2:-"project"}
    
    echo -e "${BLUE}=== 配置 $service 服务 ===${NC}"
    
    case "$service" in
        "gemini")
            read -sp "请输入 Gemini API Key: " api_key
            echo  # 换行
            if [ ! -z "$api_key" ]; then
                set_config_value "GEMINI_API_KEY" "$api_key" "$scope"
            fi
            
            read -p "请输入 Gemini Model (默认: gemini-pro): " model
            model=${model:-"gemini-pro"}
            set_config_value "GEMINI_MODEL" "$model" "$scope"
            ;;
        "opencode")
            read -sp "请输入 OpenCode API Key: " api_key
            echo  # 换行
            if [ ! -z "$api_key" ]; then
                set_config_value "OPENCODE_API_KEY" "$api_key" "$scope"
            fi
            
            read -p "请输入 OpenCode API URL (默认: https://api.opencode.com/v1): " api_url
            api_url=${api_url:-"https://api.opencode.com/v1"}
            set_config_value "OPENCODE_API_URL" "$api_url" "$scope"
            
            read -p "请输入 OpenCode Model (默认: opencode-pro): " model
            model=${model:-"opencode-pro"}
            set_config_value "OPENCODE_MODEL" "$model" "$scope"
            ;;
        "claudecode")
            read -sp "请输入 ClaudeCode API Key: " api_key
            echo  # 换行
            if [ ! -z "$api_key" ]; then
                set_config_value "CLAUDECODE_API_KEY" "$api_key" "$scope"
            fi
            
            read -p "请输入 ClaudeCode API URL (默认: https://api.claudecode.com/v1): " api_url
            api_url=${api_url:-"https://api.claudecode.com/v1"}
            set_config_value "CLAUDECODE_API_URL" "$api_url" "$scope"
            
            read -p "请输入 ClaudeCode Model (默认: claude-3-sonnet): " model
            model=${model:-"claude-3-sonnet"}
            set_config_value "CLAUDECODE_MODEL" "$model" "$scope"
            ;;
        *)
            echo -e "${RED}❌ 不支持的服务: $service${NC}"
            return 1
            ;;
    esac
    
    # 设置为当前AI服务
    set_config_value "AI_SERVICE" "$service" "$scope"
    
    echo -e "${GREEN}✓ $service 配置完成${NC}"
}

# 选择AI服务
select_ai_service() {
    local scope=${1:-"project"}
    
    echo -e "${BLUE}=== 选择AI服务 ===${NC}"
    echo "支持的AI服务："
    
    for i in "${!SUPPORTED_SERVICES[@]}"; do
        echo "  $((i+1)). ${SUPPORTED_SERVICES[$i]}"
    done
    
    read -p "请选择AI服务 (1-${#SUPPORTED_SERVICES[@]}): " choice
    
    if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#SUPPORTED_SERVICES[@]}" ]; then
        local selected_service="${SUPPORTED_SERVICES[$((choice-1))]}"
        echo -e "${GREEN}✓ 已选择: $selected_service${NC}"
        
        # 询问是否配置该服务
        read -p "是否现在配置 $selected_service 服务? (y/N): " configure_now
        if [[ "$configure_now" =~ ^[Yy]$ ]]; then
            configure_service_interactive "$selected_service" "$scope"
        else
            set_config_value "AI_SERVICE" "$selected_service" "$scope"
        fi
    else
        echo -e "${RED}❌ 无效选择${NC}"
        return 1
    fi
}

# 主函数
main() {
    case "${1:-help}" in
        "show"|"list")
            show_config "$2"
            ;;
        "set")
            if [ $# -lt 3 ]; then
                echo "用法: $0 set <key> <value> [scope]"
                return 1
            fi
            set_config_value "$2" "$3" "${4:-project}"
            ;;
        "get")
            if [ $# -lt 2 ]; then
                echo "用法: $0 get <key> [scope]"
                return 1
            fi
            get_config_value "$2" "${3:-auto}"
            ;;
        "configure")
            if [ $# -lt 2 ]; then
                echo "用法: $0 configure <service> [scope]"
                return 1
            fi
            configure_service_interactive "$2" "${3:-project}"
            ;;
        "select")
            select_ai_service "${2:-project}"
            ;;
        "validate")
            local service="${2:-$(get_config_value "AI_SERVICE")}"
            validate_service_config "$service"
            ;;
        "help"|*)
            echo "AI服务配置管理工具"
            echo ""
            echo "用法: $0 <命令> [参数...]"
            echo ""
            echo "命令:"
            echo "  show [scope]              - 显示配置 (scope: all|project|global)"
            echo "  set <key> <value> [scope] - 设置配置项"
            echo "  get <key> [scope]         - 获取配置项"
            echo "  configure <service> [scope] - 交互式配置服务"
            echo "  select [scope]            - 选择AI服务"
            echo "  validate [service]        - 验证服务配置"
            echo "  help                      - 显示帮助信息"
            echo ""
            echo "支持的服务: ${SUPPORTED_SERVICES[*]}"
            echo "配置范围: project (项目级) | global (全局)"
            ;;
    esac
}

# 如果直接执行此脚本，运行主函数
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
