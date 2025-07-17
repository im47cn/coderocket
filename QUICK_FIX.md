# 🚑 CodeReview CLI 快速修复指南

## 问题描述

如果您遇到以下错误：
```
错误：pre-push 脚本不存在: /path/to/project/githooks/pre-push
error: failed to push some refs
```

这是因为Git hooks无法找到正确的脚本路径。

## 🔧 快速修复方法

### 方法一：使用修复脚本（推荐）

1. **下载修复脚本**：
   ```bash
   curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/fix-hooks.sh -o fix-hooks.sh
   chmod +x fix-hooks.sh
   ```

2. **在项目目录中运行修复脚本**：
   ```bash
   cd /path/to/your/project
   ./fix-hooks.sh
   ```

3. **验证修复**：
   ```bash
   git push
   ```

### 方法二：手动修复

1. **检查全局安装**：
   ```bash
   ls -la ~/.codereview-cli/
   ```
   
   如果目录不存在，请重新安装：
   ```bash
   curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/install.sh | bash
   ```

2. **重新设置项目hooks**：
   ```bash
   cd /path/to/your/project
   codereview-cli setup
   ```

3. **如果codereview-cli命令不存在**：
   ```bash
   ~/.codereview-cli/install-hooks.sh
   ```

### 方法三：临时绕过（不推荐）

如果您急需推送代码，可以临时跳过hooks：
```bash
git push --no-verify
```

**注意**：这会跳过代码审查和MR自动创建功能。

## 🔍 问题排查

### 检查安装状态

```bash
# 检查全局安装
ls -la ~/.codereview-cli/

# 检查项目hooks
ls -la .git/hooks/

# 检查hooks内容
cat .git/hooks/pre-push
```

### 常见问题

1. **全局安装不完整**
   - 解决：重新运行安装脚本
   ```bash
   curl -fsSL https://raw.githubusercontent.com/im47cn/codereview-cli/main/install.sh | bash
   ```

2. **权限问题**
   - 解决：确保hooks有执行权限
   ```bash
   chmod +x .git/hooks/post-commit
   chmod +x .git/hooks/pre-push
   ```

3. **路径问题**
   - 解决：使用修复脚本更新hooks内容

## 📞 获取帮助

如果问题仍然存在：

1. **查看详细错误信息**：
   ```bash
   git push -v
   ```

2. **检查环境变量**：
   ```bash
   echo $GITLAB_PERSONAL_ACCESS_TOKEN
   ```

3. **测试AI服务**：
   ```bash
   ~/.codereview-cli/lib/ai-service-manager.sh status
   ```

4. **创建Issue**：
   - 访问：https://github.com/im47cn/codereview-cli/issues
   - 包含错误信息和环境详情

## 🎯 预防措施

为避免类似问题：

1. **使用全局安装模式**（推荐）
2. **定期更新**：
   ```bash
   codereview-cli update
   ```
3. **验证安装**：
   ```bash
   codereview-cli setup
   ```

---

**快速链接**：
- [主文档](README.md)
- [AI服务指南](docs/AI_SERVICES_GUIDE.md)
- [贡献指南](CONTRIBUTING.md)
