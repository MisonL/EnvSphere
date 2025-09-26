# 🌍 EnvSphere

> *优雅的环境变量管理器 - 让开发环境如行星般有序旋转*

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/yourusername/EnvSphere)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)](docs/INSTALL.md)

[English](./README.md) | [中文](./docs/README.zh-CN.md)

## ✨ 特性

- **🚀 一键安装** - 一行命令完成安装和配置
- **🔍 智能分析** - 自动识别和分类环境变量
- **🎯 交互式迁移** - 可视化界面选择要管理的变量
- **🌐 多平台支持** - 支持 macOS、Linux、Windows
- **🐚 多终端兼容** - 支持 zsh、bash、PowerShell、CMD
- **🎨 优雅界面** - 彩色输出，友好的用户体验
- **🔄 安全备份** - 自动备份，随时可回滚
- **📦 模块化配置** - 按项目或用途组织环境变量

## 📦 安装

### 快速安装

**macOS/Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/EnvSphere/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/yourusername/EnvSphere/main/install.ps1 | iex
```

### 手动安装

1. 克隆仓库：
```bash
git clone https://github.com/yourusername/EnvSphere.git
cd EnvSphere
```

2. 运行安装脚本：
```bash
./install.sh
```

## 🚀 快速开始

### 1. 分析当前环境变量

安装完成后，首先分析您当前的环境变量：

```bash
envsphere-analyze
```

这将扫描您的shell配置文件，智能识别和分类环境变量。

### 2. 交互式迁移向导

运行交互式向导来选择要迁移的环境变量：

```bash
envsphere-migrate
```

向导将引导您：
- 选择要迁移的配置分类
- 选择具体的环境变量
- 配置迁移选项（保留/删除原配置）

### 3. 管理环境配置

基本命令：

```bash
# 列出所有配置
envsphere list

# 加载配置
envsphere load development

# 创建新配置
envsphere create production

# 快捷方式
es ls          # 列出配置
es load dev    # 加载开发配置
```

## 📖 使用指南

### 环境变量分类

EnvSphere会自动将环境变量分为以下类别：

| 分类 | 描述 | 示例 |
|------|------|------|
| 🔑 API密钥 | 各种API密钥和令牌 | `GITHUB_TOKEN`, `OPENAI_API_KEY` |
| ☁️ 云服务 | 云服务商配置 | `AWS_*`, `AZURE_*`, `GCP_*` |
| 🗄️ 数据库 | 数据库连接信息 | `DB_HOST`, `REDIS_URL` |
| 🛠️ 开发工具 | 开发环境配置 | `NODE_ENV`, `DEBUG` |
| 📁 路径配置 | 路径相关变量 | `PATH`, `JAVA_HOME` |
| 🌐 语言区域 | 语言和区域设置 | `LANG`, `LC_ALL` |
| 📝 编辑器 | 编辑器偏好 | `EDITOR`, `VISUAL` |
| 🐚 Shell | Shell配置 | `PS1`, `PROMPT` |

### 高级用法

#### 自动加载配置

在特定目录下创建 `.envsphere` 文件，内容是要加载的配置名称：

```bash
echo "project-specific" > .envsphere
```

当您进入该目录时，EnvSphere会自动加载对应的配置。

#### 配置模板

创建配置模板以便重复使用：

```bash
# 创建API密钥模板
envsphere create api-template
echo 'export API_KEY="your-key-here"' >> ~/.envsphere/profiles/api-template.env
```

#### 批量操作

```bash
# 加载多个配置
envsphere load development && envsphere load api-keys

# 查看配置内容
envsphere show production
```

## 🛠️ 配置

### Shell集成

EnvSphere会自动集成到您的shell配置中。您也可以手动添加：

**Zsh** (`~/.zshrc`):
```bash
# EnvSphere
export PATH="$HOME/.envsphere/bin:$PATH"
source "$HOME/.envsphere/scripts/zsh-integration.sh"
```

**Bash** (`~/.bashrc`):
```bash
# EnvSphere
export PATH="$HOME/.envsphere/bin:$PATH"
source "$HOME/.envsphere/scripts/bash-integration.sh"
```

**PowerShell** (`$PROFILE`):
```powershell
# EnvSphere
$env:PATH = "$env:USERPROFILE\.envsphere\bin;$env:PATH"
. "$env:USERPROFILE\.envsphere\scripts\powershell-integration.ps1"
```

### 环境变量

- `ENVSphere_DIR` - EnvSphere安装目录
- `ENVSphere_ACTIVE_PROFILE` - 当前激活的配置
- `ENVSphere_QUIET` - 设置为1以禁用欢迎消息

## 🔧 开发

### 项目结构

```
EnvSphere/
├── install.sh              # 安装脚本
├── uninstall.sh            # 卸载脚本
├── scripts/
│   ├── env-analyzer.sh     # 环境变量分析器
│   ├── interactive-cli.sh  # 交互式界面
│   └── envsphere-core.sh   # 核心功能
├── templates/              # Shell集成模板
├── profiles/               # 示例配置
└── docs/                   # 文档
```

### 构建和测试

```bash
# 运行测试
./tests/run-tests.sh

# 检查脚本语法
shellcheck scripts/*.sh

# 模拟安装
./install.sh --dry-run
```

## 📝 示例

### 开发环境配置

```bash
# 创建开发环境配置
cat > ~/.envsphere/profiles/development.env << EOF
# 开发环境
export NODE_ENV=development
export DEBUG=true
export API_BASE_URL=http://localhost:3000
export DATABASE_URL=postgres://localhost/dev_db
EOF

# 加载配置
envsphere load development
```

### 项目管理

```bash
# 为不同项目创建配置
envsphere create project-alpha
echo 'export PROJECT_ROOT="/path/to/project-alpha"' >> ~/.envsphere/profiles/project-alpha.env

# 在项目目录中创建自动加载文件
echo "project-alpha" > /path/to/project-alpha/.envsphere
```

## 🔍 故障排除

### 常见问题

**Q: 安装后命令未找到**
A: 重新加载shell配置：
```bash
source ~/.zshrc  # 或 ~/.bashrc
```

**Q: 权限错误**
A: 确保安装脚本有执行权限：
```bash
chmod +x install.sh
```

**Q: PowerShell中无法加载脚本**
A: 设置执行策略：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 🤝 贡献

欢迎贡献！请查看我们的[贡献指南](CONTRIBUTING.md)。

### 快速开始

1. Fork 仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开 Pull Request

## 🗺️ 路线图

- [ ] 支持更多shell（fish、tcsh）
- [ ] 加密敏感配置
- [ ] 云端同步配置
- [ ] 配置版本控制
- [ ] GUI管理界面
- [ ] 插件系统

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- 感谢所有贡献者
- 受 [nvm](https://github.com/nvm-sh/nvm) 和 [pyenv](https://github.com/pyenv/pyenv) 启发

## 📞 支持

- 📧 邮箱: support@envsphere.dev
- 💬 Discord: [加入我们的社区](https://discord.gg/envsphere)
- 🐛 报告问题: [GitHub Issues](https://github.com/yourusername/EnvSphere/issues)

---

<div align="center">

**[⬆ 回到顶部](#-envsphere)**

Made with ❤️ by the EnvSphere team

</div>