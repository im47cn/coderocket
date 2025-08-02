# CodeRocket CLI 卸载指南

## 🗑️ 完整卸载说明

CodeRocket CLI 提供了专业的卸载脚本，可以完全移除所有相关组件，确保系统恢复到安装前的状态。

## 🚀 快速卸载

### 方式一：一键卸载（推荐）

```bash
# 直接运行在线卸载脚本
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/uninstall.sh | bash
```

### 方式二：下载后运行

```bash
# 下载卸载脚本
wget https://raw.githubusercontent.com/im47cn/coderocket-cli/main/uninstall.sh
chmod +x uninstall.sh

# 查看将要删除的内容
./uninstall.sh

# 确认后执行卸载
```

### 方式三：使用本地脚本

```bash
# 如果已安装 CodeRocket CLI
bash ~/.coderocket/uninstall.sh
```

## ⚡ 强制卸载

如果需要跳过确认直接卸载：

```bash
# 强制卸载，不询问确认
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/uninstall.sh | bash -s -- --force

# 或使用本地脚本
./uninstall.sh --force
```

## 📋 卸载内容详情

卸载脚本将移除以下所有内容：

### 📁 安装目录
- `~/.coderocket/` - 主安装目录及所有文件
- 包含脚本、配置、文档等所有组件

### 🔧 全局命令
- `/usr/local/bin/coderocket` - 主命令
- `/usr/local/bin/codereview-cli` - 兼容命令
- `/usr/local/bin/cr` - 简短别名

### 👤 用户命令
- `~/.local/bin/coderocket` - 用户级主命令
- `~/.local/bin/codereview-cli` - 用户级兼容命令
- `~/.local/bin/cr` - 用户级简短别名

### ⚙️ Shell 配置
- 从 `.bashrc`/`.zshrc`/`.bash_profile` 中移除 PATH 配置
- 恢复安装前的配置文件备份（如果存在）
- 支持 bash、zsh、fish 等多种 shell

### 🔗 Git 模板和 Hooks
- `~/.git-templates/hooks/` - Git 全局模板 hooks
- 重置 Git 全局 `init.templatedir` 配置
- 可选扫描并清理项目中的 CodeRocket hooks

### 🧹 残留文件
- `~/.cache/coderocket` - 缓存文件
- `~/.local/share/coderocket` - 用户数据
- `/tmp/coderocket*` - 临时文件
- 旧版本兼容文件（如 `~/.codereview-cli`）

## 🔍 卸载预览

运行卸载脚本时，会首先显示检测到的所有组件：

```
╔══════════════════════════════════════════════════════════════╗
║                    CodeRocket CLI 卸载                      ║
║                                                              ║
║  ⚠️  警告：此操作将完全移除 CodeRocket CLI                   ║
║      包括所有配置、日志和 Git hooks                         ║
╚══════════════════════════════════════════════════════════════╝

即将卸载以下内容：

📁 安装目录：
  ✓ /Users/username/.coderocket

🔧 全局命令：
  ✓ /usr/local/bin/coderocket
  ✓ /usr/local/bin/codereview-cli
  ✓ /usr/local/bin/cr

👤 用户命令：
  ✓ /Users/username/.local/bin/coderocket

🔗 Git 模板：
  ✓ /Users/username/.git-templates

⚙️  Shell 配置：
  • 将从 shell 配置文件中移除 PATH 配置
  • 将恢复配置文件备份（如果存在）

⚠️  注意：此操作不可逆！
```

## 🛡️ 安全特性

### 备份机制
- 自动备份 shell 配置文件
- 保留原始配置文件备份
- 支持恢复到安装前状态

### 智能检测
- 准确识别所有已安装组件
- 区分 CodeRocket 和其他内容
- 避免误删非相关文件

### 用户确认
- 详细显示将要删除的内容
- 多重确认机制
- 支持强制模式跳过确认

### 项目扫描
- 可选扫描项目中的 Git hooks
- 用户选择是否清理项目 hooks
- 避免影响其他项目

## 📝 使用选项

### 帮助信息
```bash
./uninstall.sh --help
```

### 可用选项
- `--help, -h` - 显示帮助信息
- `--force` - 强制卸载，跳过确认

## ⚠️ 注意事项

1. **不可逆操作**：卸载操作无法撤销，请确认后再执行
2. **备份重要数据**：如有自定义配置，请提前备份
3. **项目影响**：会扫描并可选清理项目中的 Git hooks
4. **权限要求**：删除全局命令可能需要 sudo 权限
5. **Shell 重启**：卸载后需要重新打开终端或重新加载配置

## 🔄 重新安装

如需重新安装 CodeRocket CLI：

```bash
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket-cli/main/install.sh | bash
```

## 🆘 故障排除

### 权限问题
如果遇到权限错误：
```bash
# 使用 sudo 运行卸载脚本
sudo bash uninstall.sh
```

### 部分卸载失败
如果某些组件卸载失败，可以手动清理：
```bash
# 手动删除安装目录
rm -rf ~/.coderocket

# 手动删除全局命令
sudo rm -f /usr/local/bin/coderocket /usr/local/bin/codereview-cli /usr/local/bin/cr

# 手动清理 PATH 配置
# 编辑 ~/.bashrc 或 ~/.zshrc，删除相关行
```

### 配置恢复
如果需要恢复配置文件：
```bash
# 查找备份文件
ls ~/.bashrc.backup.* ~/.zshrc.backup.*

# 恢复备份
cp ~/.bashrc.backup.YYYYMMDD_HHMMSS ~/.bashrc
```

## 📞 支持

如果在卸载过程中遇到问题：

1. 查看错误信息和日志
2. 检查 [GitHub Issues](https://github.com/im47cn/coderocket-cli/issues)
3. 创建新的问题报告

---

**感谢使用 CodeRocket CLI！** 🚀
