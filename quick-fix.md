# 🔧 快速修复全局命令语法错误

## 问题描述
全局命令 `cr`、`codereview-cli`、`coderocket` 中有语法错误：
```
/usr/local/bin/cr: line 46: syntax error near unexpected token `('
/usr/local/bin/cr: line 46: `OLD_VERSION=\\\$(cat "\$INSTALL_DIR/VERSION")'
```

## 🚀 解决方案

### 方案1：使用本地命令（推荐）
直接使用项目目录中的命令，它们工作正常：
```bash
# 进入项目目录
cd /path/to/codereview-cli

# 使用本地命令
bash bin/coderocket help
bash bin/coderocket version
bash bin/coderocket setup    # 为其他项目设置
```

### 方案2：手动修复全局命令
如果你有管理员权限，可以手动修复：

```bash
# 修复 cr 命令
sudo sed -i '' 's/OLD_VERSION=\\\\\\$(cat/OLD_VERSION=\\$(cat/g' /usr/local/bin/cr
sudo sed -i '' 's/NEW_VERSION=\\\\\\$(cat/NEW_VERSION=\\$(cat/g' /usr/local/bin/cr

# 修复 codereview-cli 命令
sudo sed -i '' 's/OLD_VERSION=\\\\\\$(cat/OLD_VERSION=\\$(cat/g' /usr/local/bin/codereview-cli
sudo sed -i '' 's/NEW_VERSION=\\\\\\$(cat/NEW_VERSION=\\$(cat/g' /usr/local/bin/codereview-cli

# 修复 coderocket 命令
sudo sed -i '' 's/OLD_VERSION=\\\\\\$(cat/OLD_VERSION=\\$(cat/g' /usr/local/bin/coderocket
sudo sed -i '' 's/NEW_VERSION=\\\\\\$(cat/NEW_VERSION=\\$(cat/g' /usr/local/bin/coderocket
```

### 方案3：重新安装（最彻底）
```bash
# 删除旧的全局命令
sudo rm -f /usr/local/bin/coderocket /usr/local/bin/codereview-cli /usr/local/bin/cr

# 重新运行安装脚本
curl -fsSL https://raw.githubusercontent.com/im47cn/coderocket/main/install.sh | bash
```

## ✅ 验证修复
修复后测试命令：
```bash
cr help
codereview-cli help
coderocket help
```

## 💡 临时解决方案
如果暂时无法修复全局命令，可以创建别名：
```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
alias cr='bash /path/to/codereview-cli/bin/coderocket'
alias codereview-cli='bash /path/to/codereview-cli/bin/coderocket'
alias coderocket='bash /path/to/codereview-cli/bin/coderocket'
```

## 🎯 推荐做法
目前本地的 `bin/coderocket` 脚本工作完美，建议：
1. 使用 `bash bin/coderocket` 进行日常操作
2. 有时间时使用方案2或3修复全局命令
3. 新项目可以运行 `bash bin/coderocket setup` 来设置
