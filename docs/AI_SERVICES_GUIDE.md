# AI 服务使用指南

本指南详细说明如何配置和使用 CodeReview CLI 支持的多种 AI 服务。

## 🤖 支持的 AI 服务

### 1. Google Gemini (默认)

- **模型**: Gemini Pro
- **特点**: 强大的代码理解和生成能力
- **安装**: `npm install -g @google/gemini-cli`
- **配置**: 需要 Google AI Studio API 密钥

### 2. OpenCode

- **模型**: OpenCode Pro
- **特点**: 专注于代码分析和优化
- **安装**: `npm install -g @opencode/cli`
- **配置**: 需要 OpenCode API 密钥

### 3. ClaudeCode

- **模型**: Claude 4 Sonnet
- **特点**: 优秀的代码审查和建议能力
- **安装**: `npm install -g @claudecode/cli`
- **配置**: 需要 ClaudeCode API 密钥

## ⚙️ 配置方法

### 快速配置

使用交互式配置工具：

```bash
# 选择AI服务
./lib/ai-config.sh select

# 配置特定服务
./lib/ai-config.sh configure gemini
./lib/ai-config.sh configure opencode
./lib/ai-config.sh configure claudecode
```

### 手动配置

#### 环境变量配置

```bash
# 选择AI服务
export AI_SERVICE=gemini  # 或 opencode, claudecode

# Gemini 配置
export GEMINI_API_KEY=your_gemini_api_key
export GEMINI_MODEL=gemini-pro

# OpenCode 配置
export OPENCODE_API_KEY=your_opencode_api_key
export OPENCODE_API_URL=https://api.opencode.com/v1
export OPENCODE_MODEL=opencode-pro

# ClaudeCode 配置
export CLAUDECODE_API_KEY=your_claudecode_api_key
export CLAUDECODE_API_URL=https://api.claudecode.com/v1
export CLAUDECODE_MODEL=claude-3-sonnet
```

#### 配置文件

**项目级配置** (`.ai-config`)：
```bash
AI_SERVICE=gemini
GEMINI_API_KEY=your_api_key
GEMINI_MODEL=gemini-pro
```

**全局配置** (`~/.codereview-cli/ai-config`)：
```bash
AI_SERVICE=gemini
GEMINI_API_KEY=your_api_key
```

## 🔧 使用方法

### 检查服务状态

```bash
# 查看所有AI服务状态
./lib/ai-service-manager.sh status

# 测试当前AI服务
./lib/ai-service-manager.sh test
```

### 切换AI服务

```bash
# 设置项目级AI服务
./lib/ai-config.sh set AI_SERVICE gemini

# 设置全局AI服务
./lib/ai-config.sh set AI_SERVICE gemini global
```

### 验证配置

```bash
# 验证当前AI服务配置
./lib/ai-config.sh validate

# 验证特定服务配置
./lib/ai-config.sh validate gemini
```

## 🚀 高级功能

### 备用方案

当主要AI服务不可用时，系统会自动使用备用方案：

1. **MR标题生成**: 基于分支名称生成
2. **MR描述生成**: 简单列出提交记录
3. **代码审查**: 跳过AI分析，仅进行基本检查

### 性能优化

```bash
# 设置超时时间（秒）
export AI_TIMEOUT=30

# 设置重试次数
export AI_MAX_RETRIES=3
```

### 调试模式

```bash
# 启用调试模式
export DEBUG=true

# 查看详细日志
./lib/ai-service-manager.sh test
```

## 🔍 故障排除

### 常见问题

#### 1. AI服务不可用

```bash
# 检查服务状态
./lib/ai-service-manager.sh status

# 重新安装CLI工具
npm install -g @google/gemini-cli
npm install -g @opencode/cli
npm install -g @claudecode/cli
```

#### 2. API密钥配置错误

```bash
# 重新配置API密钥
./lib/ai-config.sh configure gemini

# 验证配置
./lib/ai-config.sh validate gemini
```

#### 3. 网络连接问题

```bash
# 测试网络连接
curl -I https://api.openai.com
curl -I https://api.opencode.com
curl -I https://api.claudecode.com

# 设置代理（如需要）
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
```

#### 4. 权限问题

```bash
# 检查文件权限
ls -la lib/
chmod +x lib/*.sh

# 检查配置文件权限
ls -la .ai-config
chmod 644 .ai-config
```

## 📊 性能对比

| 服务 | 响应速度 | 代码理解 | 中文支持 | 成本 |
|------|----------|----------|----------|------|
| Gemini | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 💰💰 |
| OpenCode | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | 💰💰💰 |
| ClaudeCode | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 💰💰💰💰 |

## 🔗 相关链接

- [Google AI Studio](https://aistudio.google.com/app/apikey)
- [OpenCode API 文档](https://docs.opencode.com)
- [ClaudeCode API 文档](https://docs.claudecode.com)
- [CodeReview CLI 主文档](../README.md)

## 💡 最佳实践

1. **选择合适的AI服务**: 根据项目需求和预算选择
2. **配置备用服务**: 设置多个AI服务以提高可用性
3. **定期更新**: 保持CLI工具和API密钥的更新
4. **监控使用量**: 关注API调用次数和成本
5. **团队协作**: 统一团队的AI服务配置

## 🆘 获取帮助

如果遇到问题，请：

1. 查看本指南的故障排除部分
2. 运行 `./lib/ai-service-manager.sh status` 检查状态
3. 查看 [GitHub Issues](https://github.com/im47cn/codereview-cli/issues)
4. 创建新的 Issue 报告问题
