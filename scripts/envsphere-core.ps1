# EnvSphere PowerShell 支持脚本
# 提供PowerShell特定的功能和集成

# PowerShell环境变量管理函数

function Get-EnvSphereConfig {
    <#
    .SYNOPSIS
        获取EnvSphere配置信息
    
    .DESCRIPTION
        返回当前EnvSphere的安装状态和配置信息
    #>
    
    return @{
        InstallDir = $env:USERPROFILE + "\.envsphere"
        ProfilesDir = $env:USERPROFILE + "\.envsphere\profiles"
        Version = if (Test-Path "$env:USERPROFILE\.envsphere\.version") { 
            Get-Content "$env:USERPROFILE\.envsphere\.version" 
        } else { "Unknown" }
        ActiveProfile = $env:ENVSphere_ACTIVE_PROFILE
    }
}

function Import-EnvSphereProfile {
    <#
    .SYNOPSIS
        导入环境变量配置文件
    
    .PARAMETER ProfileName
        要导入的配置文件名称
    
    .PARAMETER Path
        配置文件的路径
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProfileName,
        
        [Parameter(Mandatory=$false)]
        [string]$Path
    )
    
    if (-not $Path) {
        $Path = Join-Path (Get-EnvSphereConfig).ProfilesDir "$ProfileName.env"
    }
    
    if (Test-Path $Path) {
        Get-Content $Path | ForEach-Object {
            $line = $_.Trim()
            if ($line -match '^\s*export\s+([^=]+)=(.+)') {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim().Trim('"', "'")
                Set-Item -Path "env:$name" -Value $value
            }
        }
        $env:ENVSphere_ACTIVE_PROFILE = $ProfileName
        Write-Host "✓ 配置 '$ProfileName' 加载成功" -ForegroundColor Green
    } else {
        Write-Error "配置文件不存在: $Path"
    }
}

function Export-EnvSphereProfile {
    <#
    .SYNOPSIS
        导出当前环境变量到配置文件
    
    .PARAMETER ProfileName
        配置文件的名称
    
    .PARAMETER Variables
        要导出的变量名列表
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProfileName,
        
        [Parameter(Mandatory=$false)]
        [string[]]$Variables
    )
    
    $profilesDir = (Get-EnvSphereConfig).ProfilesDir
    $outputFile = Join-Path $profilesDir "$ProfileName.env"
    
    if (-not (Test-Path $profilesDir)) {
        New-Item -ItemType Directory -Path $profilesDir -Force | Out-Null
    }
    
    $content = @"# EnvSphere Profile: $ProfileName
# 创建于: $(Get-Date)

"@
    
    if ($Variables) {
        # 导出指定变量
        foreach ($var in $Variables) {
            $value = [Environment]::GetEnvironmentVariable($var)
            if ($value) {
                $content += "export $var=`"$value`"`n"
            }
        }
    } else {
        # 导出所有环境变量（排除系统变量）
        $excludedVars = @("PATH", "TEMP", "TMP", "USERNAME", "USERPROFILE", "COMPUTERNAME", "OS")
        
        Get-ChildItem env: | Where-Object {
            $_.Name -notin $excludedVars -and 
            -not $_.Name.StartsWith("PS") -and 
            -not $_.Name.StartsWith("__") -and
            $_.Name -ne "ENVSphere_ACTIVE_PROFILE"
        } | ForEach-Object {
            $content += "export $($_.Name)=`"$($_.Value)`"`n"
        }
    }
    
    $content | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "✓ 配置已导出到: $outputFile" -ForegroundColor Green
}

function Test-EnvSphereInstallation {
    <#
    .SYNOPSIS
        检查EnvSphere是否正确安装
    #>
    
    $config = Get-EnvSphereConfig
    
    $tests = @{
        "安装目录" = Test-Path $config.InstallDir
        "配置文件目录" = Test-Path $config.ProfilesDir
        "核心脚本" = Test-Path (Join-Path $config.InstallDir "scripts\envsphere-core.sh")
        "分析器脚本" = Test-Path (Join-Path $config.InstallDir "scripts\env-analyzer.sh")
    }
    
    Write-Host "EnvSphere 安装检查:" -ForegroundColor Cyan
    foreach ($test in $tests.GetEnumerator()) {
        $status = if ($test.Value) { "✓" } else { "✗" }
        $color = if ($test.Value) { "Green" } else { "Red" }
        Write-Host "  $status $($test.Key)" -ForegroundColor $color
    }
    
    return $tests.Values -notcontains $false
}

# 别名定义
Set-Alias -Name esp-import -Value Import-EnvSphereProfile
Set-Alias -Name esp-export -Value Export-EnvSphereProfile
Set-Alias -Name esp-check -Value Test-EnvSphereInstallation

# 导出函数
Export-ModuleMember -Function @(
    'Get-EnvSphereConfig',
    'Import-EnvSphereProfile',
    'Export-EnvSphereProfile',
    'Test-EnvSphereInstallation'
) -Alias @('esp-import', 'esp-export', 'esp-check')