<div align="center">

# 🌍 EnvSphere

> *简洁的环境变量管理器 - 复刻loadenv模式*

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/MisonL/EnvSphere)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

</div>

## ✨ 特性

- **🚀 智能安装** - 交互式确认，实施方案预览，同时支持非交互/CI 模式
- **🎯 简洁实用** - 复刻经典的 loadenv 使用模式
- **🐚 多Shell支持** - 支持 zsh、bash，兼容 macOS、主流 Linux 发行版及 WSL/Git Bash
- **⚡ 快速加载** - 瞬间切换环境变量配置
- **📝 模板驱动** - 内置 `env_loader.template` 与 `example-*.env` 示例，开箱即用
- **🔒 安全可控** - 交互式确认，用户完全掌控

## 📦 安装

### 一键安装（推荐）
```bash
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash
```

### 安全安装（推荐用于生产环境）
```bash
# 先下载并检查脚本内容
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh -o install.sh
cat install.sh  # 检查脚本内容
bash install.sh  # 执行安装
```

### 查看帮助信息
```bash
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash -s -- --help
```

### 手动安装
```bash
git clone https://github.com/MisonL/EnvSphere.git
cd EnvSphere
./install.sh
```

### 安装选项
```bash
./install.sh              # 交互式安装
./install.sh --force      # 非交互/CI 场景使用，跳过确认
./install.sh --help       # 显示帮助信息
```

> 📌 **CI / 非交互环境**：使用 `./install.sh --force` 或 `curl ... | bash -s -- --force`，脚本将自动使用检测到的配置文件路径完成集成。

## 🚀 快速开始

### 1. 重新加载shell
```bash
source ~/.zshrc  # 或 ~/.bashrc
```

### 2. 查看可用配置
```bash
loadenv --list
# 或
list-envs
```

### 3. 加载环境配置
```bash
loadenv development    # 加载开发环境
loadenv claude         # 加载Claude配置
```

## 📁 示例资源

项目内置以下模板资源，可直接复制或调整使用：

```
env_loader.template         # loadenv 函数模板
.env_profiles/
├── example-development.env # 开发环境示例
├── example-api-keys.env    # API 密钥占位示例
└── example-claude.env      # Claude Code 示例
```

> 安装脚本首次运行时会将 `example-*.env` 拷贝到 `~/.env_profiles/`，帮助快速上手。

## 📖 使用指南

### 基本命令
```bash
loadenv [profile]      # 加载指定环境配置
loadenv -l, --list      # 列出所有可用配置
loadenv -a, --all       # 加载所有配置
loadenv -h, --help      # 显示帮助信息
```

### 快捷Alias
```bash
alias loadenv='env_profile'
alias load-all-env='env_profile --all'
alias list-envs='env_profile --list'
```

## 🔧 环境变量管理操作指南

### 基本操作

#### 新增环境变量
```bash
# 编辑配置文件
vim ~/.env_profiles/development.env
export NEW_VAR="value"

# 或创建新配置
cat > ~/.env_profiles/myapp.env << 'EOF'
export API_KEY="your-key"
export DATABASE_URL="postgres://localhost/myapp"
EOF

# 加载配置
loadenv myapp
```

#### 修改环境变量
```bash
# 直接编辑文件
vim ~/.env_profiles/development.env
# 修改 export API_KEY="old-key" 为 export API_KEY="new-key"

# 或使用sed替换
sed -i 's/export API_KEY=".*"/export API_KEY="new-key"/' ~/.env_profiles/development.env
loadenv development
```

#### 删除环境变量
```bash
# 从文件中删除行
vim ~/.env_profiles/development.env
# 删除包含 export OLD_VAR="value" 的行

# 或使用sed删除
sed -i '/export OLD_VAR=".*"/d' ~/.env_profiles/development.env
loadenv development
```

### 实用示例

#### API密钥管理
```bash
# 创建API配置
cat > ~/.env_profiles/api-keys.env << 'EOF'
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
export OPENAI_API_KEY="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
EOF

# 加载并验证
loadenv api-keys
echo $GITHUB_TOKEN  # 验证加载成功

# 更新密钥
sed -i 's/export GITHUB_TOKEN=".*"/export GITHUB_TOKEN="ghp_newtokenxxxx"/' ~/.env_profiles/api-keys.env
loadenv api-keys
```

#### 项目环境切换
```bash
# 创建项目配置
cat > ~/.env_profiles/project-a.env << 'EOF'
export PROJECT_A_API_URL="https://api.project-a.com"
export PROJECT_A_DEBUG="true"
EOF

# 切换项目
loadenv project-a

# 添加新变量
echo 'export PROJECT_A_NEW_FEATURE="enabled"' >> ~/.env_profiles/project-a.env
loadenv project-a
```

## 💡 最佳实践

### 1. 配置分类
```bash
# 按用途分类
~/.env_profiles/
├── development/     # 开发环境
├── production/      # 生产环境
└── secrets/        # 敏感信息
```

### 2. 敏感信息处理
```bash
# 使用占位符，不要存储真实密钥
cat > ~/.env_profiles/api-keys.env << 'EOF'
# export GITHUB_TOKEN="your-github-token-here"
# export OPENAI_API_KEY="your-openai-api-key-here"
EOF
```

### 3. 快速操作
```bash
# 查看当前配置
echo $ENVSphere_ACTIVE_PROFILE

# 临时修改变量（不保存）
export TEMP_VAR="test-value"  # 只在当前会话有效

# 批量查看所有配置
for file in ~/.env_profiles/*.env; do echo "=== $(basename $file .env) ==="; cat "$file"; done
```

## 🔧 卸载

```bash
./uninstall.sh
```

> 卸载脚本会备份原 shell 配置，并询问是否保留 `~/.env_profiles`，重新安装时仍可复用模板。

## 📁 文件结构

```
EnvSphere项目/
├── install.sh              # 智能安装脚本
├── uninstall.sh            # 安全卸载脚本
├── env_loader.template     # 环境变量加载器模板
├── .env_profiles/          # 示例配置目录（example-*.env）
├── .github/workflows/      # CI 检查（bash -n、shellcheck、最小化安装测试）
├── README.md               # 本文档
└── LICENSE                 # MIT许可证

用户环境/
├── .env_loader              # 环境变量加载器（主程序）
├── .env_profiles/           # 配置文件目录
│   ├── development.env
│   ├── production.env
│   └── ...
└── .zshrc 或 .bashrc        # Shell配置文件（自动集成）
```

## 🤝 贡献

欢迎提交Issue和Pull Request！请查看 [贡献指南](CONTRIBUTING.md) 了解详细信息。

## 📋 更新日志

查看 [更新日志](CHANGELOG.md) 了解版本变化。

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE) 文件了解详情。