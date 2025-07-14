# VS Code Git Hooks 测试指南

## 🧪 测试 Post-Commit Hook

### 步骤 1：准备测试

1. 确保你在 VS Code 中打开了这个项目
2. 确保调试日志已清理（已完成）

### 步骤 2：在 VS Code 中进行测试

1. **创建测试文件**：
   - 在 VS Code 中创建一个新文件，例如 `vscode-test.txt`
   - 添加一些内容，例如：`This is a VS Code test`

2. **使用 VS Code Git 面板提交**：
   - 打开 VS Code 的源代码管理面板（Ctrl+Shift+G）
   - 暂存新文件
   - 输入提交信息：`test: VS Code post-commit hook 测试`
   - 点击提交按钮

3. **观察结果**：
   - 提交后，观察 VS Code 的终端输出
   - 应该看到：`🚀 正在执行 commit 后的代码审查...`
   - 等待几秒钟，直到看到：`👌 代码审查完成`

### 步骤 3：验证结果

1. **检查调试日志**：
   ```bash
   cat ~/.codereview-cli-debug.log
   ```

2. **检查审查报告**：
   - 查看 `review_logs/` 目录
   - 应该有新的审查报告文件

### 步骤 4：如果没有触发

如果在 VS Code 中没有看到 hook 执行，请尝试：

1. **检查 VS Code Git 设置**：
   - 打开 VS Code 设置（Cmd+,）
   - 搜索 "git.path"
   - 确保使用系统 Git：`/usr/bin/git`

2. **重启 VS Code**：
   - 完全关闭 VS Code
   - 重新打开项目

3. **检查终端集成**：
   - 在 VS Code 中打开集成终端
   - 运行：`which git`
   - 确保路径是 `/usr/bin/git`

## 🧪 测试 Pre-Push Hook

### 在 VS Code 中测试推送

1. **确保有未推送的提交**
2. **使用 VS Code 推送**：
   - 在源代码管理面板中
   - 点击 "..." 菜单
   - 选择 "推送到..." 
   - 选择 `yeepay` remote
3. **观察结果**：
   - 应该看到：`=== GitLab MR 自动创建 ===`
   - 会询问是否创建 MR

## 🔧 故障排除

### 如果 VS Code 中仍然不工作

1. **检查 Git 配置**：
   ```bash
   git config --global core.hooksPath
   ```
   应该为空或不存在

2. **检查 VS Code Git 扩展**：
   - 禁用所有第三方 Git 扩展
   - 只使用内置的 Git 支持

3. **使用 VS Code 集成终端**：
   - 在 VS Code 的集成终端中运行 git 命令
   - 看是否能触发 hooks

4. **检查权限**：
   ```bash
   ls -la .git/hooks/post-commit
   ls -la .git/hooks/pre-push
   ```

## 📝 报告问题

如果测试失败，请提供：

1. 调试日志内容：`cat ~/.codereview-cli-debug.log`
2. VS Code 版本：Help > About
3. Git 版本：`git --version`
4. 操作系统版本
5. 具体的错误信息或现象

## 💡 已知问题

1. **某些 VS Code 版本**可能不会触发 Git hooks
2. **第三方 Git 扩展**可能会干扰 hooks 执行
3. **权限问题**可能导致 hooks 无法执行

## ✅ 成功标志

测试成功的标志：
- [ ] 在 VS Code 中提交后看到代码审查提示
- [ ] 生成了新的审查报告文件
- [ ] 调试日志记录了 hook 执行过程
- [ ] 推送到 GitLab 时出现 MR 创建提示
