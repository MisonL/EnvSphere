#!/usr/bin/env bash

# EnvSphere - 简洁的环境变量管理器
# 基于loadenv模式的一键安装脚本
# 复刻用户主机上的环境变量管理模式

set -euo pipefail

SCRIPT_DIR_DIRNAME="$(dirname "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR_DIRNAME
SCRIPT_DIR="$(cd "$SCRIPT_DIR_DIRNAME" && pwd)"
readonly SCRIPT_DIR

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

# 安装配置
readonly ENVSphere_VERSION="1.1.0"
readonly ENV_PROFILES_DIR="$HOME/.env_profiles"
readonly ENV_LOADER_FILE="$HOME/.env_loader"
readonly ENV_LOADER_TEMPLATE="$SCRIPT_DIR/env_loader.template"
readonly ENV_PROFILES_TEMPLATE_DIR="$SCRIPT_DIR/.env_profiles"

# 打印彩色输出
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 打印标题
print_header() {
    echo ""
    print_color "$CYAN" "╔══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║              EnvSphere 安装程序                      ║"
    print_color "$CYAN" "║          简洁的环境变量管理器 v${ENVSphere_VERSION}              ║"
    print_color "$CYAN" "╚══════════════════════════════════════════════════════╝"
    echo ""
}

# 检测系统类型
detect_system() {
    local os="unknown"
    local is_wsl=false
    local distro="unknown"
    local windows_env="unknown"
    
    # 检测操作系统
    case "$(uname -s)" in
        Darwin*) 
            os="macos"
            ;;
        Linux*) 
            # 检测WSL环境（仅在Linux系统上）
            if grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSLENV:-}" ]; then
                is_wsl=true
                os="wsl"
            else
                # 检测Linux发行版
                if [ -f /etc/os-release ]; then
                    # 读取发行版信息
                    # shellcheck source=/etc/os-release disable=SC1091
                    . /etc/os-release
                    case "$ID" in
                        ubuntu|debian)
                            os="ubuntu"
                            distro="$ID"
                            ;;
                        centos|rhel|fedora|rocky|almalinux)
                            os="centos"
                            distro="$ID"
                            ;;
                        alpine)
                            os="alpine"
                            distro="$ID"
                            ;;
                        arch|manjaro)
                            os="arch"
                            distro="$ID"
                            ;;
                        opensuse*|suse*)
                            os="suse"
                            distro="$ID"
                            ;;
                        *)
                            os="linux"
                            distro="$ID"
                            ;;
                    esac
                elif [ -f /etc/redhat-release ]; then
                    # CentOS/RHEL旧版本
                    if grep -qi "centos" /etc/redhat-release; then
                        os="centos"
                        distro="centos"
                    elif grep -qi "red hat" /etc/redhat-release; then
                        os="centos" 
                        distro="rhel"
                    fi
                elif [ -f /etc/debian_version ]; then
                    # Debian/Ubuntu旧版本
                    if [ -f /etc/lsb-release ]; then
                        # shellcheck source=/etc/lsb-release disable=SC1091
                        . /etc/lsb-release
                        if [ "$DISTRIB_ID" = "Ubuntu" ]; then
                            os="ubuntu"
                            distro="ubuntu"
                        fi
                    else
                        os="ubuntu"
                        distro="debian"
                    fi
                else
                    os="linux"
                    distro="unknown"
                fi
            fi
            ;;
        CYGWIN*) 
            os="windows"
            windows_env="cygwin"
            ;;
        MINGW*|MSYS*)
            os="windows"
            # 检测Git for Windows vs MSYS2
            if [ -n "${MSYSTEM:-}" ]; then
                # MSYS2环境
                windows_env="msys2"
                distro="msys2"
            elif [ -f /etc/gitconfig ] || [ -d /git ]; then
                # Git for Windows环境
                windows_env="git"
                distro="git-for-windows"
            else
                # 普通MinGW环境
                windows_env="mingw"
                distro="mingw"
            fi
            ;;
        *) 
            os="unknown"
            distro="unknown"
            windows_env="unknown"
            ;;
    esac
    
    echo "$os $is_wsl $distro $windows_env"
}

# 检测Shell类型和配置文件
detect_shell() {
    local shell_type=""
    local shell_config=""
    local system_info
    system_info=$(detect_system)
    local os
    os=$(echo "$system_info" | cut -d' ' -f1)
    local windows_env
    windows_env=$(echo "$system_info" | cut -d' ' -f4)
    
    # 检测Shell类型
    if [ -n "${ZSH_VERSION:-}" ]; then
        shell_type="zsh"
        shell_config="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ]; then
        shell_type="bash"
        
        # 根据不同系统和环境选择正确的配置文件
        case "$os" in
            "macos")
                # macOS 默认使用 .bash_profile
                if [ -f "$HOME/.bash_profile" ]; then
                    shell_config="$HOME/.bash_profile"
                elif [ -f "$HOME/.bashrc" ]; then
                    shell_config="$HOME/.bashrc"
                else
                    shell_config="$HOME/.bash_profile"
                fi
                ;;
            "linux"|"wsl")
                # Linux 和 WSL 使用 .bashrc
                if [ -f "$HOME/.bashrc" ]; then
                    shell_config="$HOME/.bashrc"
                elif [ -f "$HOME/.bash_profile" ]; then
                    shell_config="$HOME/.bash_profile"
                else
                    shell_config="$HOME/.bashrc"
                fi
                ;;
            "windows")
                # Windows环境 (Git Bash, MSYS2, Cygwin)
                case "$windows_env" in
                    "git")
                        # Git for Windows
                        if [ -f "$HOME/.bash_profile" ]; then
                            shell_config="$HOME/.bash_profile"
                        elif [ -f "$HOME/.bashrc" ]; then
                            shell_config="$HOME/.bashrc"
                        else
                            shell_config="$HOME/.bash_profile"
                        fi
                        ;;
                    "msys2")
                        # MSYS2环境
                        if [ -f "$HOME/.bashrc" ]; then
                            shell_config="$HOME/.bashrc"
                        elif [ -f "$HOME/.bash_profile" ]; then
                            shell_config="$HOME/.bash_profile"
                        else
                            shell_config="$HOME/.bashrc"
                        fi
                        ;;
                    "cygwin")
                        # Cygwin环境
                        if [ -f "$HOME/.bashrc" ]; then
                            shell_config="$HOME/.bashrc"
                        elif [ -f "$HOME/.bash_profile" ]; then
                            shell_config="$HOME/.bash_profile"
                        else
                            shell_config="$HOME/.bashrc"
                        fi
                        ;;
                    *)
                        # 其他Windows bash环境
                        shell_config="$HOME/.bashrc"
                        ;;
                esac
                ;;
            *)
                # 其他系统，默认使用 .bashrc
                shell_config="$HOME/.bashrc"
                ;;
        esac
    else
        shell_type="unknown"
        shell_config=""
    fi
    
    echo "$shell_type $shell_config"
}

# 创建目录结构
create_directories() {
    print_color "$BLUE" "正在创建目录结构..."
    
    mkdir -p "$ENV_PROFILES_DIR"
    print_color "$GREEN" "✓ 创建目录: $ENV_PROFILES_DIR"
}

# 创建env_loader文件（复刻用户的函数）
create_env_loader() {
    print_color "$BLUE" "正在创建环境变量加载器..."

    if [ ! -f "$ENV_LOADER_TEMPLATE" ]; then
        print_color "$RED" "错误: 找不到模板 $ENV_LOADER_TEMPLATE"
        exit 1
    fi

    cp "$ENV_LOADER_TEMPLATE" "$ENV_LOADER_FILE"
    chmod +x "$ENV_LOADER_FILE"
    print_color "$GREEN" "✓ 创建环境变量加载器: $ENV_LOADER_FILE"
}

# 创建示例配置文件
create_sample_profiles() {
    print_color "$BLUE" "正在创建示例配置文件..."

    if [ ! -d "$ENV_PROFILES_TEMPLATE_DIR" ]; then
        print_color "$YELLOW" "提示: 未找到模板目录 $ENV_PROFILES_TEMPLATE_DIR，跳过示例复制"
        return 0
    fi

    find "$ENV_PROFILES_TEMPLATE_DIR" -maxdepth 1 -name "example-*.env" -print0 | while IFS= read -r -d '' template; do
        local target
        target="$ENV_PROFILES_DIR/$(basename "$template")"
        if [ -f "$target" ]; then
            print_color "$YELLOW" "跳过已存在的示例: $(basename "$template")"
            continue
        fi
        cp "$template" "$target"
        print_color "$GREEN" "✓ 已复制示例: $(basename "$template")"
    done
}

# 集成到Shell配置
integrate_shell() {
    local shell_config="$1"
    local shell_type="$2"
    local non_interactive="$3"

    if [[ -z "$shell_config" ]]; then
        print_color "$YELLOW" "警告: 未检测到Shell配置文件，您可以稍后手动执行:"
        echo "  echo 'if [ -f ~/.env_loader ]; then source ~/.env_loader; fi' >> ~/.bashrc"
        return 1
    fi

    local target_config="$shell_config"

    if [[ "$non_interactive" != "true" ]]; then
        print_color "$BLUE" "检测到的 $shell_type 配置文件: $shell_config"
        read -r -p "确认使用该文件进行集成？(Y/n/自定义路径): " response || true

        case "$response" in
            [Nn]|[Nn][Oo])
                read -r -p "请输入希望写入的配置文件路径: " custom_path || true
                if [[ -z "${custom_path:-}" ]]; then
                    print_color "$YELLOW" "未提供路径，将跳过自动集成"
                    return 1
                fi
                target_config="$custom_path"
                ;;
            [Yy]|[Yy][Ee][Ss]|"")
                ;;
            *)
                target_config="$response"
                ;;
        esac
    else
        print_color "$BLUE" "非交互模式，自动使用 $target_config 进行集成"
    fi

    if [[ ! -e "$target_config" ]]; then
        touch "$target_config" 2>/dev/null || {
            print_color "$YELLOW" "无法创建 $target_config，请手动添加以下内容:"
            echo ""
            echo "# 加载环境变量管理器"
            echo "if [ -f ~/.env_loader ]; then"
            echo "    source ~/.env_loader"
            echo "fi"
            echo ""
            return 1
        }
    fi

    if grep -q "加载环境变量管理器" "$target_config" 2>/dev/null; then
        print_color "$YELLOW" "环境变量管理器已存在，跳过集成"
        return 0
    fi

    {
        echo ""
        echo "# 加载环境变量管理器"
        echo "if [ -f ~/.env_loader ]; then"
        echo "    source ~/.env_loader"
        echo "fi"
    } >> "$target_config" 2>/dev/null || {
        print_color "$YELLOW" "警告: 无法写入 $target_config，请手动添加以下内容:"
        echo ""
        echo "# 加载环境变量管理器"
        echo "if [ -f ~/.env_loader ]; then"
        echo "    source ~/.env_loader"
        echo "fi"
        echo ""
        return 1
    }

    print_color "$GREEN" "✓ 已集成到 $target_config"
}

verify_loader() {
    local shell_type="$1"
    local shell_bin="${SHELL:-}"

    case "$shell_type" in
        zsh)
            shell_bin="${shell_bin:-/bin/zsh}"
            ;;
        bash)
            shell_bin="${shell_bin:-/bin/bash}"
            ;;
        *)
            shell_bin="${shell_bin:-/bin/sh}"
            ;;
    esac

    if ! command -v "$shell_bin" >/dev/null 2>&1; then
        print_color "$YELLOW" "提示: 无法自动校验 loadenv，请手动执行 'source ~/.env_loader'"
        return
    fi

    if "$shell_bin" -lc "if [ -f \"\$HOME/.env_loader\" ]; then . \"\$HOME/.env_loader\"; fi; command -v loadenv >/dev/null" >/dev/null 2>&1; then
        print_color "$GREEN" "✓ 校验完成: loadenv 命令可用"
    else
        print_color "$YELLOW" "提示: 请重新加载 shell 配置以启用 loadenv 命令"
    fi
}

# 显示实施方案
show_implementation_plan() {
    local os="$1"
    local shell_type="$2" 
    local shell_config="$3"
    local distro="$4"
    local windows_env="$5"
    
    print_color "$CYAN" "╔══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║                  实施方案预览                        ║"
    print_color "$CYAN" "╚══════════════════════════════════════════════════════╝"
    echo ""
    
    print_color "$BLUE" "📋 实施步骤："
    echo ""
    
    echo "1. 📁 创建目录结构："
    echo "   - 创建 ~/.env_profiles/ 目录"
    echo "   - 创建 ~/.env_loader 文件"
    echo ""
    
    echo "2. ⚙️ 生成配置文件："
    echo "   - 创建 development.env (开发环境示例)"
    echo "   - 创建 api-keys.env (API密钥模板)"
    echo "   - 创建 claude.env (Claude配置示例)"
    echo ""
    
    echo "3. 🔗 集成到Shell："
    if [ -n "$shell_config" ]; then
        echo "   - 添加到 $shell_config"
        echo "   - 添加环境变量加载器集成"
    else
        echo "   - 无法自动检测Shell配置文件"
        echo "   - 需要手动添加集成代码"
    fi
    echo ""
    
    echo "4. 🎯 创建快捷命令："
    echo "   - loadenv (加载环境配置)"
    echo "   - load-all-env (加载所有配置)"
    echo "   - list-envs (列出可用配置)"
    echo ""
    
    print_color "$BLUE" "🔍 系统信息："
    echo "   操作系统: $os"
    if [ "$distro" != "unknown" ]; then
        echo "   发行版: $distro"
    fi
    if [ -n "$shell_type" ] && [ "$shell_type" != "unknown" ]; then
        echo "   Shell类型: $shell_type"
        echo "   配置文件: $shell_config"
    fi
    if [ "$windows_env" != "unknown" ]; then
        echo "   Windows环境: $windows_env"
    fi
    echo ""
    
    print_color "$YELLOW" "⚠️  注意事项："
    echo "   - 安装将修改您的shell配置文件，若在CI或非交互环境中请使用 --force"
    echo "   - 建议先备份重要配置"
    echo "   - 安装完成后需要重新加载shell配置"
    echo ""
}

# 交互式确认
interactive_confirmation() {
    echo ""
    print_color "$CYAN" "请确认是否继续安装？"
    echo ""
    echo "  输入 y 或 yes  - 继续执行安装"
    echo "  输入 n 或 no   - 取消安装"
    echo "  输入其他       - 重新显示此提示"
    echo ""
    
    # 检测是否在管道环境中运行
    if [ -p /dev/stdin ] || [ ! -t 0 ]; then
        print_color "$YELLOW" "⚠️  检测到管道环境，默认跳过交互确认"
        echo "  使用方式： ./install.sh --force"
        echo "  或者: curl ... | bash -s -- --force"
        echo "  示例: curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash -s -- --force"
        echo ""
        return 0
    else
        # 正常终端环境
        echo -n "您的选择: "
        read -r response
    fi
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        [Nn]|[Nn][Oo]|"")
            print_color "$YELLOW" ""
            print_color "$YELLOW" "╔══════════════════════════════════════════════════════╗"
            print_color "$YELLOW" "║                  安装已取消                          ║"
            print_color "$YELLOW" "║                                                      ║"
            print_color "$YELLOW" "║  如果需要安装，请重新运行:                          ║"
            print_color "$YELLOW" "║  ./install.sh                                        ║"
            print_color "$YELLOW" "╚══════════════════════════════════════════════════════╝"
            exit 0
            ;;
        *)
            echo ""
            print_color "$YELLOW" "无效输入，请重新选择"
            interactive_confirmation
            ;;
    esac
}

# 显示帮助信息
show_help() {
    echo ""
    print_color "$CYAN" "╔══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║                  EnvSphere 安装帮助                    ║"
    print_color "$CYAN" "╚══════════════════════════════════════════════════════╝"
    echo ""
    
    print_color "$BLUE" "📖 用法:"
    echo "  ./install.sh              # 交互式安装"
    echo "  ./install.sh --force      # 非交互/CI 环境使用，跳过确认"
    echo "  ./install.sh --help       # 显示此帮助信息"
    echo ""
    
    print_color "$BLUE" "🌐 在线安装:"
    echo "  curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash"
    echo ""
    
    print_color "$BLUE" "⚠️  安全提示:"
    echo "  推荐先下载脚本检查内容后再执行："
    echo "  curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh -o install.sh"
    echo "  cat install.sh  # 检查内容"
    echo "  bash install.sh  # 执行安装"
    echo ""
    
    print_color "$BLUE" "🔧 安装后使用:"
    echo "  loadenv                    # 显示可用配置"
    echo "  loadenv <profile>          # 加载指定配置"
    echo "  loadenv -l, --list         # 列出所有配置"
    echo "  loadenv -a, --all          # 加载所有配置"
    echo ""

    print_color "$BLUE" "📁 安装位置:"
    echo "  配置目录: ~/.env_profiles/"
    echo "  加载器: ~/.env_loader (由仓库模板 env_loader.template 生成)"
    echo "  示例配置: ~/.env_profiles/example-*.env"
    echo ""

    print_color "$BLUE" "🤖 非交互示例:"
    echo "  curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash -s -- --force"
    echo "  ./install.sh --force"
    echo ""
}

# 主安装流程
main() {
    # 检查帮助参数
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    print_header
    
    # 检测系统信息
    local system_info
    system_info=$(detect_system)
    local os
    os=$(echo "$system_info" | cut -d' ' -f1)
    local is_wsl
    is_wsl=$(echo "$system_info" | cut -d' ' -f2)
    local distro
    distro=$(echo "$system_info" | cut -d' ' -f3)
    local windows_env
    windows_env=$(echo "$system_info" | cut -d' ' -f4)

    local shell_info
    shell_info=$(detect_shell)
    local shell_type
    shell_type=$(echo "$shell_info" | cut -d' ' -f1)
    local shell_config
    shell_config=$(echo "$shell_info" | cut -d' ' -f2)
    local non_interactive=false
    
    print_color "$CYAN" "系统信息:"
    echo "  操作系统: $os"
    if [ "$distro" != "unknown" ] && { [ "$os" = "ubuntu" ] || [ "$os" = "centos" ] || [ "$os" = "alpine" ] || [ "$os" = "arch" ] || [ "$os" = "suse" ]; }; then
        echo "  发行版: $distro"
    fi
    if [ "$is_wsl" = "true" ]; then
        echo "  WSL环境: 是"
    fi
    if [ "$os" = "windows" ] && [ "$windows_env" != "unknown" ]; then
        case "$windows_env" in
            "git")
                echo "  Windows环境: Git for Windows"
                ;;
            "msys2")
                echo "  Windows环境: MSYS2"
                ;;
            "mingw")
                echo "  Windows环境: MinGW"
                ;;
            "cygwin")
                echo "  Windows环境: Cygwin"
                ;;
        esac
    fi
    echo "  Shell类型: $shell_type"
    echo "  配置文件: $shell_config"
    echo ""
    
    # 检查是否强制安装
    local force_install=false
    if [[ "${1:-}" == "--force" ]]; then
        force_install=true
        print_color "$YELLOW" "⚠️  强制安装模式（跳过确认）"
        non_interactive=true
    fi
    
    # 显示简要安装信息（不显示完整实施方案）
    print_color "$CYAN" "正在安装 EnvSphere..."
    echo "  目标目录: $ENV_PROFILES_DIR"
    echo "  Shell配置: $shell_config"
    echo ""
    
    # 非强制安装时显示实施方案并确认
    if [[ "$force_install" != "true" ]]; then
        show_implementation_plan "$os" "$shell_type" "$shell_config" "$distro" "$windows_env"
        interactive_confirmation
    fi
    
    echo ""
    print_color "$GREEN" "开始执行安装..."
    echo ""
    
    # 执行安装步骤
    # 创建目录结构
    create_directories
    
    # 创建env_loader文件
    create_env_loader
    
    # 创建示例配置
    create_sample_profiles
    
    # 集成到Shell
    if [[ "$shell_type" != "unknown" ]]; then
        integrate_shell "$shell_config" "$shell_type" "$non_interactive"
        verify_loader "$shell_type"
    fi
    
    # 完成提示
    echo ""
    print_color "$GREEN" "🎉 EnvSphere 安装成功！"
    echo ""
    print_color "$CYAN" "=== 使用说明 ==="
    echo ""
    echo "重新加载shell配置或重启终端，然后使用："
    echo ""
    echo "  loadenv                    # 显示可用配置"
    echo "  loadenv <profile>          # 加载指定配置"
    echo "  loadenv -l, --list         # 列出所有配置"
    echo "  loadenv -a, --all          # 加载所有配置"
    echo ""
    echo "示例："
    echo "  loadenv claude             # 加载Claude配置"
    echo "  loadenv development        # 加载开发环境"
    echo ""
    print_color "$CYAN" "配置文件目录: $ENV_PROFILES_DIR"
    echo ""
    print_color "$YELLOW" "提示: 编辑 $ENV_PROFILES_DIR 下的 .env 文件来添加您的配置"
}

# 运行主函数
main "$@"