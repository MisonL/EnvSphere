# EnvSphere 项目概览

## 项目简介

EnvSphere 是一个简洁的环境变量管理器，复刻了经典的 loadenv 使用模式。它允许用户轻松管理和切换不同环境下的环境变量配置，支持多种操作系统和 Shell 环境。

## 项目架构

### 核心组件

1. **安装脚本 (install.sh)**
   - 智能系统检测（支持 macOS、Linux、WSL、Windows）
   - 交互式安装流程
   - 自动创建必要的目录结构和配置文件
   - Shell 环境集成（zsh、bash）

2. **卸载脚本 (uninstall.sh)**
   - 安全移除所有安装的组件
   - 自动备份 Shell 配置文件
   - 可选择保留或删除配置文件

3. **环境加载器 (~/.env_loader)**
   - 核心功能函数 `env_profile()`
   - 支持加载、列出、管理环境配置
   - 提供便捷的别名命令

### 文件结构

```
EnvSphere/
├── install.sh          # 主安装脚本
├── uninstall.sh        # 卸载脚本
├── README.md           # 项目文档
├── CONTRIBUTING.md     # 贡献指南
├── CHANGELOG.md        # 更新日志
├── LICENSE             # MIT 许可证
└── .gitignore          # Git 忽略规则

用户环境/
├── .env_loader         # 环境变量加载器
├── .env_profiles/      # 配置文件目录
│   ├── development.env
│   ├── api-keys.env
│   └── claude.env
└── .zshrc/.bashrc      # Shell 配置（自动集成）
```

## 构建和运行

### 安装

```bash
# 一键安装
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash

# 安全安装（推荐）
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh -o install.sh
cat install.sh  # 检查内容
bash install.sh  # 执行安装

# 查看帮助
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash -s -- --help
```

### 使用

```bash
# 重新加载 Shell 配置
source ~/.zshrc  # 或 ~/.bashrc

# 列出可用配置
loadenv --list

# 加载指定环境
loadenv development
loadenv claude

# 加载所有配置
loadenv --all
```

### 卸载

```bash
# 运行卸载脚本
./uninstall.sh

# 查看卸载帮助
./uninstall.sh --help
```

## 开发约定

### 代码风格

- 使用 Bash 脚本编写，遵循 `set -euo pipefail` 安全模式
- 使用函数式编程结构，每个功能独立封装
- 彩色输出使用预定义的颜色常量
- 错误处理包含明确的错误信息和退出码

### 测试

```bash
# 语法检查
bash -n install.sh
bash -n uninstall.sh

# 功能测试
bash install.sh --help
bash uninstall.sh --help
```

### 贡献流程

1. Fork 项目仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 提交信息规范

```
类型: 简短描述

详细描述（可选）
```

类型包括：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

## 安全考虑

1. **安装安全**
   - 提供安全安装选项，建议先检查脚本内容
   - 权限检查和错误处理
   - 备份重要配置文件

2. **运行时安全**
   - 不使用 sudo 或危险命令
   - 所有操作都在用户目录下进行
   - 明确的确认步骤

## 支持的环境

### 操作系统
- macOS (Darwin)
- Linux (各发行版)
- Windows (WSL、Git Bash、MSYS2、Cygwin)

### Shell
- Zsh
- Bash
- 兼容大多数 POSIX 兼容 Shell

## 版本管理

项目遵循语义化版本 (SemVer)：
- 主版本号：不兼容的 API 修改
- 次版本号：向下兼容的功能性新增
- 修订号：向下兼容的问题修正

当前版本：1.0.0 (发布于 2025-10-05)

## 相关链接

- 项目主页: https://github.com/MisonL/EnvSphere
- 问题反馈: https://github.com/MisonL/EnvSphere/issues
- 文档: README.md
- 贡献指南: CONTRIBUTING.md
- 更新日志: CHANGELOG.md