# 贡献指南

感谢您对 CodeRocket CLI 项目的关注！我们欢迎各种形式的贡献。

## 🤝 如何贡献

### 报告问题

如果您发现了 bug 或有功能建议，请：

1. 检查 [Issues](https://github.com/im47cn/coderocket-cli/issues) 确认问题未被报告
2. 创建新的 Issue，包含：
   - 详细的问题描述
   - 复现步骤
   - 期望的行为
   - 实际的行为
   - 环境信息（操作系统、Node.js版本等）

### 提交代码

1. **Fork 项目**
   ```bash
   git clone https://github.com/your-username/coderocket-cli.git
   cd coderocket-cli
   ```

2. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **进行开发**
   - 遵循现有的代码风格
   - 添加必要的测试
   - 更新相关文档

4. **测试您的更改**
   ```bash
   # 运行测试套件
   ./test-ai-services.sh
   
   # 测试安装流程
   ./install.sh
   ```

5. **提交更改**
   ```bash
   git add .
   git commit -m "feat: 添加新功能描述"
   ```

6. **推送并创建 Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

## 📝 代码规范

### Shell 脚本规范

1. **文件头部**
   ```bash
   #!/bin/bash
   
   # 脚本描述
   # 作者信息和日期
   ```

2. **变量命名**
   - 使用大写字母和下划线：`GITLAB_API_URL`
   - 局部变量使用小写：`local api_key`

3. **函数规范**
   ```bash
   # 函数描述
   function_name() {
       local param1=$1
       local param2=$2
       
       # 函数实现
   }
   ```

4. **错误处理**
   ```bash
   if ! command -v tool &> /dev/null; then
       echo -e "${RED}❌ 工具未安装${NC}"
       return 1
   fi
   ```

### 提交信息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

- `feat:` 新功能
- `fix:` 修复bug
- `docs:` 文档更新
- `style:` 代码格式调整
- `refactor:` 代码重构
- `test:` 测试相关
- `chore:` 构建过程或辅助工具的变动

示例：
```
feat: 添加对ClaudeCode的支持
fix: 修复API密钥验证问题
docs: 更新安装指南
```

## 🧪 测试指南

### 运行测试

```bash
# 完整测试套件
./test-ai-services.sh

# 特定功能测试
./lib/ai-service-manager.sh test
./lib/ai-config.sh validate
```

### 添加新测试

在 `test-ai-services.sh` 中添加测试用例：

```bash
run_test "测试描述" "测试命令" [期望退出码]
```

### 测试覆盖范围

确保新功能包含以下测试：
- 功能正常流程测试
- 错误处理测试
- 边界条件测试
- 集成测试

## 📚 文档贡献

### 文档结构

- `README.md` - 主要文档
- `docs/AI_SERVICES_GUIDE.md` - AI服务使用指南
- `CONTRIBUTING.md` - 本贡献指南
- `CHANGELOG.md` - 变更日志

### 文档规范

1. 使用清晰的标题层级
2. 提供代码示例
3. 包含必要的截图或图表
4. 保持中英文混排的一致性

## 🔧 开发环境设置

### 必需工具

- Bash 4.0+
- Git 2.0+
- Node.js 14+ (用于AI CLI工具)
- Python 3.6+ (用于JSON处理)

### 推荐工具

- [ShellCheck](https://www.shellcheck.net/) - Shell脚本静态分析
- [Prettier](https://prettier.io/) - 代码格式化
- [VS Code](https://code.visualstudio.com/) - 推荐编辑器

### 开发流程

1. 设置开发环境
2. 运行现有测试确保环境正常
3. 开发新功能
4. 添加测试
5. 更新文档
6. 提交代码

## 🚀 发布流程

### 版本号规范

使用 [Semantic Versioning](https://semver.org/)：
- `MAJOR.MINOR.PATCH`
- 主版本号：不兼容的API修改
- 次版本号：向下兼容的功能性新增
- 修订号：向下兼容的问题修正

### 发布检查清单

- [ ] 所有测试通过
- [ ] 文档已更新
- [ ] CHANGELOG.md 已更新
- [ ] 版本号已更新
- [ ] 创建 Git 标签

## 💡 开发建议

### 最佳实践

1. **小步提交**：每个提交只包含一个逻辑变更
2. **测试驱动**：先写测试，再实现功能
3. **文档同步**：代码变更时同步更新文档
4. **向后兼容**：尽量保持向后兼容性

### 常见问题

**Q: 如何调试Shell脚本？**
A: 使用 `set -x` 启用调试模式，或设置 `DEBUG=true` 环境变量。

**Q: 如何测试不同的AI服务？**
A: 使用 `./lib/ai-config.sh select` 切换服务，然后运行相应测试。

**Q: 如何处理跨平台兼容性？**
A: 使用POSIX兼容的命令，避免GNU特定的选项。

## 📞 联系方式

- GitHub Issues: [项目Issues页面](https://github.com/im47cn/coderocket-cli/issues)
- 邮件: [项目维护者邮箱]
- 讨论: [GitHub Discussions](https://github.com/im47cn/coderocket-cli/discussions)

## 📄 许可证

通过贡献代码，您同意您的贡献将在与项目相同的许可证下发布。

---

再次感谢您的贡献！每一个贡献都让这个项目变得更好。
