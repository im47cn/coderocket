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
GLOBAL_CONFIG="$HOME/.coderocket/ai-config"
ENV_FILE=".env"

# 支持的AI服务列表
SUPPORTED_SERVICES=("gemini" "opencode" "claudecode")

# 创建配置目录
#
# 功能: 确保全局配置目录存在
# 参数: 无
# 返回: 无
# 复杂度: O(1) - 常数时间操作
# 依赖: mkdir命令
# 调用者: set_config_value(), configure_service_interactive()
ensure_config_dir() {
    mkdir -p "$HOME/.coderocket"
}

# 读取配置值
#
# 功能: 从指定范围读取配置项的值
# 参数:
#   $1 - key: 配置项的键名 (必需)
#   $2 - scope: 配置范围 (可选, 默认: "auto")
#        - "auto": 按优先级自动选择 (环境变量 > 项目配置 > 全局配置)
#        - "project": 仅从项目配置文件读取
#        - "global": 仅从全局配置文件读取
# 返回: 配置项的值 (如果不存在则返回空字符串)
# 复杂度: O(n) - n为配置文件行数
# 依赖: grep, cut命令
# 调用者: show_config(), validate_service_config(), main()
# 示例:
#   get_config_value "AI_SERVICE"           # 自动查找
#   get_config_value "API_KEY" "project"    # 仅项目配置
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
                value="${!key}"  # 间接变量引用，获取环境变量值
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
#
# 功能: 在指定范围设置配置项的值
# 参数:
#   $1 - key: 配置项的键名 (必需)
#   $2 - value: 配置项的值 (必需)
#   $3 - scope: 配置范围 (可选, 默认: "project")
#        - "project": 保存到项目配置文件
#        - "global": 保存到全局配置文件
# 返回: 0=成功, 1=失败
# 复杂度: O(n) - n为配置文件行数 (sed操作)
# 依赖: touch, grep, sed命令, ensure_config_dir()
# 调用者: configure_service_interactive(), select_ai_service(), main()
# 示例:
#   set_config_value "AI_SERVICE" "gemini" "project"
#   set_config_value "API_KEY" "xxx" "global"
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
            ensure_config_dir  # 确保全局配置目录存在
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
        # 更新现有配置 - 跨平台sed兼容性处理
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^$key=.*/$key=$value/" "$config_file"  # macOS
        else
            sed -i "s/^$key=.*/$key=$value/" "$config_file"     # Linux
        fi
    else
        # 添加新配置项到文件末尾
        echo "$key=$value" >> "$config_file"
    fi

    echo -e "${GREEN}✓ 配置已保存: $key=$value (${scope})${NC}"
}

# 显示当前配置
#
# 功能: 显示指定范围的配置信息
# 参数:
#   $1 - scope: 显示范围 (可选, 默认: "all")
#        - "all": 显示所有配置 (项目+全局+当前有效)
#        - "project": 仅显示项目配置
#        - "global": 仅显示全局配置
# 返回: 无
# 复杂度: O(n) - n为配置文件总行数
# 依赖: cat, get_config_value()
# 调用者: main()
# 示例:
#   show_config              # 显示所有配置
#   show_config "project"    # 仅显示项目配置
show_config() {
    local scope=${1:-"all"}  # all, project, global
    
    echo -e "${BLUE}=== AI服务配置 ===${NC}"
    
    if [ "$scope" = "all" ] || [ "$scope" = "project" ]; then
        echo -e "\n${YELLOW}项目配置 ($PROJECT_CONFIG):${NC}"
        if [ -f "$PROJECT_CONFIG" ]; then
            # 逐行读取配置文件，跳过注释和空行
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
            # 逐行读取全局配置文件，跳过注释和空行
            cat "$GLOBAL_CONFIG" | while IFS='=' read -r key value; do
                if [ ! -z "$key" ] && [[ ! "$key" =~ ^# ]]; then
                    echo "  $key = $value"
                fi
            done
        else
            echo "  (无全局配置文件)"
        fi
    fi
    
    # 显示当前有效配置 (按优先级解析后的最终值)
    echo -e "\n${YELLOW}当前有效配置:${NC}"
    echo "  AI_SERVICE = $(get_config_value "AI_SERVICE")"
    echo "  REVIEW_TIMING = $(get_config_value "REVIEW_TIMING")"
    echo "  AI_TIMEOUT = $(get_config_value "AI_TIMEOUT")"
    echo "  AI_MAX_RETRIES = $(get_config_value "AI_MAX_RETRIES")"
}

# 验证AI服务配置
#
# 功能: 验证指定AI服务的配置完整性
# 参数:
#   $1 - service: AI服务名称 (必需)
#        支持: "gemini", "opencode", "claudecode"
# 返回: 0=验证通过, 1=验证失败或不支持的服务
# 复杂度: O(1) - 常数时间检查
# 依赖: get_config_value()
# 调用者: main()
# 验证规则:
#   - gemini: 需要 GEMINI_API_KEY
#   - opencode: 需要 OPENCODE_API_KEY, OPENCODE_API_URL
#   - claudecode: 需要 CLAUDECODE_API_KEY, CLAUDECODE_API_URL
# 示例:
#   validate_service_config "gemini"
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
#
# 功能: 通过交互式界面配置指定的AI服务
# 参数:
#   $1 - service: AI服务名称 (必需)
#        支持: "gemini", "opencode", "claudecode"
#   $2 - scope: 配置范围 (可选, 默认: "project")
#        - "project": 保存到项目配置
#        - "global": 保存到全局配置
# 返回: 0=配置成功, 1=不支持的服务
# 复杂度: O(1) - 用户交互时间
# 依赖: read命令, set_config_value()
# 调用者: select_ai_service(), main()
# 安全性: 使用read -sp隐藏API密钥输入
# 示例:
#   configure_service_interactive "gemini" "project"
configure_service_interactive() {
    local service=$1
    local scope=${2:-"project"}
    
    echo -e "${BLUE}=== 配置 $service 服务 ===${NC}"
    
    case "$service" in
        "gemini")
            # 安全输入API密钥 (隐藏输入)
            read -sp "请输入 Gemini API Key: " api_key
            echo  # 换行
            if [ ! -z "$api_key" ]; then
                set_config_value "GEMINI_API_KEY" "$api_key" "$scope"
            fi

            # 配置模型 (提供默认值)
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
#
# 功能: 通过交互式菜单选择AI服务
# 参数:
#   $1 - scope: 配置范围 (可选, 默认: "project")
#        - "project": 保存到项目配置
#        - "global": 保存到全局配置
# 返回: 0=选择成功, 1=无效选择
# 复杂度: O(1) - 用户交互时间
# 依赖: read命令, configure_service_interactive(), set_config_value()
# 调用者: main()
# 流程: 显示菜单 -> 用户选择 -> 可选配置 -> 保存选择
# 示例:
#   select_ai_service "project"
select_ai_service() {
    local scope=${1:-"project"}
    
    echo -e "${BLUE}=== 选择AI服务 ===${NC}"
    echo "支持的AI服务："
    
    # 显示支持的AI服务列表 (数组索引转换为用户友好的编号)
    for i in "${!SUPPORTED_SERVICES[@]}"; do
        echo "  $((i+1)). ${SUPPORTED_SERVICES[$i]}"
    done
    
    read -p "请选择AI服务 (1-${#SUPPORTED_SERVICES[@]}): " choice
    
    # 验证用户输入 (正整数且在有效范围内)
    if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#SUPPORTED_SERVICES[@]}" ]; then
        local selected_service="${SUPPORTED_SERVICES[$((choice-1))]}"  # 转换为数组索引
        echo -e "${GREEN}✓ 已选择: $selected_service${NC}"

        # 询问是否立即配置该服务
        read -p "是否现在配置 $selected_service 服务? (y/N): " configure_now
        if [[ "$configure_now" =~ ^[Yy]$ ]]; then
            configure_service_interactive "$selected_service" "$scope"
        else
            # 仅保存服务选择，不进行详细配置
            set_config_value "AI_SERVICE" "$selected_service" "$scope"
        fi
    else
        echo -e "${RED}❌ 无效选择${NC}"
        return 1
    fi
}

# 选择代码审查时机
#
# 功能: 通过交互式菜单选择代码审查时机
# 参数:
#   $1 - scope: 配置范围 (可选, 默认: "project")
#        - "project": 保存到项目配置
#        - "global": 保存到全局配置
# 返回: 0=选择成功, 1=无效选择
# 复杂度: O(1) - 用户交互时间
# 依赖: read命令, set_config_value()
# 调用者: main()
# 流程: 显示菜单 -> 用户选择 -> 保存选择
# 示例:
#   select_review_timing "project"
select_review_timing() {
    local scope=${1:-"project"}

    echo -e "${BLUE}=== 选择代码审查时机 ===${NC}"
    echo "支持的审查时机："
    echo "  1. pre-commit  - 提交前审查（可阻止有问题的提交）"
    echo "  2. post-commit - 提交后审查（不影响提交流程，当前默认）"
    echo ""
    echo -e "${YELLOW}说明：${NC}"
    echo "  • pre-commit：在 git commit 之前进行代码审查，如果发现严重问题可以阻止提交"
    echo "  • post-commit：在 git commit 之后进行代码审查，不会影响正常的提交流程"

    read -p "请选择审查时机 (1-2): " choice

    case "$choice" in
        "1")
            local selected_timing="pre-commit"
            echo -e "${GREEN}✓ 已选择: $selected_timing (提交前审查)${NC}"
            set_config_value "REVIEW_TIMING" "$selected_timing" "$scope"
            echo -e "${YELLOW}注意：选择提交前审查后，需要重新运行安装脚本来更新Git hooks${NC}"
            ;;
        "2")
            local selected_timing="post-commit"
            echo -e "${GREEN}✓ 已选择: $selected_timing (提交后审查)${NC}"
            set_config_value "REVIEW_TIMING" "$selected_timing" "$scope"
            ;;
        *)
            echo -e "${RED}❌ 无效选择${NC}"
            return 1
            ;;
    esac
}

# 配置自动更新选项
#
# 功能: 交互式配置自动更新相关选项
# 参数:
#   $1 - scope: 配置范围 (可选, 默认: "global")
# 返回: 0=成功, 1=失败
# 复杂度: O(1) - 用户交互
# 依赖: set_config_value()
# 调用者: main()
configure_auto_update() {
    local scope=${1:-"global"}

    echo -e "${BLUE}=== 配置自动更新 ===${NC}"
    echo ""

    # 显示当前配置
    local current_enabled=$(get_config_value "AUTO_UPDATE_ENABLED" "$scope")
    local current_interval=$(get_config_value "UPDATE_CHECK_INTERVAL" "$scope")
    local current_channel=$(get_config_value "UPDATE_CHANNEL" "$scope")

    current_enabled=${current_enabled:-"true"}
    current_interval=${current_interval:-"daily"}
    current_channel=${current_channel:-"stable"}

    echo -e "${YELLOW}当前配置:${NC}"
    echo "  自动更新: $current_enabled"
    echo "  检查间隔: $current_interval"
    echo "  更新渠道: $current_channel"
    echo ""

    # 配置是否启用自动更新
    echo "1. 是否启用自动更新?"
    echo "   a) true  - 启用 (推荐)"
    echo "   b) false - 禁用"
    read -p "请选择 [a/b] (当前: $current_enabled): " update_enabled

    case "$update_enabled" in
        "a"|"true"|"")
            set_config_value "AUTO_UPDATE_ENABLED" "true" "$scope"
            ;;
        "b"|"false")
            set_config_value "AUTO_UPDATE_ENABLED" "false" "$scope"
            echo -e "${YELLOW}⚠️  自动更新已禁用${NC}"
            return 0  # 如果禁用，不需要配置其他选项
            ;;
        *)
            echo -e "${RED}❌ 无效选择，保持当前设置${NC}"
            ;;
    esac

    # 配置检查间隔
    echo ""
    echo "2. 更新检查间隔:"
    echo "   1. daily  - 每天检查"
    echo "   2. weekly - 每周检查"
    echo "   3. never  - 从不检查"
    read -p "请选择 [1-3] (当前: $current_interval): " interval_choice

    case "$interval_choice" in
        "1"|"")
            set_config_value "UPDATE_CHECK_INTERVAL" "daily" "$scope"
            ;;
        "2")
            set_config_value "UPDATE_CHECK_INTERVAL" "weekly" "$scope"
            ;;
        "3")
            set_config_value "UPDATE_CHECK_INTERVAL" "never" "$scope"
            ;;
        *)
            echo -e "${RED}❌ 无效选择，保持当前设置${NC}"
            ;;
    esac

    # 配置更新渠道
    echo ""
    echo "3. 更新渠道:"
    echo "   1. stable - 稳定版 (推荐)"
    echo "   2. beta   - 测试版"
    read -p "请选择 [1-2] (当前: $current_channel): " channel_choice

    case "$channel_choice" in
        "1"|"")
            set_config_value "UPDATE_CHANNEL" "stable" "$scope"
            ;;
        "2")
            set_config_value "UPDATE_CHANNEL" "beta" "$scope"
            ;;
        *)
            echo -e "${RED}❌ 无效选择，保持当前设置${NC}"
            ;;
    esac

    echo ""
    echo -e "${GREEN}✓ 自动更新配置完成${NC}"
}

# 主函数
#
# 功能: 命令行接口，解析参数并调用相应功能
# 参数: $@ - 命令行参数
#   命令格式:
#     show [scope]              - 显示配置
#     set <key> <value> [scope] - 设置配置项
#     get <key> [scope]         - 获取配置项
#     configure <service> [scope] - 交互式配置服务
#     select [scope]            - 选择AI服务
#     validate [service]        - 验证服务配置
#     help                      - 显示帮助信息
# 返回: 0=成功, 1=参数错误或操作失败
# 复杂度: O(1) - 命令分发
# 依赖: 所有其他函数
# 调用者: 脚本直接执行时
# 示例:
#   main show
#   main set AI_SERVICE gemini
#   main configure gemini project
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
        "timing")
            select_review_timing "${2:-project}"
            ;;
        "update")
            configure_auto_update "${2:-global}"
            ;;
        "validate")
            # 验证指定服务或当前配置的服务
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
            echo "  timing [scope]            - 选择代码审查时机"
            echo "  update [scope]            - 配置自动更新选项"
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
