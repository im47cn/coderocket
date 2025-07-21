#!/bin/bash

# Auto Update Test Script
# 自动更新功能测试脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试配置
TEST_DIR="/tmp/codereview-cli-test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=== CodeReview CLI 自动更新功能测试 ===${NC}"
echo ""

# 清理测试环境
cleanup() {
    echo -e "${YELLOW}清理测试环境...${NC}"
    rm -rf "$TEST_DIR"
}

# 设置测试环境
setup_test_env() {
    echo -e "${BLUE}设置测试环境...${NC}"
    
    # 清理旧的测试目录
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    # 复制当前代码到测试目录
    cp -r "$SCRIPT_DIR"/* "$TEST_DIR/"
    
    # 设置执行权限
    chmod +x "$TEST_DIR"/*.sh
    chmod +x "$TEST_DIR"/lib/*.sh
    
    echo -e "${GREEN}✅ 测试环境设置完成${NC}"
}

# 测试版本比较功能
test_version_comparison() {
    echo -e "\n${BLUE}=== 测试版本比较功能 ===${NC}"
    
    local version_compare="$TEST_DIR/lib/version-compare.sh"
    
    if [ ! -f "$version_compare" ]; then
        echo -e "${RED}❌ 版本比较模块不存在${NC}"
        return 1
    fi
    
    # 测试用例
    local test_cases=(
        "1.0.0:1.0.0:0"    # 相等
        "1.0.1:1.0.0:1"    # 大于
        "1.0.0:1.0.1:2"    # 小于
        "2.0.0:1.9.9:1"    # 大于
        "v1.0.0:1.0.0:0"   # 带v前缀
    )
    
    local passed=0
    local total=${#test_cases[@]}
    
    for test_case in "${test_cases[@]}"; do
        local IFS=':'
        local parts=($test_case)
        local v1="${parts[0]}"
        local v2="${parts[1]}"
        local expected="${parts[2]}"
        
        "$version_compare" compare "$v1" "$v2" >/dev/null 2>&1
        local result=$?
        
        if [ $result -eq $expected ]; then
            echo -e "${GREEN}✅ $v1 vs $v2 = $result (期望: $expected)${NC}"
            passed=$((passed + 1))
        else
            echo -e "${RED}❌ $v1 vs $v2 = $result (期望: $expected)${NC}"
        fi
    done
    
    echo -e "${BLUE}版本比较测试结果: $passed/$total 通过${NC}"
    
    if [ $passed -eq $total ]; then
        return 0
    else
        return 1
    fi
}

# 测试配置管理功能
test_config_management() {
    echo -e "\n${BLUE}=== 测试配置管理功能 ===${NC}"
    
    local auto_updater="$TEST_DIR/lib/auto-updater.sh"
    local ai_config="$TEST_DIR/lib/ai-config.sh"
    
    if [ ! -f "$auto_updater" ] || [ ! -f "$ai_config" ]; then
        echo -e "${RED}❌ 配置管理模块不存在${NC}"
        return 1
    fi
    
    # 测试设置配置
    echo "测试设置自动更新配置..."
    "$ai_config" set AUTO_UPDATE_ENABLED true global >/dev/null 2>&1
    local enabled=$("$ai_config" get AUTO_UPDATE_ENABLED global 2>/dev/null)
    
    if [ "$enabled" = "true" ]; then
        echo -e "${GREEN}✅ 配置设置成功${NC}"
    else
        echo -e "${RED}❌ 配置设置失败${NC}"
        return 1
    fi
    
    # 测试获取配置
    echo "测试获取配置..."
    "$ai_config" show global >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 配置获取成功${NC}"
    else
        echo -e "${RED}❌ 配置获取失败${NC}"
        return 1
    fi
    
    return 0
}

# 测试缓存机制
test_cache_mechanism() {
    echo -e "\n${BLUE}=== 测试缓存机制 ===${NC}"
    
    local auto_updater="$TEST_DIR/lib/auto-updater.sh"
    
    # 设置测试环境变量
    export HOME="$TEST_DIR"
    export AUTO_UPDATE_ENABLED="true"
    
    # 测试缓存目录创建
    source "$auto_updater"
    ensure_cache_dir
    
    if [ -d "$TEST_DIR/.codereview-cli" ]; then
        echo -e "${GREEN}✅ 缓存目录创建成功${NC}"
    else
        echo -e "${RED}❌ 缓存目录创建失败${NC}"
        return 1
    fi
    
    # 测试缓存文件写入
    update_cache "1.0.1"
    local cache_file="$TEST_DIR/.codereview-cli/update_cache"
    
    if [ -f "$cache_file" ]; then
        local cached_version=$(grep "^latest_version=" "$cache_file" | cut -d'=' -f2)
        if [ "$cached_version" = "1.0.1" ]; then
            echo -e "${GREEN}✅ 缓存写入成功${NC}"
        else
            echo -e "${RED}❌ 缓存内容错误${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ 缓存文件创建失败${NC}"
        return 1
    fi
    
    # 测试今日检查逻辑
    if should_check_today; then
        echo -e "${GREEN}✅ 今日检查逻辑正确（今天已检查）${NC}"
    else
        echo -e "${RED}❌ 今日检查逻辑错误${NC}"
        return 1
    fi
    
    return 0
}

# 测试锁机制
test_lock_mechanism() {
    echo -e "\n${BLUE}=== 测试锁机制 ===${NC}"
    
    local auto_updater="$TEST_DIR/lib/auto-updater.sh"
    
    # 设置测试环境变量
    export HOME="$TEST_DIR"
    
    source "$auto_updater"
    
    # 测试获取锁
    if acquire_update_lock; then
        echo -e "${GREEN}✅ 获取锁成功${NC}"
        
        # 测试重复获取锁（应该失败）
        if ! acquire_update_lock; then
            echo -e "${GREEN}✅ 重复获取锁正确失败${NC}"
        else
            echo -e "${RED}❌ 重复获取锁应该失败${NC}"
            release_update_lock
            return 1
        fi
        
        # 释放锁
        release_update_lock
        echo -e "${GREEN}✅ 释放锁成功${NC}"
        
        # 再次获取锁（应该成功）
        if acquire_update_lock; then
            echo -e "${GREEN}✅ 重新获取锁成功${NC}"
            release_update_lock
        else
            echo -e "${RED}❌ 重新获取锁失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ 获取锁失败${NC}"
        return 1
    fi
    
    return 0
}

# 测试安装模式检测
test_install_mode_detection() {
    echo -e "\n${BLUE}=== 测试安装模式检测 ===${NC}"
    
    local auto_updater="$TEST_DIR/lib/auto-updater.sh"
    
    source "$auto_updater"
    
    # 测试项目级安装检测
    local mode=$(detect_install_mode)
    echo "检测到的安装模式: $mode"
    
    if [ "$mode" = "project" ] || [ "$mode" = "global" ]; then
        echo -e "${GREEN}✅ 安装模式检测成功${NC}"
    else
        echo -e "${RED}❌ 安装模式检测失败${NC}"
        return 1
    fi
    
    # 测试安装目录获取
    local install_dir=$(get_install_dir)
    echo "检测到的安装目录: $install_dir"
    
    if [ -d "$install_dir" ]; then
        echo -e "${GREEN}✅ 安装目录检测成功${NC}"
    else
        echo -e "${RED}❌ 安装目录检测失败${NC}"
        return 1
    fi
    
    return 0
}

# 运行所有测试
run_all_tests() {
    local total_tests=0
    local passed_tests=0
    
    # 设置测试环境
    setup_test_env
    
    # 运行各项测试
    local tests=(
        "test_version_comparison"
        "test_config_management"
        "test_cache_mechanism"
        "test_lock_mechanism"
        "test_install_mode_detection"
    )
    
    for test_func in "${tests[@]}"; do
        total_tests=$((total_tests + 1))
        if $test_func; then
            passed_tests=$((passed_tests + 1))
        fi
    done
    
    # 显示测试结果
    echo -e "\n${BLUE}=== 测试结果汇总 ===${NC}"
    echo -e "${BLUE}总测试数: $total_tests${NC}"
    echo -e "${GREEN}通过测试: $passed_tests${NC}"
    echo -e "${RED}失败测试: $((total_tests - passed_tests))${NC}"
    
    if [ $passed_tests -eq $total_tests ]; then
        echo -e "\n${GREEN}🎉 所有测试通过！${NC}"
        cleanup
        return 0
    else
        echo -e "\n${RED}❌ 部分测试失败${NC}"
        cleanup
        return 1
    fi
}

# 主函数
main() {
    case "${1:-all}" in
        "version")
            test_version_comparison
            ;;
        "config")
            test_config_management
            ;;
        "cache")
            test_cache_mechanism
            ;;
        "lock")
            test_lock_mechanism
            ;;
        "install")
            test_install_mode_detection
            ;;
        "all")
            run_all_tests
            ;;
        "help"|"-h"|"--help")
            echo "自动更新功能测试脚本"
            echo ""
            echo "用法: $0 <测试类型>"
            echo ""
            echo "测试类型:"
            echo "  version  - 测试版本比较功能"
            echo "  config   - 测试配置管理功能"
            echo "  cache    - 测试缓存机制"
            echo "  lock     - 测试锁机制"
            echo "  install  - 测试安装模式检测"
            echo "  all      - 运行所有测试 (默认)"
            echo "  help     - 显示帮助信息"
            ;;
        *)
            echo -e "${RED}❌ 未知测试类型: $1${NC}"
            echo "运行 '$0 help' 查看可用选项"
            return 1
            ;;
    esac
}

# 如果直接执行此脚本，运行主函数
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
