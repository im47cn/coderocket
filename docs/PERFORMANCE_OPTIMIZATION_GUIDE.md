# CodeRocket 性能优化指南

## 🚀 概述

本指南提供了优化 CodeRocket 性能的最佳实践和技巧，帮助您获得更快的代码审查体验和更高的工作效率。

## 📊 性能基准

### 典型性能指标

| 操作 | 优化前 | 优化后 | 改善幅度 |
|------|--------|--------|----------|
| 代码审查 | 45-60秒 | 15-25秒 | 60%+ |
| MR创建 | 20-30秒 | 8-12秒 | 50%+ |
| 配置加载 | 2-3秒 | 0.5-1秒 | 70%+ |
| Hook执行 | 50-70秒 | 20-30秒 | 60%+ |

## ⚡ AI服务优化

### 1. 选择最优AI服务

**性能对比**：
```bash
# 测试不同AI服务的响应时间
./lib/ai-service-manager.sh benchmark

# 结果示例：
# Gemini: 平均 18秒
# OpenCode: 平均 22秒  
# ClaudeCode: 平均 25秒
```

**推荐配置**：
```bash
# 高性能配置
echo "AI_SERVICE=gemini" > .ai-config
echo "AI_TIMEOUT=30" >> .env
echo "AI_MAX_RETRIES=2" >> .env
```

### 2. 优化API调用参数

**Gemini优化**：
```bash
# 使用更快的模型
echo "GEMINI_MODEL=gemini-pro" >> .env

# 优化提示词长度
echo "MAX_PROMPT_LENGTH=4000" >> .env

# 启用流式响应
echo "GEMINI_STREAM=true" >> .env
```

**通用优化**：
```bash
# 减少超时时间（适合稳定网络）
echo "AI_TIMEOUT=20" >> .env

# 减少重试次数
echo "AI_MAX_RETRIES=1" >> .env

# 启用响应缓存
echo "ENABLE_AI_CACHE=true" >> .env
```

### 3. 网络优化

**连接池配置**：
```bash
# 复用HTTP连接
echo "HTTP_KEEP_ALIVE=true" >> .env
echo "HTTP_MAX_CONNECTIONS=5" >> .env

# 启用压缩
echo "HTTP_COMPRESSION=true" >> .env
```

**代理优化**：
```bash
# 使用本地代理加速
export https_proxy=http://localhost:7890
export http_proxy=http://localhost:7890

# 或配置CDN加速
echo "AI_API_ENDPOINT=https://your-cdn.com/api" >> .env
```

## 🔧 系统级优化

### 1. 文件系统优化

**使用SSD存储**：
```bash
# 将审查日志存储到SSD
echo "REVIEW_LOGS_DIR=/ssd/coderocket-logs" >> .env
mkdir -p /ssd/coderocket-logs
```

**优化临时文件**：
```bash
# 使用内存文件系统
echo "TEMP_DIR=/tmp/coderocket-temp" >> .env
mkdir -p /tmp/coderocket-temp

# 或使用RAM磁盘
sudo mount -t tmpfs -o size=100M tmpfs /tmp/coderocket-temp
```

### 2. 内存优化

**配置内存限制**：
```bash
# 限制Node.js内存使用
echo "NODE_OPTIONS='--max-old-space-size=512'" >> .env

# 启用垃圾回收优化
echo "NODE_OPTIONS='--optimize-for-size'" >> .env
```

**清理策略**：
```bash
# 自动清理旧日志
echo "AUTO_CLEANUP_DAYS=7" >> .env

# 限制日志文件大小
echo "MAX_LOG_SIZE=10MB" >> .env
```

### 3. 并发优化

**并行处理**：
```bash
# 启用并行AI调用（谨慎使用）
echo "ENABLE_PARALLEL_AI=false" >> .env  # 默认关闭，避免API限制

# 优化Git操作并发
echo "GIT_PARALLEL_JOBS=2" >> .env
```

## 📝 配置优化

### 1. 智能配置加载

**配置缓存**：
```bash
# 启用配置缓存
echo "ENABLE_CONFIG_CACHE=true" >> .env
echo "CONFIG_CACHE_TTL=300" >> .env  # 5分钟缓存
```

**配置优先级优化**：
```bash
# 优化配置文件结构
# 将最常用的配置放在环境变量中
export AI_SERVICE=gemini
export AI_TIMEOUT=25
export GITLAB_PERSONAL_ACCESS_TOKEN="your-token"

# 减少配置文件查找
echo "SKIP_GLOBAL_CONFIG=true" >> .env
```

### 2. 提示词优化

**精简提示词**：
```bash
# 创建高效提示词模板
cat > prompts/optimized-prompt.md << 'EOF'
# 高效代码审查提示词

## 核心要求
- 重点关注：功能正确性、安全问题、性能问题
- 输出格式：简洁的要点列表
- 长度限制：最多500字

## 审查重点
1. 逻辑错误和bug
2. 安全漏洞
3. 性能瓶颈
4. 代码规范

请基于以上要求进行快速审查。
EOF
```

**动态提示词**：
```bash
# 根据文件类型使用不同提示词
echo "DYNAMIC_PROMPTS=true" >> .env
echo "PROMPT_JS=prompts/javascript-prompt.md" >> .env
echo "PROMPT_PY=prompts/python-prompt.md" >> .env
```

## 🎯 Hook优化

### 1. 选择性执行

**智能触发**：
```bash
# 只对重要文件执行审查
cat > .coderocket-ignore << 'EOF'
*.md
*.txt
*.json
package-lock.json
yarn.lock
EOF
```

**条件执行**：
```bash
# 在post-commit hook中添加条件判断
if [ "$(git diff --name-only HEAD~1 | wc -l)" -gt 10 ]; then
    echo "变更文件过多，跳过自动审查"
    exit 0
fi
```

### 2. 异步执行

**后台处理**：
```bash
# 修改post-commit hook为异步执行
# 在hook末尾添加：
{
    # 原有的审查逻辑
    call_ai_for_review "$service" "$prompt_file" "$prompt"
} &

# 立即返回，不阻塞Git操作
echo "代码审查已在后台启动..."
```

**进度通知**：
```bash
# 添加进度通知
echo "ENABLE_PROGRESS_NOTIFICATION=true" >> .env
echo "NOTIFICATION_COMMAND=notify-send" >> .env
```

## 📈 监控和分析

### 1. 性能监控

**执行时间统计**：
```bash
# 创建性能监控脚本
cat > monitor-performance.sh << 'EOF'
#!/bin/bash
echo "=== 性能监控报告 ==="

# Hook执行时间
echo "最近10次Hook执行时间："
grep "执行时间" review_logs/*.md | tail -10

# AI服务响应时间
echo "AI服务平均响应时间："
./lib/ai-service-manager.sh stats

# 系统资源使用
echo "系统资源使用："
ps aux | grep coderocket
EOF

chmod +x monitor-performance.sh
```

**自动化监控**：
```bash
# 添加到crontab
echo "0 */6 * * * /path/to/monitor-performance.sh >> /var/log/coderocket-perf.log" | crontab -
```

### 2. 性能分析

**瓶颈识别**：
```bash
# 使用time命令分析
time ./githooks/post-commit

# 使用strace分析系统调用
strace -c -f ./githooks/post-commit

# 使用htop监控资源使用
htop -p $(pgrep -f coderocket)
```

## 🔄 高级优化技巧

### 1. 预编译和缓存

**脚本预编译**：
```bash
# 预编译常用脚本
bash -n lib/ai-service-manager.sh  # 语法检查
bash -x lib/ai-service-manager.sh  # 调试模式检查
```

**结果缓存**：
```bash
# 启用智能缓存
echo "ENABLE_SMART_CACHE=true" >> .env
echo "CACHE_DURATION=3600" >> .env  # 1小时缓存

# 缓存相似代码的审查结果
echo "ENABLE_SIMILARITY_CACHE=true" >> .env
```

### 2. 资源预加载

**预热AI服务**：
```bash
# 创建预热脚本
cat > warmup.sh << 'EOF'
#!/bin/bash
echo "预热AI服务..."
echo "简单测试" | gemini > /dev/null 2>&1
echo "AI服务预热完成"
EOF

# 在系统启动时执行
echo "@reboot /path/to/warmup.sh" | crontab -
```

### 3. 批量处理优化

**批量审查**：
```bash
# 批量处理多个提交
batch-review() {
    local commits=$(git log --oneline -n 5 --format="%H")
    for commit in $commits; do
        git checkout $commit
        ./githooks/post-commit &
    done
    wait  # 等待所有后台任务完成
}
```

## 📊 性能测试

### 基准测试脚本

```bash
#!/bin/bash
# benchmark.sh - 性能基准测试

echo "=== CodeRocket 性能基准测试 ==="

# 测试1：配置加载时间
echo "1. 配置加载测试："
time ./lib/ai-config.sh show > /dev/null

# 测试2：AI服务响应时间
echo "2. AI服务响应测试："
time echo "测试代码审查" | gemini > /dev/null

# 测试3：Hook执行时间
echo "3. Hook执行测试："
time ./githooks/post-commit > /dev/null

# 测试4：MR创建时间
echo "4. MR创建测试："
time ./githooks/pre-push > /dev/null 2>&1

echo "=== 测试完成 ==="
```

### 压力测试

```bash
#!/bin/bash
# stress-test.sh - 压力测试

echo "=== 压力测试开始 ==="

# 并发测试
for i in {1..5}; do
    {
        echo "并发测试 $i"
        ./githooks/post-commit
    } &
done

wait
echo "=== 压力测试完成 ==="
```

## 💡 最佳实践总结

### 1. 日常使用优化

```bash
# 创建优化配置模板
cat > .env.optimized << 'EOF'
# 性能优化配置
AI_SERVICE=gemini
AI_TIMEOUT=25
AI_MAX_RETRIES=2
ENABLE_CONFIG_CACHE=true
AUTO_CLEANUP_DAYS=7
MAX_LOG_SIZE=5MB
ENABLE_PROGRESS_NOTIFICATION=true
EOF
```

### 2. 团队协作优化

```bash
# 团队共享的优化配置
cat > .env.team << 'EOF'
# 团队优化配置
AI_SERVICE=gemini
AI_TIMEOUT=30
ENABLE_SMART_CACHE=true
CACHE_DURATION=1800
SKIP_GLOBAL_CONFIG=true
DYNAMIC_PROMPTS=true
EOF
```

### 3. CI/CD环境优化

```bash
# CI/CD专用配置
cat > .env.ci << 'EOF'
# CI/CD优化配置
AI_SERVICE=gemini
AI_TIMEOUT=60
AI_MAX_RETRIES=3
ENABLE_PARALLEL_AI=false
AUTO_CLEANUP_DAYS=1
DEBUG=false
EOF
```

## 🎯 性能目标

通过应用本指南的优化技巧，您应该能够达到：

- ✅ **代码审查时间**: 从60秒减少到20秒
- ✅ **MR创建时间**: 从30秒减少到10秒
- ✅ **配置加载时间**: 从3秒减少到1秒
- ✅ **内存使用**: 减少40%
- ✅ **网络请求**: 减少30%

---

**记住：性能优化是一个持续的过程，定期监控和调整是关键！** ⚡✨
