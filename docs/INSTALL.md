# EnvSphere 安装指南

本指南将帮助您在不同平台上安装EnvSphere。

## 系统要求

### 操作系统
- **macOS**: 10.12 (Sierra) 或更高版本
- **Linux**: 大多数现代发行版 (Ubuntu 16.04+, CentOS 7+, Debian 9+)
- **Windows**: Windows 10 或更高版本

### Shell支持
- **Zsh**: 5.0 或更高版本
- **Bash**: 4.0 或更高版本
- **PowerShell**: 5.1 或更高版本 (Windows)
- **Fish**: 3.0 或更高版本
- **CMD**: Windows 命令提示符 (基础支持)

### 依赖项
- `curl` 或 `wget` (用于下载)
- `git` (可选，用于手动安装)

## 快速安装

### macOS/Linux

```bash
# 使用 curl
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash

# 或者使用 wget
wget -qO- https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash
```

### Windows

#### PowerShell (推荐)
```powershell
# 使用 Invoke-WebRequest
iwr -useb https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.ps1 | iex

# 或者使用 curl
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.ps1 | powershell -Command -
```

#### CMD (基础支持)
```cmd
# 下载安装脚本
curl -o install.bat https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.bat
install.bat
```

## 手动安装

### 1. 克隆仓库

```bash
git clone https://github.com/MisonL/EnvSphere.git
cd EnvSphere
```

### 2. 运行安装脚本

#### macOS/Linux
```bash
chmod +x install.sh
./install.sh
```

#### Windows
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

### 3. 验证安装

安装完成后，运行以下命令验证：

```bash
# Unix系统
envsphere --version

# Windows PowerShell
envsphere --version
```

## 高级安装选项

### 自定义安装路径

```bash
# 设置自定义安装路径
export ENVSphere_INSTALL_DIR="/opt/envsphere"
./install.sh

# Windows
$env:ENVSphere_INSTALL_DIR = "C:\Tools\EnvSphere"
.\install.ps1
```

### 静默安装

```bash
# 跳过交互式提示
./install.sh --quiet

# Windows
.\install.ps1 -Quiet
```

### 开发模式安装

```bash
# 安装开发依赖
./install.sh --dev

# 这将会安装额外的开发工具和文档
```

## 故障排除

### 权限问题

如果在安装过程中遇到权限错误：

```bash
# macOS/Linux - 使用 sudo (不推荐)
sudo ./install.sh

# 更好的做法是修复权限
sudo chown -R $USER:$USER ~/.envsphere
```

### PowerShell 执行策略

如果遇到执行策略错误：

```powershell
# 查看当前执行策略
Get-ExecutionPolicy

# 为当前用户设置执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 网络问题

如果下载失败，可以尝试：

```bash
# 使用代理
export https_proxy=http://your-proxy:port
./install.sh

# 或者手动下载
wget https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh
chmod +x install.sh
./install.sh
```

## 卸载

要卸载EnvSphere，运行：

```bash
# Unix系统
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/uninstall.sh | bash

# Windows
iwr -useb https://raw.githubusercontent.com/MisonL/EnvSphere/main/uninstall.ps1 | iex
```

或者手动运行卸载脚本：

```bash
# 从安装目录
~/.envsphere/uninstall.sh
```

## 更新

EnvSphere会自动检查更新。要手动更新：

```bash
# 更新到最新版本
envsphere update

# 或者重新安装最新版本
curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash
```

## 验证安装

安装完成后，可以通过以下方式验证：

1. **检查版本**
   ```bash
   envsphere --version
   ```

2. **列出配置文件**
   ```bash
   envsphere list
   ```

3. **测试功能**
   ```bash
   # 创建测试配置
   envsphere create test
   
   # 加载配置
   envsphere load test
   ```

4. **检查Shell集成**
   ```bash
   # 检查是否已添加到PATH
   which envsphere
   
   # 检查自动补全
   envsphere <TAB>
   ```

## 下一步

安装完成后，建议：

1. 运行 `envsphere-analyze` 分析当前环境变量
2. 使用 `envsphere-migrate` 迁移现有配置
3. 查看 [使用指南](../README.md#-使用指南) 了解更多功能

## 获取帮助

如果在安装过程中遇到问题：

1. 查看 [故障排除](../README.md#-故障排除) 部分
2. 在 [GitHub Issues](https://github.com/MisonL/EnvSphere/issues) 报告问题
3. 加入我们的 [Discord 社区](https://discord.gg/envsphere)