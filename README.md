# CodeReview CLI

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub stars](https://img.shields.io/github/stars/im47cn/codereview-cli.svg)](https://github.com/im47cn/codereview-cli/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/im47cn/codereview-cli.svg)](https://github.com/im47cn/codereview-cli/issues)

一个基于 Google Gemini AI 的智能 Git 提交代码审查工具，通过 Git Hook 自动对每次提交进行全面的代码质量分析和审查。

## 🚀 核心功能

- **自动化代码审查**：每次 Git 提交后自动触发 AI 代码审查
- **全局代码搜索**：基于提交信息进行智能的全局代码搜索分析
- **多维度评估**：从功能完整性、代码质量、可维护性、扩展性等多个维度进行评估
- **智能状态标记**：使用 ✅ ⚠️ ❌ 🔍 等状态符号直观显示审查结果
- **详细审查报告**：生成结构化的 Markdown 审查报告，包含具体的改进建议
- **配置灵活性**：支持全局和项目级别的配置定制

## 📋 目录

- [技术栈](#技术栈)
- [环境要求](#环境要求)
- [安装指南](#安装指南)
- [使用说明](#使用说明)
- [配置说明](#配置说明)
- [审查报告](#审查报告)
- [贡献指南](#贡献指南)
- [许可证](#许可证)

## 🛠 技术栈

- **AI 引擎**: Google Gemini CLI
- **脚本语言**: Shell Script
- **版本控制**: Git Hooks (post-commit)
- **文档格式**: Markdown
- **配置管理**: 基于文件的配置系统

## 📋 环境要求

- **操作系统**: macOS, Linux, Windows (WSL)
- **Node.js**: >= 14.0.0
- **Git**: >= 2.0.0
- **Google Gemini CLI**: 最新版本
- **网络连接**: 需要访问 Google Gemini API

## 🔧 安装指南

### 1. 安装 Google Gemini CLI

```bash
npm install -g @google/gemini-cli
```

### 2. 配置 Gemini API

首次使用需要配置 Gemini API 密钥：

```bash
gemini config
```

按照提示输入您的 Google AI Studio API 密钥。

### 3. 克隆项目

```bash
git clone https://github.com/im47cn/codereview-cli.git
cd codereview-cli
```

### 4. 设置 Git Hook

在您的项目根目录中创建或编辑 `.git/hooks/post-commit` 文件：

```bash
#!/bin/sh
echo "🚀 正在执行 commit 后的代码审查..."
if cat "./prompts/git-commit-review-prompt.md" | gemini -p "请你现在按照指令开始执行最新提交的commit" -y; then
    echo "👌 代码审查完成"
else
    echo "❌ 代码审查失败，但不影响提交"
fi
```

### 5. 添加执行权限

```bash
chmod +x .git/hooks/post-commit
```

### 6. 复制配置文件

将 `prompts/git-commit-review-prompt.md` 复制到您的项目根目录：

```bash
cp prompts/git-commit-review-prompt.md ./prompts/
```

## 📖 使用说明

### 基本使用流程

1. **完成项目安装**：按照上述安装指南完成环境配置
2. **正常开发提交**：像往常一样进行代码开发和 Git 提交
3. **自动触发审查**：每次 `git commit` 后会自动触发代码审查
4. **查看审查报告**：审查完成后在 `review_logs/` 目录查看详细报告

### 示例工作流程

```bash
# 1. 修改代码
vim src/main.js

# 2. 添加到暂存区
git add src/main.js

# 3. 提交代码（会自动触发审查）
git commit -m "feat: 添加用户认证功能"

# 4. 查看审查报告
ls review_logs/
cat review_logs/20241201_1430_✅_6efa8d_添加用户认证功能.md
```

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

### 环境变量配置

可以通过环境变量进行额外配置：

```bash
# 设置审查报告输出目录
export REVIEW_LOGS_DIR="./custom_review_logs"

# 设置 Gemini 模型参数
export GEMINI_MODEL="gemini-pro"
```

## 📊 审查报告

### 报告文件命名规则

```
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

## 🤝 贡献指南

我们欢迎社区贡献！请遵循以下步骤：

### 开发环境设置

1. Fork 本仓库
2. 克隆您的 fork：
   ```bash
git clone https://github.com/YOUR_USERNAME/codereview-cli.git
```
3. 创建功能分支：
   ```bash
git checkout -b feature/your-feature-name
```

### 提交规范

请使用以下提交信息格式：

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**类型**：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

### Pull Request 流程

1. 确保代码通过所有测试
2. 更新相关文档
3. 提交 Pull Request
4. 等待代码审查和合并

### 代码规范

- 遵循项目现有的代码风格
- 添加适当的注释和文档
- 确保向后兼容性
- 编写测试用例（如适用）

## 📄 许可证

本项目采用 [Apache License 2.0](LICENSE) 许可证。

```
Copyright 2024 im47cn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## 🔗 相关链接

- [Google Gemini CLI 文档](https://github.com/google/generative-ai-js)
- [Git Hooks 官方文档](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [项目问题反馈](https://github.com/im47cn/codereview-cli/issues)
- [功能请求](https://github.com/im47cn/codereview-cli/issues/new?template=feature_request.md)

## 📞 支持与反馈

如果您在使用过程中遇到问题或有改进建议，请：

1. 查看 [常见问题](https://github.com/im47cn/codereview-cli/wiki/FAQ)
2. 搜索 [现有问题](https://github.com/im47cn/codereview-cli/issues)
3. 创建 [新问题](https://github.com/im47cn/codereview-cli/issues/new)

## 🚀 快速开始

### 一键安装脚本

为了简化安装过程，我们提供了一键安装脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/install.sh | bash
```

### Docker 支持

如果您偏好使用 Docker：

```bash
docker run -v $(pwd):/workspace im47cn/codereview-cli
```

### 常见问题解决

**问题 1**: Gemini API 配置失败
```bash
# 解决方案：重新配置 API 密钥
gemini config --reset
```

**问题 2**: Hook 权限问题
```bash
# 解决方案：确保 hook 文件有执行权限
chmod +x .git/hooks/post-commit
```

**问题 3**: 审查报告生成失败
```bash
# 解决方案：检查 review_logs 目录权限
mkdir -p review_logs
chmod 755 review_logs
```

---

**让 AI 成为您代码质量的守护者！** 🛡️✨