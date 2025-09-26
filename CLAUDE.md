# CLAUDE.md

此文件为 Claude Code (claude.ai/code) 提供在本代码仓库中工作的指导。

## 项目概述

EnvSphere 是一个跨平台环境变量管理工具，提供智能分析、交互式迁移和模块化配置管理功能。支持 macOS、Linux 和 Windows 系统，兼容 zsh、bash、PowerShell 和 CMD 终端。

## 架构设计

### 核心组件

1. **安装系统**
   - `install.sh` - Unix/Linux/macOS 安装器，检测系统/终端类型并配置环境
   - `install.ps1` - Windows PowerShell 安装器
   - 创建 `~/.envsphere/` 目录结构，包含 bin/、scripts/、templates/ 和 profiles/ 子目录

2. **分析引擎**
   - `scripts/env-analyzer.sh` - 扫描 shell 配置文件，使用正则模式分类环境变量
   - 将分析结果存储在 `~/.envsphere/analysis/current_env_analysis.json`
   - 分类包括：api_keys、cloud_services、databases、development、paths、languages、editors、shell、system、display、proxy、colors

3. **交互式 CLI**
   - `scripts/interactive-cli.sh` - 提供菜单驱动的迁移界面
   - 允许用户选择要迁移的变量，以及保留/删除原始配置
   - 创建 JSON 格式的迁移计划

4. **终端集成**
   - `templates/` 目录包含各终端类型的集成模板
   - 将 envsphere 命令添加到 PATH 并引用集成脚本
   - 支持命令：`envsphere list`、`envsphere load <配置>`、`envsphere create <配置>`

## 开发命令

```bash
# 检查 shell 脚本语法
shellcheck scripts/*.sh

# 本地测试安装
./test-install.sh

# 模拟安装（不实际修改系统）
./install.sh --dry-run

# 手动运行分析器
./scripts/env-analyzer.sh

# 运行交互式迁移向导
./scripts/interactive-cli.sh
```

## 关键实现细节

1. **多终端支持**：项目使用不同的集成策略：
   - Unix 终端：修改 .zshrc/.bashrc 以引用集成脚本
   - PowerShell：修改 $PROFILE 以导入模块
   - CMD：在 PATH 中创建批处理文件

2. **配置管理**：环境变量以 `.env` 文件形式存储在 `~/.envsphere/profiles/`
   - 每个配置是一个导出变量的 shell 脚本
   - 支持动态加载/卸载配置
   - 通过目录中的 `.envsphere` 文件支持自动加载

3. **安全特性**：
   - 修改前始终备份现有终端配置
   - 使用 `set -euo pipefail` 进行严格的错误处理
   - 在交互模式中验证用户输入
   - 提供卸载脚本以干净移除

4. **跨平台考虑**：
   - Unix 和 Windows 之间的路径处理不同
   - 各平台的终端检测逻辑不同
   - 颜色输出代码在各平台保持一致
   - 使用各操作系统适当的配置文件位置