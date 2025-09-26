# EnvSphere Windows 安装脚本
# PowerShell 版本

# 要求 PowerShell 5.1 或更高版本
#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# 配置
$EnvSphereVersion = "1.0.0"
$EnvSphereDir = Join-Path $HOME ".envsphere"
$EnvSphereBinDir = Join-Path $EnvSphereDir "bin"
$EnvSphereProfilesDir = Join-Path $EnvSphereDir "profiles"
$EnvSphereBackupDir = Join-Path $EnvSphereDir "backups"

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$ForegroundColor,
        [string]$Message
    )
    $colors = @{
        "Red" = "Red"
        "Green" = "Green"
        "Yellow" = "Yellow"
        "Blue" = "Blue"
        "Cyan" = "Cyan"
        "Gray" = "Gray"
    }
    Write-Host $Message -ForegroundColor $colors[$ForegroundColor]
}

# 检测管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 创建目录结构
function New-EnvSphereDirectory {
    Write-ColorOutput "Blue" "正在创建EnvSphere目录结构..."
    
    $directories = @($EnvSphereDir, $EnvSphereBinDir, $EnvSphereProfilesDir, $EnvSphereBackupDir)
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    # 创建版本文件
    $EnvSphereVersion | Out-File -FilePath (Join-Path $EnvSphereDir ".version") -Encoding UTF8
    
    Write-ColorOutput "Green" "✓ 目录结构创建完成"
}

# 安装核心脚本
function Install-EnvSphereCore {
    Write-ColorOutput "Blue" "正在安装EnvSphere核心脚本..."
    
    # 创建envsphere.ps1
    $envsphereScript = @'
# EnvSphere PowerShell 核心脚本
param(
    [Parameter(Position=0)]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$Argument
)

$EnvSphereDir = $env:USERPROFILE + "\.envsphere"
$ProfilesDir = Join-Path $EnvSphereDir "profiles"

function Load-EnvSphereProfile {
    param([string]$ProfileName)
    
    $profileFile = Join-Path $ProfilesDir "$ProfileName.env"
    if (Test-Path $profileFile) {
        Write-Host "正在加载环境配置: $ProfileName" -ForegroundColor Green
        
        # 读取并执行配置文件
        Get-Content $profileFile | ForEach-Object {
            if ($_ -match '^\s*export\s+([^=]+)=(.+)') {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim().Trim('"', "'")
                Set-Item -Path "env:$name" -Value $value
            }
        }
        
        $env:ENVSphere_ACTIVE_PROFILE = $ProfileName
        Write-Host "✓ 配置加载成功" -ForegroundColor Green
    } else {
        Write-Error "错误: 找不到配置文件 $profileFile"
        exit 1
    }
}

function Get-EnvSphereProfiles {
    if (Test-Path $ProfilesDir) {
        Get-ChildItem -Path $ProfilesDir -Filter "*.env" | ForEach-Object {
            $_.BaseName
        }
    }
}

function New-EnvSphereProfile {
    param([string]$ProfileName)
    
    $profileFile = Join-Path $ProfilesDir "$ProfileName.env"
    
    if (Test-Path $profileFile) {
        Write-Warning "配置文件已存在: $profileFile"
        $confirm = Read-Host "覆盖吗? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            return
        }
    }
    
    @"
# EnvSphere Profile: $ProfileName
# 创建于: $(Get-Date)

# 在此添加环境变量
# export VARIABLE_NAME="value"

"@ | Out-File -FilePath $profileFile -Encoding UTF8
    
    Write-Host "✓ 配置文件已创建: $profileFile" -ForegroundColor Green
    Write-Host "请编辑该文件并添加您的环境变量"
}

# 主命令处理
switch ($Command) {
    "load" {
        if (-not $Argument) {
            Write-Error "用法: envsphere load <profile>"
            exit 1
        }
        Load-EnvSphereProfile $Argument
    }
    { $_ -in "list", "ls" } {
        $profiles = Get-EnvSphereProfiles
        if ($profiles) {
            Write-Host "可用的环境配置:"
            $profiles | ForEach-Object { Write-Host "  - $_" }
        } else {
            Write-Host "没有找到配置文件"
        }
    }
    { $_ -in "create", "new" } {
        if (-not $Argument) {
            Write-Error "用法: envsphere create <profile>"
            exit 1
        }
        New-EnvSphereProfile $Argument
    }
    default {
        Write-Host @"
EnvSphere - 优雅的环境变量管理器

用法:
  envsphere load <profile>    加载环境配置
  envsphere list              列出所有配置
  envsphere create <name>     创建新配置

更多信息: https://github.com/yourusername/EnvSphere
"@
    }
}
'@
    
    # 保存脚本
    $envsphereScript | Out-File -FilePath (Join-Path $EnvSphereBinDir "envsphere.ps1") -Encoding UTF8
    
    Write-ColorOutput "Green" "✓ 核心脚本安装完成"
}

# 安装PowerShell集成
function Install-PowerShellIntegration {
    Write-ColorOutput "Blue" "正在安装PowerShell集成..."
    
    # 获取PowerShell配置文件路径
    $profilePath = $PROFILE
    
    if (-not (Test-Path $profilePath)) {
        # 创建配置文件
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }
    
    # 检查是否已集成
    if (Select-String -Path $profilePath -Pattern "EnvSphere" -Quiet) {
        Write-ColorOutput "Yellow" "EnvSphere 已存在于PowerShell配置中，跳过集成"
        return
    }
    
    # 备份原配置文件
    $backupPath = Join-Path $EnvSphereBackupDir "powershell_profile.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -Path $profilePath -Destination $backupPath -Force
    
    # 添加EnvSphere集成
    $integration = @"

# EnvSphere - 环境变量管理器
# 添加EnvSphere到PATH
`$env:PATH = "`$env:USERPROFILE\.envsphere\bin;`$env:PATH"

# 加载EnvSphere函数
if (Test-Path "`$env:USERPROFILE\.envsphere\scripts\powershell-integration.ps1") {
    . "`$env:USERPROFILE\.envsphere\scripts\powershell-integration.ps1"
}

"@
    
    Add-Content -Path $profilePath -Value $integration -Encoding UTF8
    
    Write-ColorOutput "Green" "✓ PowerShell集成完成"
}

# 创建示例配置
function New-EnvSphereExamples {
    Write-ColorOutput "Blue" "正在创建示例配置文件..."
    
    # 创建开发环境示例
    @"
# EnvSphere 示例配置
# 开发环境配置

# Node.js 开发环境
export NODE_ENV="development"
export DEBUG="app:*"
export PORT="3000"

# 日志级别
export LOG_LEVEL="debug"

# API 基础地址
export API_BASE_URL="http://localhost:3000/api"
"@ | Out-File -FilePath (Join-Path $EnvSphereProfilesDir "development.env") -Encoding UTF8
    
    Write-ColorOutput "Green" "✓ 示例配置文件创建完成"
}

# 主安装流程
function Main {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              EnvSphere Installer (Windows)           ║" -ForegroundColor Cyan
    Write-Host "║          优雅的环境变量管理器 v$EnvSphereVersion              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # 显示系统信息
    $osInfo = Get-CimInstance Win32_OperatingSystem
    Write-Host "系统信息:" -ForegroundColor Cyan
    Write-Host "  操作系统: Windows $($osInfo.Caption)"
    Write-Host "  架构: $($env:PROCESSOR_ARCHITECTURE)"
    Write-Host "  PowerShell版本: $($PSVersionTable.PSVersion)"
    Write-Host ""
    
    # 检查管理员权限
    if (Test-Administrator) {
        Write-ColorOutput "Yellow" "⚠️  检测到管理员权限，EnvSphere通常不需要管理员权限"
    }
    
    # 执行安装步骤
    New-EnvSphereDirectory
    Install-EnvSphereCore
    Install-PowerShellIntegration
    New-EnvSphereExamples
    
    # 完成提示
    Write-Host ""
    Write-Host "🎉 EnvSphere 安装成功！" -ForegroundColor Green -NoNewline
    Write-Host ""
    Write-Host ""
    Write-Host "使用方法:" -ForegroundColor Cyan
    Write-Host "  envsphere list              # 查看可用配置"
    Write-Host "  envsphere load <profile>    # 加载配置"
    Write-Host "  envsphere create <name>     # 创建新配置"
    Write-Host ""
    Write-Host "请重新加载您的PowerShell配置文件或重启终端:"
    Write-Host "  . `$PROFILE"
    Write-Host ""
    Write-Host "更多信息请查看: https://github.com/yourusername/EnvSphere" -ForegroundColor Blue
}

# 运行主函数
Main