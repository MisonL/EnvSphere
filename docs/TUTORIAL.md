# EnvSphere 使用教程

## 🎯 快速开始（5分钟上手）

### 第一步：安装完成后

安装成功后，您会看到详细的安装成功信息。请按照提示操作：

```bash
# 重新加载 shell 配置
source ~/.zshrc  # 或 ~/.bashrc

# 或者简单地重新打开终端窗口
```

### 第二步：分析您的环境变量

```bash
# 分析当前环境变量
envsphere analyze

# 这将显示类似：
# 发现以下类型的环境变量：
#   API密钥               : 2 个变量
#   云服务                : 1 个变量
#   开发工具              : 5 个变量
#   ...
```

### 第三步：运行迁移向导（推荐）

```bash
# 启动交互式迁移向导
envsphere migrate

# 按照提示选择：
# 1) 开发环境配置 (推荐) - 自动迁移开发相关变量
# 2) API 密钥配置 - 创建API密钥模板
# 3) 自定义选择 - 手动选择要迁移的变量
# 4) 跳过迁移 - 稍后再处理
```

### 第四步：开始使用

```bash
# 查看可用配置
envsphere list

# 加载开发环境配置
envsphere load development

# 或者使用快捷方式
es ls      # 列出配置
es load dev # 加载开发配置
```

## 📚 详细功能介绍

### 1. 环境变量分析（envsphere analyze）

自动扫描您的 shell 配置文件，识别和分类环境变量：

- **API密钥**: GITHUB_TOKEN, OPENAI_API_KEY 等
- **云服务**: AWS_ACCESS_KEY_ID, AZURE_* 等
- **数据库**: DATABASE_URL, REDIS_URL 等
- **开发工具**: NODE_ENV, DEBUG 等
- **路径配置**: PATH, JAVA_HOME 等
- **语言区域**: LANG, LC_ALL 等

### 2. 交互式迁移向导（envsphere migrate）

提供用户友好的界面来选择要迁移的环境变量：

1. **自动分类** - 智能识别变量类型
2. **可视化选择** - 清晰地看到每个分类的变量
3. **安全迁移** - 备份原始配置，可随时回滚
4. **模板生成** - 自动生成配置文件模板

### 3. 配置管理

#### 查看配置
```bash
envsphere list          # 查看所有配置
envsphere list | grep dev  # 搜索包含 dev 的配置
```

#### 加载配置
```bash
envsphere load development    # 加载开发环境
envsphere load production     # 加载生产环境
envsphere load api-keys       # 加载API密钥
```

#### 创建配置
```bash
envsphere create myproject    # 创建名为 myproject 的配置
# 然后编辑生成的配置文件
vim ~/.envsphere/profiles/myproject.env
```

#### 卸载配置
```bash
# 从当前 shell 卸载配置（需要手动 unset 变量）
unset $(env | grep -E '^MY_VAR=' | cut -d= -f1)
```

### 4. 自动加载功能

在项目目录下创建 `.envsphere` 文件：

```bash
# 进入项目目录
cd ~/projects/myapp

# 创建自动加载文件
echo "myapp" > .envsphere

# 现在每次进入这个目录，EnvSphere 会自动加载 myapp 配置
```

## 🔧 高级用法

### 自定义环境变量分类

编辑分析器脚本的分类模式：

```bash
vim ~/.envsphere/scripts/env-analyzer.sh
```

### 批量操作

```bash
# 同时加载多个配置
envsphere load development && envsphere load api-keys

# 查看配置内容
envsphere show production
```

### 备份和恢复

```bash
# 配置文件会自动备份在 ~/.envsphere/backups/
ls ~/.envsphere/backups/

# 手动备份当前环境
env | sort > ~/my-env-backup.txt
```

### 与其他工具集成

#### 与 Git 工作流集成
```bash
# 为不同分支创建不同配置
git checkout feature-branch
envsphere create feature-branch-env
```

#### 与 CI/CD 集成
```bash
# 在 CI 脚本中使用
envsphere load ci-environment
```

## ⚠️ 重要提示

### 安全注意事项

1. **API密钥安全**
   - 不要将真实的API密钥提交到版本控制
   - 使用 `.gitignore` 忽略配置文件
   - 考虑使用加密存储敏感信息

2. **配置备份**
   ```bash
   # 定期备份您的配置
   cp -r ~/.envsphere/profiles ~/envsphere-backup
   ```

3. **权限问题**
   - 如果遇到权限错误，检查文件所有权
   - 使用 `ls -la ~/.envsphere/` 查看权限

### 故障排除

#### 问题：命令未找到
```bash
# 检查 PATH 设置
echo $PATH | grep envsphere

# 重新加载 shell 配置
source ~/.zshrc  # 或 ~/.bashrc
```

#### 问题：配置文件无法加载
```bash
# 检查文件权限
ls -la ~/.envsphere/profiles/

# 检查文件内容
head ~/.envsphere/profiles/your-config.env
```

#### 问题：分析器报错
```bash
# 确保使用 zsh 运行分析器
zsh ~/.envsphere/scripts/env-analyzer.sh

# 或者使用简化版本
envsphere analyze 2>/dev/null
```

## 📖 更多资源

- **完整文档**: https://github.com/MisonL/EnvSphere
- **示例项目**: https://github.com/MisonL/EnvSphere/tree/main/examples
- **常见问题**: https://github.com/MisonL/EnvSphere/issues

## 💬 获取帮助

- **报告问题**: https://github.com/MisonL/EnvSphere/issues
- **讨论区**: https://github.com/MisonL/EnvSphere/discussions
- **Discord 社区**: https://discord.gg/envsphere

---

🎉 **恭喜！您现在已经掌握了 EnvSphere 的所有功能。开始优雅地管理您的环境变量吧！**