# CodeRocket 更新日志

## [v1.0.2] - 2025-01-31

### 🎨 界面优化：Gemini CLI 风格的精美 Banner

#### ✨ 新功能
- **渐变 Banner 设计**：参考 Gemini CLI 的精美设计风格，使用 256 色渐变效果
- **响应式界面**：根据终端宽度自动选择合适的 ASCII art 显示
- **专业级视觉效果**：蓝绿渐变色彩，媲美 Gemini CLI 的高质量界面
- **多场景 Banner**：支持启动、安装、帮助等不同场景的 banner 显示

#### 🛠️ 技术改进
- 优化 banner 显示逻辑，支持多种终端环境
- 改进脚本加载机制，确保 banner 在所有命令中正确显示
- 统一所有命令的视觉风格和用户体验
- 增强终端兼容性，支持不同宽度的终端窗口

#### 💫 用户体验
- 启动时显示精美的渐变 banner，提升专业感
- 帮助和版本信息界面更加美观易读
- 安装脚本界面全面升级，视觉效果更佳
- 所有交互界面保持一致的设计风格

---

## [v1.0.1] - 2025-01-31

### 🎉 重大更新：项目重命名为 CodeRocket

#### ✨ 新功能
- **项目重命名**：CodeReview CLI 正式更名为 **CodeRocket**
- **多命令兼容性**：支持 `coderocket`、`codereview-cli`、`cr` 三个命令别名
- **精美 Banner**：添加了好看的 ASCII art banner，提升用户体验
- **智能命令检测**：根据当前使用的命令名称显示相应的帮助信息

#### 🔄 向后兼容
- 完全兼容原有的 `codereview-cli` 命令
- 支持简短别名 `cr` 命令
- 所有功能保持不变，用户无需修改使用习惯

#### 📝 文档更新
- 更新 README.md 文档，反映新的项目名称
- 更新安装脚本中的所有引用
- 更新 Git hooks 中的配置路径
- 更新所有帮助信息和错误提示

#### 🛠️ 技术改进
- 重构全局命令创建逻辑
- 优化 banner 显示系统
- 改进命令行界面的用户体验
- 统一配置文件路径（从 `~/.codereview-cli` 到 `~/.coderocket`）

#### 📦 安装更新
- 安装目录更改为 `~/.coderocket`
- 仓库地址更新为 `https://github.com/im47cn/coderocket`
- 保持一键安装脚本的便利性

### 🔧 使用说明

#### 新用户
```bash
# 一键安装
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket/main/install.sh | bash

# 使用任意命令
coderocket help
codereview-cli help  # 完全兼容
cr help              # 简短别名
```

#### 老用户
- 无需任何操作，原有命令继续有效
- 建议重新运行安装脚本获取最新功能
- 可以开始使用新的 `coderocket` 命令

---

## [v1.0.0] - 2025-01-30

### 🎯 初始版本
- AI 驱动的代码审查功能
- 支持 Git hooks 自动触发
- 集成 Google Gemini AI
- 支持 GitLab MR 自动创建
- 全局和项目级配置支持
