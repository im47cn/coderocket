# CodeRocket API 参考文档

## 📋 概述

本文档详细描述了 CodeRocket 的核心 API 接口和函数，包括 AI 服务管理、配置管理、Git Hook 集成等模块的接口规范。

## 🔧 AI 服务管理 API

### ai-service-manager.sh

#### `get_ai_service()`
获取当前配置的AI服务

**语法**
```bash
get_ai_service()
```

**返回值**
- 字符串: AI服务名称 (`gemini`|`opencode`|`claudecode`)

**示例**
```bash
service=$(get_ai_service)
echo "当前AI服务: $service"
```

#### `check_ai_service_available(service)`
检查指定AI服务是否可用

**参数**
- `service`: AI服务名称

**返回值**
- `0`: 服务可用
- `1`: 服务不可用

**示例**
```bash
if check_ai_service_available "gemini"; then
    echo "Gemini服务可用"
fi
```

#### `call_ai_for_review(service, prompt_file, prompt)`
调用AI服务进行代码审查

**参数**
- `service`: AI服务名称
- `prompt_file`: 提示词文件路径
- `prompt`: 附加提示信息

**返回值**
- `0`: 调用成功
- `1`: 调用失败

**示例**
```bash
call_ai_for_review "gemini" "./prompts/review-prompt.md" "请审查最新提交"
```

#### `smart_ai_call(service, call_type, prompt, branch)`
智能AI调用接口

**参数**
- `service`: AI服务名称
- `call_type`: 调用类型 (`review`|`mr_title`|`mr_description`)
- `prompt`: 提示信息
- `branch`: 分支名称 (可选)

**返回值**
- `0`: 调用成功
- `1`: 调用失败

**示例**
```bash
smart_ai_call "gemini" "mr_title" "生成MR标题" "feature/new-feature"
```

#### `get_install_command(service)`
获取AI服务的安装命令

**参数**
- `service`: AI服务名称

**返回值**
- 字符串: 安装命令

**示例**
```bash
cmd=$(get_install_command "gemini")
echo "安装命令: $cmd"
```

## ⚙️ 配置管理 API

### ai-config.sh

#### `get_config_value(key, scope)`
获取配置值

**参数**
- `key`: 配置键名
- `scope`: 配置范围 (`project`|`global`|`all`)

**返回值**
- 字符串: 配置值

**示例**
```bash
api_key=$(get_config_value "GEMINI_API_KEY" "project")
```

#### `set_config_value(key, value, scope)`
设置配置值

**参数**
- `key`: 配置键名
- `value`: 配置值
- `scope`: 配置范围 (`project`|`global`)

**返回值**
- `0`: 设置成功
- `1`: 设置失败

**示例**
```bash
set_config_value "AI_SERVICE" "gemini" "project"
```

#### `validate_service_config(service)`
验证服务配置

**参数**
- `service`: AI服务名称

**返回值**
- `0`: 配置有效
- `1`: 配置无效

**示例**
```bash
if validate_service_config "gemini"; then
    echo "Gemini配置有效"
fi
```

#### `show_config(scope)`
显示配置信息

**参数**
- `scope`: 配置范围 (`all`|`project`|`global`)

**示例**
```bash
show_config "all"
```

## 🤖 AI 服务实现 API

### Gemini Service

#### `call_gemini_cli(prompt)`
调用Gemini CLI

**参数**
- `prompt`: 提示信息

**返回值**
- `0`: 调用成功
- `1`: 调用失败

#### `call_gemini_api(prompt)`
调用Gemini API

**参数**
- `prompt`: 提示信息

**返回值**
- `0`: 调用成功
- `1`: 调用失败

### OpenCode Service

#### `call_opencode_cli(prompt)`
调用OpenCode CLI

**参数**
- `prompt`: 提示信息

**返回值**
- `0`: 调用成功
- `1`: 调用失败

#### `call_opencode_api(prompt)`
调用OpenCode API

**参数**
- `prompt`: 提示信息

**返回值**
- `0`: 调用成功
- `1`: 调用失败

### ClaudeCode Service

#### `call_claudecode_cli(prompt)`
调用ClaudeCode CLI

**参数**
- `prompt`: 提示信息

**返回值**
- `0`: 调用成功
- `1`: 调用失败

#### `call_claudecode_api(prompt)`
调用ClaudeCode API

**参数**
- `prompt`: 提示信息

**返回值**
- `0`: 调用成功
- `1`: 调用失败

## 🔗 GitLab 集成 API

### MR 管理

#### `auto_get_project_id()`
自动获取GitLab项目ID

**返回值**
- 字符串: 项目ID

**示例**
```bash
project_id=$(auto_get_project_id)
```

#### `check_mr_exists(project_id, source_branch, target_branch)`
检查MR是否已存在

**参数**
- `project_id`: 项目ID
- `source_branch`: 源分支
- `target_branch`: 目标分支

**返回值**
- `0`: MR存在
- `1`: MR不存在

#### `create_mr(project_id, title, description, source_branch, target_branch)`
创建GitLab MR

**参数**
- `project_id`: 项目ID
- `title`: MR标题
- `description`: MR描述
- `source_branch`: 源分支
- `target_branch`: 目标分支

**返回值**
- `0`: 创建成功
- `1`: 创建失败

## 📊 工具函数 API

### 版本管理

#### `get_version()`
获取当前版本

**返回值**
- 字符串: 版本号

#### `check_version_update()`
检查版本更新

**返回值**
- `0`: 有更新
- `1`: 无更新

### 日志记录

#### `log_info(message)`
记录信息日志

**参数**
- `message`: 日志消息

#### `log_error(message)`
记录错误日志

**参数**
- `message`: 错误消息

#### `log_debug(message)`
记录调试日志

**参数**
- `message`: 调试消息

### 文件操作

#### `ensure_dir(path)`
确保目录存在

**参数**
- `path`: 目录路径

#### `safe_write_file(path, content)`
安全写入文件

**参数**
- `path`: 文件路径
- `content`: 文件内容

## 🔧 环境变量

### 必需变量

| 变量名 | 描述 | 示例值 |
|--------|------|--------|
| `GITLAB_PERSONAL_ACCESS_TOKEN` | GitLab访问令牌 | `glpat-xxxxxxxxxxxxxxxxxxxx` |

### 可选变量

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `AI_SERVICE` | AI服务选择 | `gemini` |
| `AI_TIMEOUT` | API调用超时 | `30` |
| `AI_MAX_RETRIES` | 最大重试次数 | `3` |
| `GITLAB_API_URL` | GitLab API地址 | `https://gitlab.com/api/v4` |
| `REVIEW_LOGS_DIR` | 审查日志目录 | `./review_logs` |
| `DEBUG` | 调试模式 | `false` |

### AI服务特定变量

#### Gemini
- `GEMINI_API_KEY`: API密钥
- `GEMINI_MODEL`: 模型名称 (默认: `gemini-pro`)

#### OpenCode
- `OPENCODE_API_KEY`: API密钥
- `OPENCODE_MODEL`: 模型名称 (默认: `opencode-pro`)
- `OPENCODE_API_URL`: API地址

#### ClaudeCode
- `CLAUDECODE_API_KEY`: API密钥
- `CLAUDECODE_MODEL`: 模型名称 (默认: `claude-3-sonnet`)
- `CLAUDECODE_API_URL`: API地址

## 🚨 错误代码

| 错误代码 | 描述 |
|----------|------|
| `0` | 成功 |
| `1` | 一般错误 |
| `2` | 配置错误 |
| `3` | 网络错误 |
| `4` | API错误 |
| `5` | 文件操作错误 |

## 📝 使用示例

### 完整的代码审查流程

```bash
#!/bin/bash

# 1. 获取当前AI服务
service=$(get_ai_service)
echo "使用AI服务: $service"

# 2. 检查服务可用性
if ! check_ai_service_available "$service"; then
    echo "服务不可用，尝试备用服务"
    service="gemini"  # 备用服务
fi

# 3. 执行代码审查
prompt_file="./prompts/git-commit-review-prompt.md"
prompt="请审查最新的Git提交"

if call_ai_for_review "$service" "$prompt_file" "$prompt"; then
    echo "代码审查完成"
else
    echo "代码审查失败"
fi
```

### 配置管理示例

```bash
#!/bin/bash

# 1. 设置AI服务
set_config_value "AI_SERVICE" "gemini" "project"

# 2. 配置API密钥
set_config_value "GEMINI_API_KEY" "your-api-key" "project"

# 3. 验证配置
if validate_service_config "gemini"; then
    echo "配置验证成功"
fi

# 4. 显示当前配置
show_config "project"
```

## 🔄 版本兼容性

- **当前版本**: 1.0.1
- **最低支持版本**: 1.0.0
- **API稳定性**: 向后兼容

## 📞 支持

如需API支持或有疑问，请：
1. 查看 [故障排除文档](../README.md#故障排除)
2. 提交 [GitHub Issue](https://github.com/im47cn/coderocket-cli/issues)
3. 参考 [贡献指南](../CONTRIBUTING.md)
