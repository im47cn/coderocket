# AI服务故障转移配置指南

## 📋 概述

CodeRocket现在支持智能AI服务故障转移功能，当主要AI服务遇到错误（如429限流、网络超时等）时，系统会自动切换到其他可用的AI服务，确保代码审查和MR生成功能的连续性。

## 🚀 主要特性

### 1. 智能错误识别
- **429限流错误**: 立即切换到下一个服务
- **认证错误**: 跳过该服务，提示用户配置
- **网络超时**: 重试一次后切换
- **CLI未安装**: 跳过该服务，提示安装
- **服务器错误**: 重试一次后切换

### 2. 自动服务切换
- 按优先级尝试可用服务
- 透明的切换过程，用户友好提示
- 保持向后兼容性

### 3. 灵活配置
- 可启用/禁用自动切换
- 自定义服务优先级
- 可调节重试策略

## ⚙️ 配置选项

### 环境变量配置

```bash
# 启用/禁用自动切换 (默认: true)
export AI_AUTO_SWITCH=true

# 最大重试次数 (默认: 3)
export AI_MAX_RETRIES=3

# 重试延迟时间，秒 (默认: 1)
export AI_RETRY_DELAY=1

# 服务优先级 (默认: "gemini claudecode")
export AI_SERVICE_PRIORITY="gemini claudecode"

# 超时时间，秒 (默认: 30)
export AI_TIMEOUT=30
```

### 配置文件设置

**项目级配置** (`.ai-config`):
```bash
AI_SERVICE=gemini
AI_AUTO_SWITCH=true
AI_SERVICE_PRIORITY=gemini claudecode
AI_MAX_RETRIES=3
```

**全局配置** (`~/.coderocket/ai-config`):
```bash
AI_SERVICE=gemini
AI_AUTO_SWITCH=true
AI_SERVICE_PRIORITY=gemini claudecode
AI_MAX_RETRIES=5
AI_RETRY_DELAY=2
```

## 🔧 使用示例

### 1. 基础使用
```bash
# 使用默认配置，自动启用故障转移
coderocket review

# 查看当前AI服务状态
./lib/ai-service-manager.sh status
```

### 2. 自定义配置
```bash
# 禁用自动切换，只使用主服务
export AI_AUTO_SWITCH=false
coderocket review

# 设置自定义服务优先级
export AI_SERVICE_PRIORITY="claudecode gemini"
coderocket review
```

### 3. 测试故障转移
```bash
# 运行故障转移测试
./test-ai-failover.sh
```

## 📊 错误处理策略

| 错误类型 | 识别模式 | 处理策略 | 用户提示 |
|---------|---------|---------|---------|
| 429限流 | `429`, `rate limit`, `quota exceeded` | 立即切换 | 🚫 服务达到使用限制 |
| 认证错误 | `401`, `403`, `unauthorized`, `api key` | 跳过服务 | 🔐 认证失败，请检查配置 |
| 网络错误 | `timeout`, `connection`, `network` | 重试后切换 | 🌐 网络连接问题 |
| CLI未安装 | `command not found`, `127` | 跳过服务 | 📦 CLI工具未安装 |
| 服务器错误 | `500`, `502`, `503`, `internal error` | 重试后切换 | 🔧 服务器错误 |

## 🎯 最佳实践

### 1. 服务配置建议
```bash
# 推荐配置：安装多个AI服务作为备用
npm install -g @google/gemini-cli

npm install -g @anthropic-ai/claude-code

# 配置API密钥
export GEMINI_API_KEY="your_gemini_key"

export CLAUDECODE_API_KEY="your_claude_key"
```

### 2. 监控和调试
```bash
# 启用详细日志
export DEBUG=true

# 查看服务切换历史
tail -f ~/.coderocket/logs/ai-service.log

# 测试所有服务可用性
./lib/ai-service-manager.sh test
```

### 3. 性能优化
```bash
# 根据网络情况调整超时
export AI_TIMEOUT=60  # 网络较慢时

# 减少重试次数以加快切换
export AI_MAX_RETRIES=1

# 设置更短的重试延迟
export AI_RETRY_DELAY=0.5
```

## 🔍 故障排除

### 常见问题

#### 1. 所有服务都不可用
```bash
# 检查服务安装状态
./lib/ai-service-manager.sh status

# 检查网络连接
ping google.com
curl -I https://api.openai.com

# 验证API密钥
echo $GEMINI_API_KEY
```

#### 2. 切换过于频繁
```bash
# 增加重试次数
export AI_MAX_RETRIES=5

# 增加重试延迟
export AI_RETRY_DELAY=3

# 检查主服务配置
./lib/ai-config.sh validate
```

#### 3. 性能问题
```bash
# 禁用自动切换以提高速度
export AI_AUTO_SWITCH=false

# 使用最快的服务作为主服务
export AI_SERVICE=gemini

# 减少超时时间
export AI_TIMEOUT=15
```

## 📈 监控指标

系统会自动记录以下指标：
- 服务成功率
- 平均响应时间
- 错误类型分布
- 切换频率

查看监控数据：
```bash
# 查看服务统计
./lib/ai-service-manager.sh stats

# 查看错误日志
cat ~/.coderocket/logs/errors.log
```

## 🔄 版本兼容性

- **向后兼容**: 现有配置无需修改
- **渐进增强**: 新功能默认启用，可选择禁用
- **API稳定**: 现有函数接口保持不变

## 📞 技术支持

如果遇到问题，请：
1. 运行 `./test-ai-failover.sh` 进行诊断
2. 查看 `~/.coderocket/logs/` 目录下的日志文件
3. 提供详细的错误信息和配置信息
