@echo off
REM EnvSphere CMD 批处理支持
REM 提供基本的EnvSphere功能

setlocal enabledelayedexpansion

REM 检查EnvSphere是否安装
if not exist "%USERPROFILE%\.envsphere" (
    echo 错误: EnvSphere 未安装
    exit /b 1
)

REM 设置路径
set "ENVSphere_DIR=%USERPROFILE%\.envsphere"
set "ENVSphere_PROFILES_DIR=%ENVSphere_DIR%\profiles"

REM 主功能
if "%1"=="" goto show_help
if /i "%1"=="load" goto load_profile
if /i "%1"=="list" goto list_profiles
if /i "%1"=="ls" goto list_profiles
if /i "%1"=="create" goto create_profile
if /i "%1"=="new" goto create_profile
if /i "%1"=="help" goto show_help
if /i "%1"=="-h" goto show_help
if /i "%1"=="--help" goto show_help

echo 未知命令: %1
goto show_help

:load_profile
if "%2"=="" (
    echo 用法: envsphere load ^<profile^>
    exit /b 1
)

set "profile=%2"
set "profile_file=%ENVSphere_PROFILES_DIR%\%profile%.env"

if not exist "%profile_file%" (
    echo 错误: 找不到配置文件 %profile_file%
    exit /b 1
)

echo 正在加载环境配置: %profile%

REM 读取并设置环境变量
for /f "usebackq tokens=*" %%a in ("%profile_file%") do (
    set "line=%%a"
    REM 跳过注释行和空行
    if "!line:~0,1!" neq "#" if "!line!" neq "" (
        REM 解析 export 语句
        echo !line! | findstr /r "^export[ ][ ]*[A-Za-z_][A-Za-z0-9_]*=.*" >nul
        if !errorlevel! equ 0 (
            REM 提取变量名和值
            for /f "tokens=2 delims==" %%b in ("!line:":=^"!") do (
                set "var_value=%%b"
                REM 移除前后的引号
                set "var_value=!var_value:"=!"
                REM 设置环境变量
                for /f "tokens=2" %%c in ("!line!") do (
                    set "var_name=%%c"
                    set "var_name=!var_name:=!"
                    setx !var_name! "!var_value!" >nul 2>&1
                    set "!var_name!=!var_value!"
                )
            )
        )
    )
)

echo ✓ 配置加载成功
set "ENVSphere_ACTIVE_PROFILE=%profile%"
exit /b 0

:list_profiles
echo 可用的环境配置:
if exist "%ENVSphere_PROFILES_DIR%\*.env" (
    for %%f in ("%ENVSphere_PROFILES_DIR%\*.env") do (
        echo   - %%~nf
    )
) else (
    echo   没有找到配置文件
)
exit /b 0

:create_profile
if "%2"=="" (
    echo 用法: envsphere create ^<profile^>
    exit /b 1
)

set "name=%2"
set "profile_file=%ENVSphere_PROFILES_DIR%\%name%.env"

if exist "%profile_file%" (
    echo 警告: 配置文件已存在，将覆盖: %profile_file%
    set /p "confirm=继续吗? (y/N): "
    if /i not "!confirm!"=="y" exit /b 1
)

REM 创建配置文件
(
echo # EnvSphere Profile: %name%
echo # 创建于: %date% %time%
echo.
echo # 在此添加环境变量
echo # export VARIABLE_NAME="value"
echo.
) > "%profile_file%"

echo ✓ 配置文件已创建: %profile_file%
echo 请编辑该文件并添加您的环境变量
exit /b 0

:show_help
echo EnvSphere - 优雅的环境变量管理器
echo.
echo 用法:
echo   envsphere load ^<profile^>    加载环境配置
echo   envsphere list              列出所有配置
echo   envsphere create ^<name^>    创建新配置
echo   envsphere help              显示帮助信息
echo.
echo 更多信息: https://github.com/yourusername/EnvSphere
exit /b 0