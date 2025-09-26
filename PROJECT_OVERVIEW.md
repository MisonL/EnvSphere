# EnvSphere 项目概览

## 项目结构

```
EnvSphere/
├── install.sh                    # Unix/Linux/macOS 安装脚本
├── install.ps1                   # Windows PowerShell 安装脚本
├── uninstall.sh                  # 卸载脚本
├── LICENSE                       # MIT 许可证
├── README.md                     # 项目主文档
├── .gitignore                    # Git 忽略文件
├── test-install.sh               # 安装测试脚本
├── docs/                         # 文档目录
│   ├── INSTALL.md               # 详细安装指南
│   └── EXAMPLES.md              # 使用示例和最佳实践
├── scripts/                      # 核心脚本
│   ├── env-analyzer.sh          # 环境变量分析器
│   ├── envsphere-core.sh        # 核心功能函数
│   ├── envsphere-core.ps1       # PowerShell 核心功能
│   └── interactive-cli.sh       # 交互式迁移向导
├── templates/                    # Shell 集成模板
│   ├── zsh-integration.sh       # Zsh 集成
│   ├── bash-integration.sh      # Bash 集成
│   ├── powershell-integration.ps1 # PowerShell 集成
│   └── cmd-integration.bat      # CMD 集成
└── profiles/                     # 示例配置文件
    ├── development.env          # 开发环境示例
    ├── production.env           # 生产环境示例
    └── api-keys.env            # API密钥模板
```

## 核心功能

1. **智能分析** (`env-analyzer.sh`)
   - 自动扫描当前环境变量
   - 按类别智能分组（API密钥、云服务、数据库等）
   - 识别敏感信息
   - 生成JSON格式的分析报告

2. **交互式迁移** (`interactive-cli.sh`)
   - 三步式迁移向导
   - 彩色界面，支持分类选择
   - 预览和确认机制
   - 多种迁移模式（询问/保留/删除）

3. **多平台支持**
   - macOS、Linux、Windows
   - zsh、bash、PowerShell、CMD
   - 自动检测和适配

4. **模块化配置**
   - 按项目或用途组织环境变量
   - 支持配置继承和覆盖
   - 版本化管理

## 安装方式

### 一键安装

```bash
# Unix/Linux/macOS
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash

# Windows PowerShell
iwr -useb https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.ps1 | iex
```

### 手动安装

```bash
git clone https://github.com/MisonL/EnvSphere.git
cd EnvSphere
./install.sh
```

## 使用流程

1. **分析环境变量**
   ```bash
   envsphere-analyze
   ```

2. **交互式迁移**
   ```bash
   envsphere-migrate
   ```

3. **管理配置**
   ```bash
   envsphere list          # 列出配置
   envsphere load dev      # 加载配置
   envsphere create prod   # 创建配置
   ```

## 技术特点

- **纯Shell实现** - 无外部依赖，轻量级
- **智能分类** - 12种预设分类，支持自定义
- **安全设计** - 自动备份，可回滚
- **扩展性强** - 模块化设计，易于扩展
- **用户友好** - 彩色输出，交互式界面

## 文件权限

```bash
chmod +x install.sh uninstall.sh test-install.sh
chmod +x scripts/*.sh
chmod 644 templates/* profiles/* docs/*
```

## 测试

运行测试脚本验证安装：
```bash
./test-install.sh
```

## 下一步

1. 上传到GitHub仓库
2. 创建Release版本
3. 完善文档和示例
4. 添加CI/CD流程
5. 收集用户反馈并迭代