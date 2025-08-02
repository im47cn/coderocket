# CodeRocket CLI

<div align="center">
  <img src="https://raw.githubusercontent.com/im47cn/coderocket-cli/refs/heads/develop/docs/assets/banner.png" alt="CodeRocket Banner" />
</div>

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub stars](https://img.shields.io/github/stars/im47cn/coderocket-cli.svg)](https://github.com/im47cn/coderocket-cli/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/im47cn/coderocket-cli.svg)](https://github.com/im47cn/coderocket-cli/issues)
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/W7W71IFTGX)

一个基于多种 AI 服务（Gemini、ClaudeCode）的智能 Git 提交代码审查工具，通过 Git Hook 自动对每次提交进行全面的代码质量分析和审查，支持 GitLab MR 自动创建。

> **项目重命名通知**：CodeRocket 现已更名为 **CodeRocket**！为保持兼容性，原有的 `codereview-cli` 和 `cr` 命令仍可正常使用。

## 🚀 核心功能

- **自动化代码审查**：每次 Git 提交后自动触发 AI 代码审查
- **全局代码搜索**：基于提交信息进行智能的全局代码搜索分析
- **多维度评估**：从功能完整性、代码质量、可维护性、扩展性等多个维度进行评估
- **智能状态标记**：使用 ✅ ⚠️ ❌ 🔍 等状态符号直观显示审查结果
- **智能 MR 创建**：集成 Gemini AI 自动生成简洁有意义的 MR 标题和描述信息
- **VS Code 兼容**：完全支持 VS Code Git 工具，提供一致的用户体验
- **详细审查报告**：生成结构化的 Markdown 审查报告，包含具体的改进建议
- **配置灵活性**：支持全局和项目级别的配置定制

## 📋 目录

- [技术栈](#-技术栈)
- [环境要求](#-环境要求)
- [快速安装](#-快速安装)
- [环境变量配置](#-环境变量配置)
- [使用说明](#-使用说明)
- [配置说明](#️-配置说明)
- [审查报告](#-审查报告)
- [贡献指南](#-贡献指南)
- [许可证](#-许可证)

## 🛠 技术栈

- **AI 引擎**: 多AI服务支持（Gemini、ClaudeCode）
- **脚本语言**: Shell Script
- **版本控制**: Git Hooks (post-commit, pre-push)
- **文档格式**: Markdown
- **配置管理**: 基于文件的配置系统

## 📋 环境要求

- **操作系统**: macOS, Linux, Windows (WSL)
- **Node.js**: >= 14.0.0
- **Git**: >= 2.0.0
- **Google Gemini CLI**: 最新版本
- **网络连接**: 需要访问 Google Gemini API

## 🚀 快速安装

### 一键安装脚本

```bash
# 方式1：直接安装（默认全局安装）
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash

# 方式2：交互式安装（可选择安装模式）
wget https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh
chmod +x install.sh
./install.sh
```

**安装模式选择：**

1. **全局安装（推荐）**：
   - ✅ 新创建的 Git 仓库自动包含 CodeRocket
   - ✅ 提供 `coderocket` 全局命令（兼容 `coderocket`, `cr`）
   - ✅ 现有仓库只需运行 `coderocket setup`
   - ✅ 一次安装，终身受益
   - ✅ 避免每个项目都要安装的麻烦

2. **项目安装**：
   - ⚠️ 仅为当前项目安装
   - ⚠️ 需要为每个项目单独安装
   - ⚠️ 容易遗漏新项目

**提示词文档配置：**

安装过程中会询问是否创建项目级提示词文档：

- **选择 'y'**：在项目中创建 `prompts/git-commit-review-prompt.md`，可自定义代码审查规则
- **选择 'n'**：使用全局默认提示词，项目目录保持干净

> 💡 **建议**：大多数用户选择 'n' 即可，只有需要特殊审查规则的项目才需要自定义提示词

### 手动安装

#### 1. 安装 AI 服务 CLI

根据您选择的AI服务安装对应的CLI工具：

**Gemini (默认)**
```bash
npm install -g @google/gemini-cli
```

**ClaudeCode (可选)**
```bash
npm install -g @anthropic-ai/claude-code
```

#### 2. 配置 AI 服务

根据您选择的AI服务进行配置：

**Gemini 配置**
```bash
gemini config
# 按照提示输入您的 Google AI Studio API 密钥
```

**ClaudeCode 配置**
```bash
claudecode config
# 或设置环境变量: export CLAUDECODE_API_KEY='your_key'
```

#### 3. 克隆项目

```bash
git clone https://github.com/im47cn/coderocket-cli.git
cd coderocket-cli
```

#### 4. 运行安装脚本

```bash
./install-hooks.sh
```

#### 5. 配置环境变量

**方式一：项目级配置（推荐）**

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，设置你的 GitLab Token
# GITLAB_PERSONAL_ACCESS_TOKEN=your_token_here
# GITLAB_API_URL=https://gitlab.com/api/v4
```

**方式二：全局环境变量**

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
export GITLAB_PERSONAL_ACCESS_TOKEN="your_token_here"
export GITLAB_API_URL="https://gitlab.com/api/v4"
```

#### 6. 重启开发环境

如果使用 VS Code，请重启以加载新的环境变量。

## 🔧 环境变量配置

### 必需的环境变量

| 变量名 | 描述 | 示例值 |
|--------|------|--------|
| `GITLAB_PERSONAL_ACCESS_TOKEN` | GitLab 个人访问令牌 | `glpat-xxxxxxxxxxxxxxxxxxxx` |
| `GITLAB_API_URL` | GitLab API 地址（可选） | `https://gitlab.com/api/v4` |

### 获取 GitLab Personal Access Token

1. 登录 GitLab
2. 进入 **Settings** > **Access Tokens** > **Personal Access Tokens**
3. 创建新令牌，需要以下权限：
   - `api` - 完整的 API 访问权限
   - `read_repository` - 读取仓库权限
   - `write_repository` - 写入仓库权限

### 配置文件优先级

1. **项目级配置**: `.env` 文件（优先级最高）
2. **全局环境变量**: `~/.bashrc`, `~/.zshrc`, `~/.profile`
3. **CI 环境变量**: `CI_PROJECT_ID` 等

## 🎯 安装验证

### 全局安装验证

```bash
# 检查全局命令是否可用
coderocket --version

# 检查 Git 模板是否配置
git config --global init.templateDir

# 检查 Gemini CLI 是否可用
gemini --version
```

### 项目安装验证

```bash
# 检查 Git hooks 是否正确安装
ls -la .git/hooks/

# 检查环境变量是否正确设置
echo $GITLAB_PERSONAL_ACCESS_TOKEN
```

## 🔧 全局命令使用

全局安装后，可以使用 `coderocket` 命令（兼容 `coderocket` 和 `cr`）：

### 🚀 直接代码审查

```bash
# 在 Git 仓库中直接运行（推荐）
cd your-git-project
coderocket                   # 自动检测并审查最新提交

# 或者明确指定审查命令
coderocket review            # 审查最新提交

# 兼容命令（老用户）
coderocket               # 完全兼容
cr                          # 简短别名
```

**智能检测**：
- ✅ 如果在 Git 仓库中：自动执行代码审查
- ⚠️ 如果不在 Git 仓库中：显示使用指南

### 🛠️ 项目管理

```bash
# 为现有项目设置 CodeRocket hooks
coderocket setup

# 更新到最新版本
coderocket update

# 配置 AI 服务
coderocket config

# 配置代码审查时机（提交前/提交后）
coderocket timing

# 查看版本信息
coderocket version

# 查看帮助信息
coderocket help

# 兼容命令（所有功能完全相同）
coderocket setup         # 兼容老用户
cr help                     # 简短别名
```

## 📖 使用说明

### 核心功能

#### 1. 自动代码审查（Post-Commit Hook）

每次 `git commit` 后自动触发 AI 代码审查：

- ✅ 自动分析提交的代码变更
- ✅ 生成详细的审查报告
- ✅ 支持多维度质量评估
- ✅ 兼容 VS Code 和命令行

#### 2. 智能 MR 创建（Pre-Push Hook）

每次 `git push` 时自动创建 GitLab MR：

- ✅ 使用 Gemini AI 生成智能标题和描述
- ✅ 自动检测目标分支
- ✅ 支持多种分支命名规范
- ✅ 避免重复创建 MR

### 基本使用流程

#### 全局安装用户

1. **一次性全局安装**：运行一键安装脚本，选择全局安装
2. **新项目自动启用**：创建新 Git 仓库时自动包含 CodeRocket
3. **现有项目设置**：在现有仓库中运行 `coderocket setup`
4. **正常开发提交**：像往常一样进行代码开发和 Git 提交
5. **自动触发审查**：每次 `git commit` 后会自动触发代码审查
6. **查看审查报告**：审查完成后在 `review_logs/` 目录查看详细报告
7. **推送并创建 MR**：`git push` 时自动创建 GitLab MR

#### 项目安装用户

1. **完成项目安装**：按照上述安装指南完成环境配置
2. **正常开发提交**：像往常一样进行代码开发和 Git 提交
3. **自动触发审查**：每次 `git commit` 后会自动触发代码审查
4. **查看审查报告**：审查完成后在 `review_logs/` 目录查看详细报告
5. **推送并创建 MR**：`git push` 时自动创建 GitLab MR

### 示例工作流程

#### 全局安装 - 新项目

```bash
# 1. 创建新项目（自动包含 CodeRocket）
git init my-project
cd my-project

# 2. 修改代码
vim src/main.js

# 3. 添加到暂存区
git add src/main.js

# 4. 提交代码（会自动触发审查）
git commit -m "feat: 添加用户认证功能"

# 5. 查看审查报告
ls review_logs/
cat review_logs/20241201_1430_✅_6efa8d_添加用户认证功能.md

# 6. 推送代码（会自动创建 MR）
git push origin feature/user-auth
```

#### 全局安装 - 现有项目

```bash
# 1. 进入现有项目
cd existing-project

# 2. 设置 CodeRocket
coderocket setup

# 3. 正常开发流程（同上）
git add .
git commit -m "feat: 新功能"
git push
```

### VS Code 集成

本工具完全兼容 VS Code Git 工具：

- ✅ 在 VS Code 中提交代码会自动触发审查
- ✅ 在 VS Code 中推送代码会自动创建 MR
- ✅ 支持 VS Code 的环境变量加载
- ✅ 详细的 VS Code 设置指南：[docs/VSCODE_SETUP.md](docs/VSCODE_SETUP.md)

### 审查状态说明

- **✅ 通过**：功能完全实现，代码质量良好，无明显问题
- **⚠️ 警告**：功能基本实现，但存在明显的质量问题或优化空间
- **❌ 失败**：功能未实现、实现不正确或存在严重 bug
- **🔍 调查**：需要进一步调查（发现可能的遗漏但需要更深入分析）

## ⚙️ 配置说明

### 配置文件层级

1. **全局配置**: `~/prompts/git-commit-review-prompt.md`
2. **项目配置**: `./prompts/git-commit-review-prompt.md`

项目配置会覆盖全局配置，实现项目级别的定制化审查规则。

### 自定义审查规则

您可以通过修改 `prompts/git-commit-review-prompt.md` 文件来自定义审查规则：

```markdown
## 自定义审阅重点

### 项目特定关注点
- 特定的编码规范要求
- 项目架构约束
- 性能要求
- 安全要求

### 质量评估标准
- 自定义的质量门禁
- 特定的最佳实践
- 团队编码约定
```

### 高级环境变量

可以通过以下环境变量进行额外配置：

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `AI_SERVICE` | 选择AI服务 | `gemini` |
| `REVIEW_LOGS_DIR` | 审查报告输出目录 | `./review_logs` |
| `AI_TIMEOUT` | AI服务调用超时时间 | `30` |
| `AI_MAX_RETRIES` | AI服务重试次数 | `3` |
| `GEMINI_MODEL` | Gemini 模型参数 | `gemini-pro` |

| `CLAUDECODE_MODEL` | ClaudeCode 模型参数 | `claude-3-sonnet` |
| `DEBUG` | 启用调试模式 | `false` |

### AI 服务配置

#### 环境变量详细说明

复制 `.env.example` 为 `.env` 并根据需要配置：

```bash
cp .env.example .env
```

**必填环境变量**：
- `GITLAB_PERSONAL_ACCESS_TOKEN` - GitLab访问令牌（必须）
- `GEMINI_API_KEY` - Gemini API密钥（如果使用Gemini）

- `CLAUDECODE_API_KEY` - ClaudeCode API密钥（如果使用ClaudeCode）

**选填环境变量**：
- `AI_SERVICE` - 选择AI服务（默认: gemini）
- `REVIEW_TIMING` - 代码审查时机（默认: post-commit）
  - `pre-commit`: 提交前审查，可阻止有问题的提交
  - `post-commit`: 提交后审查，不影响提交流程
- `AI_TIMEOUT` - API调用超时时间（默认: 30秒）
- `AI_MAX_RETRIES` - 重试次数（默认: 3次）
- `GITLAB_API_URL` - GitLab API地址（默认: https://gitlab.com/api/v4）
- `GEMINI_MODEL` - Gemini模型（默认: gemini-pro）

- `CLAUDECODE_MODEL` - ClaudeCode模型（默认: claude-3-sonnet）
- `REVIEW_LOGS_DIR` - 审查日志目录（默认: ./review_logs）
- `DEBUG` - 调试模式（默认: false）

#### 选择AI服务

您可以通过以下方式选择和配置AI服务：

**方式一：环境变量**
```bash
export AI_SERVICE=gemini  # 或 claudecode
```

**方式二：配置文件**
```bash
# 项目级配置
echo "AI_SERVICE=gemini" > .ai-config

# 全局配置
mkdir -p ~/.coderocket
echo "AI_SERVICE=gemini" > ~/.coderocket/ai-config
```

**方式三：使用配置工具**
```bash
# 交互式选择AI服务
./lib/ai-config.sh select

# 选择代码审查时机
./lib/ai-config.sh timing

# 配置特定服务
./lib/ai-config.sh configure gemini
```

## 📊 审查报告

### 报告文件命名规则

```text
YYYYMMDD_HHmm_[状态符号]_[commit_hash前6位]_[简短描述].md
```

**示例**：

- `20241201_1430_✅_6efa8d_添加用户认证功能.md`
- `20241201_1545_⚠️_abc123_优化数据库查询性能.md`
- `20241201_1600_❌_def456_修复登录验证问题.md`

### 报告内容结构

每个审查报告包含以下部分：

1. **基本信息**：提交哈希、时间、作者、提交信息
2. **审查摘要**：状态、总体评价、目标达成度
3. **全局代码搜索分析**：搜索策略、发现、完整性评估
4. **详细审查**：功能完整性、代码质量、问题标记
5. **改进建议**：立即修复、短期改进、长期优化
6. **代码片段分析**：关键代码的详细分析
7. **总结**：审查结果和主要建议

### 问题标记系统

- `//MISSING`: 遗漏的重要修改
- `//FIXME`: 必须修复的 bug 或错误
- `//OPTIMIZE`: 可以优化的代码片段
- `//TODO`: 需要补充的功能或任务
- `//WARNING`: 潜在的风险或问题
- `//RULE`: 可以提炼的通用规则或模式
- `//SECURITY`: 安全相关的问题
- `//PERFORMANCE`: 性能相关的问题
- `//DEPENDENCY`: 依赖相关的问题

## 🤝 贡献

我们欢迎社区贡献！详细的贡献指南请参考 [CONTRIBUTING.md](CONTRIBUTING.md)。

### 快速开始

1. Fork 本仓库
2. 创建功能分支
3. 进行开发和测试
4. 提交 Pull Request

### 开发资源

- [贡献指南](CONTRIBUTING.md) - 详细的开发和贡献流程
- [AI服务指南](docs/AI_SERVICES_GUIDE.md) - AI服务配置和使用
- [测试脚本](test-ai-services.sh) - 完整的测试套件

## 🔗 相关链接

- [Google Gemini CLI 文档](https://github.com/google-gemini/gemini-cli)
- [Git Hooks 官方文档](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [GitLab API 文档](https://docs.gitlab.com/ee/api/)
- [项目问题反馈](https://github.com/im47cn/coderocket-cli/issues)
- [功能请求](https://github.com/im47cn/coderocket-cli/issues/new?template=feature_request.md)

## 📚 文档

- [VS Code 设置指南](docs/VSCODE_SETUP.md) - 详细的 VS Code 集成配置
- [VS Code 测试指南](docs/VSCODE_TEST_GUIDE.md) - 功能测试和验证步骤

## 📞 支持与反馈

如果您在使用过程中遇到问题或有改进建议，请：

1. 查看 [故障排除](#-故障排除) 部分
2. 搜索 [现有问题](https://github.com/im47cn/coderocket-cli/issues)
3. 创建 [新问题](https://github.com/im47cn/coderocket-cli/issues/new)

## 🌟 特性亮点

### AI 驱动的智能分析

- **多AI服务支持**：支持 Gemini、ClaudeCode 等多种AI服务
- **智能故障转移**：🆕 当AI服务遇到429限流等错误时，自动切换到其他可用服务
- **深度代码理解**：基于先进 AI 模型的代码分析能力
- **上下文感知**：理解代码变更的业务逻辑和技术影响
- **多维度评估**：从功能、质量、性能、安全等角度全面分析
- **智能错误处理**：自动识别和处理不同类型的AI服务错误

### 无缝集成体验

- **零配置启动**：一键安装脚本，快速上手
- **IDE 原生支持**：完美兼容 VS Code Git 工具
- **灵活配置**：支持项目级和全局级配置定制

### 智能 MR 管理

- **自动标题生成**：基于提交内容生成有意义的 MR 标题
- **智能描述创建**：自动总结变更内容和影响
- **分支策略适配**：自动检测目标分支和合并策略

## 🚀 故障排除

### 常见问题解决

**问题 1**: Git hooks路径错误

如果遇到 `错误：pre-push 脚本不存在` 错误：

```bash
# 快速修复（推荐）
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/fix-hooks.sh -o fix-hooks.sh
chmod +x fix-hooks.sh
./fix-hooks.sh

# 或重新设置项目
coderocket setup
```

详细解决方案请参考：[快速修复指南](QUICK_FIX.md)

**问题 2**: AI服务配置失败

```bash
# 检查当前AI服务状态
./lib/ai-service-manager.sh status

# 重新配置AI服务
./lib/ai-config.sh select

# Gemini 重新配置
gemini config --reset



# ClaudeCode 重新配置
claudecode config
```

**问题 3**: Hook 权限问题
```bash
# 解决方案：确保 hook 文件有执行权限
chmod +x .git/hooks/post-commit
chmod +x .git/hooks/pre-push
```

**问题 4**: 审查报告生成失败
```bash
# 解决方案：检查 review_logs 目录权限
mkdir -p review_logs
chmod 755 review_logs
```

**问题 5**: VS Code 中环境变量未加载
```bash
# 解决方案：重启 VS Code 或检查环境变量配置
echo $GITLAB_PERSONAL_ACCESS_TOKEN
```

**问题 6**: MR 创建失败
```bash
# 解决方案：检查 GitLab Token 权限
# 确保 Token 具有 api, read_repository, write_repository 权限
```

### 调试模式

启用详细日志输出：

```bash
# 设置调试环境变量
export DEBUG=1

# 手动测试 post-commit hook
./githooks/post-commit

# 手动测试 pre-push hook
./githooks/pre-push
```

---

## 🔄 版本更新

保持工具的最新状态：

```bash
# 重新运行安装脚本获取最新版本
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash

# 或者手动更新
cd ~/.coderocket
git pull origin main
```

---

**让 AI 成为您代码质量的守护者！** 🛡️✨
