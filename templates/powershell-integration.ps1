# EnvSphere PowerShell 集成模板
# 此文件将被添加到用户的 PowerShell 配置中

# EnvSphere 配置
$Env:ENVSphere_DIR = Join-Path $HOME ".envsphere"
$Env:ENVSphere_PROFILES_DIR = Join-Path $Env:ENVSphere_DIR "profiles"

# 如果EnvSphere未安装，则退出
if (-not (Test-Path $Env:ENVSphere_DIR)) {
    return
}

# 加载EnvSphere核心函数
$coreScript = Join-Path $Env:ENVSphere_DIR "scripts/envsphere-core.ps1"
if (Test-Path $coreScript) {
    . $coreScript
}

# PowerShell特有的EnvSphere函数

function Show-EnvSphereStatus {
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  EnvSphere Status                    ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # 显示版本
    $versionFile = Join-Path $Env:ENVSphere_DIR ".version"
    if (Test-Path $versionFile) {
        $version = Get-Content $versionFile
        Write-Host "║ Version: $version" -ForegroundColor Cyan -NoNewline
        Write-Host (" " * (50 - $version.Length - 10)) + "║" -ForegroundColor Cyan
    }
    
    # 显示配置文件数量
    $profileCount = (Get-ChildItem -Path $Env:ENVSphere_PROFILES_DIR -Filter "*.env" -ErrorAction SilentlyContinue).Count
    Write-Host "║ Profiles: $profileCount" -ForegroundColor Cyan -NoNewline
    Write-Host (" " * (50 - $profileCount.ToString().Length - 11)) + "║" -ForegroundColor Cyan
    
    # 显示当前加载的配置
    if ($env:ENVSphere_ACTIVE_PROFILE) {
        Write-Host "║ Active: $($env:ENVSphere_ACTIVE_PROFILE)" -ForegroundColor Cyan -NoNewline
        Write-Host (" " * (50 - $env:ENVSphere_ACTIVE_PROFILE.Length - 10)) + "║" -ForegroundColor Cyan
    }
    
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

# Tab补全
Register-ArgumentCompleter -CommandName envsphere -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $commands = @('load', 'list', 'ls', 'create', 'new', 'remove', 'rm', 'edit', 'help', '-h', '--help')
    
    # 解析当前命令位置
    $elements = $commandAst.CommandElements
    $elementCount = $elements.Count
    
    if ($elementCount -eq 2) {
        # 第一个参数：命令
        $commands | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
    elseif ($elementCount -eq 3) {
        # 第二个参数：配置文件名（仅对某些命令）
        $command = $elements[1].Value
        if ($command -in @('load', 'remove', 'rm', 'edit')) {
            if (Test-Path $Env:ENVSphere_PROFILES_DIR) {
                Get-ChildItem -Path $Env:ENVSphere_PROFILES_DIR -Filter "*.env" | ForEach-Object {
                    $name = $_.BaseName
                    if ($name -like "$wordToComplete*") {
                        [System.Management.Automation.CompletionResult]::new($name, $name, 'ParameterValue', "Profile: $name")
                    }
                }
            }
        }
    }
}

# Alias定义
Set-Alias -Name es -Value envsphere
Set-Alias -Name esls -Value 'envsphere list'
Set-Alias -Name esload -Value 'envsphere load'
Set-Alias -Name escreate -Value 'envsphere create'

# 快速加载常用配置
function Load-DevProfile {
    envsphere load development 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "未找到 development 配置" -ForegroundColor Yellow
    }
}

function Load-ProdProfile {
    envsphere load production 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "未找到 production 配置" -ForegroundColor Yellow
    }
}

function Load-ApiProfile {
    envsphere load api-keys 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "未找到 api-keys 配置" -ForegroundColor Yellow
    }
}

Set-Alias -Name load-dev -Value Load-DevProfile
Set-Alias -Name load-prod -Value Load-ProdProfile
Set-Alias -Name load-api -Value Load-ApiProfile

# PowerShell特有的功能

# 环境变量持久化（跨会话）
function Save-EnvSphereToRegistry {
    param(
        [string]$ProfileName
    )
    
    $regPath = "HKCU:\Software\EnvSphere\Profiles"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    # 保存活动配置
    Set-ItemProperty -Path $regPath -Name "ActiveProfile" -Value $ProfileName
}

# 自动加载上次使用的配置
function Restore-EnvSphereFromRegistry {
    $regPath = "HKCU:\Software\EnvSphere\Profiles"
    if (Test-Path $regPath) {
        $activeProfile = Get-ItemProperty -Path $regPath -Name "ActiveProfile" -ErrorAction SilentlyContinue
        if ($activeProfile -and $activeProfile.ActiveProfile) {
            envsphere load $activeProfile.ActiveProfile 2>$null
        }
    }
}

# 监听目录变化自动加载配置
function Set-EnvSphereDirectoryWatcher {
    param(
        [string]$Path = "."
    )
    
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Path
    $watcher.Filter = ".envsphere"
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
    
    $action = {
        $profile = Get-Content $Event.SourceEventArgs.FullPath -ErrorAction SilentlyContinue
        if ($profile) {
            envsphere load $profile.Trim()
        }
    }
    
    Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action | Out-Null
}

# 与Windows Terminal集成
function Update-TerminalTitle {
    param(
        [string]$ProfileName
    )
    
    if ($env:WT_SESSION) {
        # 在Windows Terminal中更新标题
        $host.UI.RawUI.WindowTitle = "EnvSphere: $ProfileName"
    }
}

# 导出函数
Export-ModuleMember -Function @(
    'Show-EnvSphereStatus',
    'Load-DevProfile',
    'Load-ProdProfile', 
    'Load-ApiProfile',
    'Save-EnvSphereToRegistry',
    'Restore-EnvSphereFromRegistry',
    'Set-EnvSphereDirectoryWatcher',
    'Update-TerminalTitle'
) -Alias @('es', 'esls', 'esload', 'escreate', 'load-dev', 'load-prod', 'load-api')

# 帮助函数
function Get-EnvSphereHelp {
    Write-Host @"
EnvSphere - 优雅的环境变量管理器

命令:
  envsphere load <profile>    加载环境配置文件
  envsphere list/ls           列出所有配置文件
  envsphere create/new        创建新的配置文件
  envsphere remove/rm         删除配置文件
  envsphere edit              编辑配置文件

快捷alias:
  es, esls, esload, escreate  envsphere的简写
  load-dev, load-prod, load-api  快速加载常用配置

PowerShell特有功能:
  Show-EnvSphereStatus        显示EnvSphere状态
  Save-EnvSphereToRegistry    保存配置到注册表
  Restore-EnvSphereFromRegistry 从注册表恢复配置
  Set-EnvSphereDirectoryWatcher 设置目录监听器

更多信息: https://github.com/yourusername/EnvSphere
"@
}

Set-Alias -Name envsphere-help -Value Get-EnvSphereHelp

# 清理函数
function Clear-EnvSphereTempFiles {
    $tempDir = Join-Path $Env:ENVSphere_DIR "temp"
    if (Test-Path $tempDir) {
        Get-ChildItem -Path $tempDir -File | Where-Object {
            $_.LastWriteTime -lt (Get-Date).AddDays(-30)
        } | Remove-Item -Force
    }
}

# 设置定期清理
if ($Host.Name -eq "ConsoleHost") {
    # 注册引擎事件，在退出时清理
    Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Clear-EnvSphereTempFiles
    } | Out-Null
}

# 自动恢复上次使用的配置（可选）
# 取消注释以启用
# Restore-EnvSphereFromRegistry

# 显示欢迎信息（仅在交互式会话中）
if ($Host.Name -eq "ConsoleHost" -and -not $env:ENVSphere_QUIET) {
    if (-not $env:ENVSphere_WELCOME_SHOWN) {
        $env:ENVSphere_WELCOME_SHOWN = "1"
        
        # 可以在这里添加欢迎消息
        # Write-Host "EnvSphere 已加载！使用 'envsphere-help' 查看帮助" -ForegroundColor Green
    }
}