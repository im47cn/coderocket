# 📝 提示词文档配置指南

## 🎯 概述

CodeReview CLI 支持两种提示词配置方式：

1. **全局默认提示词**：使用系统内置的通用代码审查规则
2. **项目级自定义提示词**：为特定项目创建定制化的审查规则

## 🚀 安装时的选择

在运行安装脚本时，系统会询问：

```
是否需要创建项目级的代码审查提示词文档？
  - 选择 'y': 在当前项目创建 prompts/git-commit-review-prompt.md，可自定义审查规则
  - 选择 'n': 使用全局默认提示词，无需在项目中创建文件

创建项目级提示词文档? (y/N):
```

## 📋 选择建议

### 选择 'n' (推荐) - 使用全局默认提示词

**适用场景：**
- 大多数常规项目
- 不需要特殊审查规则的项目
- 希望保持项目目录干净的团队

**优点：**
- ✅ 项目目录保持干净，无额外文件
- ✅ 使用经过优化的通用审查规则
- ✅ 自动获得系统更新的审查规则
- ✅ 减少维护成本

**效果：**
```
项目目录结构：
my-project/
├── src/
├── .git/
├── .env.example
└── README.md
```

### 选择 'y' - 创建项目级提示词

**适用场景：**
- 有特殊代码规范要求的项目
- 需要针对特定技术栈优化审查的项目
- 企业级项目需要定制化审查规则

**优点：**
- ✅ 完全自定义的代码审查规则
- ✅ 可以针对项目特点优化
- ✅ 团队可以共享统一的审查标准

**效果：**
```
项目目录结构：
my-project/
├── src/
├── .git/
├── prompts/
│   └── git-commit-review-prompt.md
├── .env.example
└── README.md
```

## 🔧 后续修改

### 添加项目级提示词

如果最初选择了全局默认，后来想要自定义：

```bash
# 1. 创建prompts目录
mkdir -p prompts

# 2. 复制默认提示词模板
cp ~/.codereview-cli/prompts/git-commit-review-prompt.md prompts/

# 3. 编辑自定义规则
vim prompts/git-commit-review-prompt.md
```

### 移除项目级提示词

如果想要回到全局默认：

```bash
# 删除项目级提示词文档
rm -rf prompts/

# 系统会自动使用全局默认提示词
```

## 📚 提示词优先级

系统按以下优先级查找提示词：

1. **项目级提示词** (最高优先级)
   - `./prompts/git-commit-review-prompt.md`

2. **全局默认提示词** (备用)
   - `~/.codereview-cli/prompts/git-commit-review-prompt.md`

## 🎨 自定义提示词示例

如果选择创建项目级提示词，可以参考以下模板：

```markdown
# 项目代码审查提示词

## 项目特定要求

- 使用 TypeScript 严格模式
- 遵循 ESLint 配置规则
- 确保所有函数都有 JSDoc 注释

## 审查重点

1. **类型安全**：检查 TypeScript 类型定义
2. **性能优化**：关注 React 组件性能
3. **安全性**：检查 XSS 和 CSRF 防护
4. **测试覆盖**：确保关键逻辑有单元测试

## 输出格式

请按以下格式输出审查结果：
- 🎯 **主要改进点**
- ⚠️ **潜在问题**
- ✅ **优秀实践**
- 📝 **建议**
```

## 💡 最佳实践

1. **大多数项目选择全局默认**：除非有特殊需求，建议使用全局默认提示词
2. **团队统一标准**：如果团队决定使用项目级提示词，确保所有成员都了解规则
3. **定期更新**：项目级提示词需要手动维护，建议定期检查和更新
4. **版本控制**：项目级提示词应该纳入版本控制，与团队共享

## 🔍 故障排除

### 提示词文件不存在错误

如果遇到 "提示词文件不存在" 错误：

```bash
# 检查文件是否存在
ls -la prompts/git-commit-review-prompt.md
ls -la ~/.codereview-cli/prompts/git-commit-review-prompt.md

# 重新运行项目设置
codereview-cli setup
```

### 切换提示词模式

```bash
# 从项目级切换到全局默认
rm -rf prompts/

# 从全局默认切换到项目级
mkdir -p prompts
cp ~/.codereview-cli/prompts/git-commit-review-prompt.md prompts/
```
