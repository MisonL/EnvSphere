#!/usr/bin/env bash

# EnvSphere 卸载脚本
# 安全移除环境变量管理器

set -euo pipefail

# 颜色定义
GREEN='\033[0;32m'
readonly GREEN
YELLOW='\033[0;33m'
readonly YELLOW
BLUE='\033[0;34m'
readonly BLUE
CYAN='\033[0;36m'
readonly CYAN
RESET='\033[0m'
readonly RESET

# 路径配置
SCRIPT_DIR_RAW="$(dirname "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR_RAW
SCRIPT_DIR="$(cd "$SCRIPT_DIR_RAW" && pwd)"
readonly SCRIPT_DIR
readonly ENV_PROFILES_DIR="$HOME/.env_profiles"
readonly ENV_LOADER_FILE="$HOME/.env_loader"
readonly ENV_LOADER_TEMPLATE="$SCRIPT_DIR/env_loader.template"

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
    print_color "$CYAN" "║              EnvSphere 卸载程序                      ║"
    print_color "$CYAN" "║              Environment Manager Uninstaller         ║"
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

# 备份配置文件
backup_config() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_file
        backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_file"
        print_color "$GREEN" "✓ 已备份: $backup_file"
    fi
}

# 从Shell配置中移除集成
remove_shell_integration() {
    local shell_config="$1"
    
    if [[ -f "$shell_config" ]]; then
        print_color "$BLUE" "正在从 $shell_config 中移除集成..."
        
        # 备份原文件
        backup_config "$shell_config"
        
        # 移除env_loader相关行
        sed -i.bak '/# 加载环境变量管理器/,/fi/d' "$shell_config" 2>/dev/null || true
        
        print_color "$GREEN" "✓ 已从 $shell_config 中移除集成"
    fi
}

# 删除文件和目录
remove_files() {
    print_color "$BLUE" "正在删除文件和目录..."
    
    # 删除env_loader文件
    if [[ -f "$ENV_LOADER_FILE" ]]; then
        rm -f "$ENV_LOADER_FILE"
        print_color "$GREEN" "✓ 删除文件: $ENV_LOADER_FILE"
    elif [[ -f "$ENV_LOADER_TEMPLATE" ]]; then
        print_color "$YELLOW" "提示: 检测到模板文件，若您使用模板生成的加载器，请手动确认 ~/.env_loader 是否已移除"
    fi
    
    # 询问是否删除配置文件目录
    if [[ -d "$ENV_PROFILES_DIR" ]]; then
        local profile_count
        profile_count=$(find "$ENV_PROFILES_DIR" -maxdepth 1 -name "*.env" | wc -l | tr -d ' ')
        print_color "$YELLOW" "发现 $profile_count 个配置文件在 $ENV_PROFILES_DIR"

        if [ "${CI:-}" = "true" ]; then
            rm -rf "$ENV_PROFILES_DIR"
            print_color "$GREEN" "✓ (CI) 已删除目录: $ENV_PROFILES_DIR"
        else
            echo -n "是否删除所有配置文件? (y/N): "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                rm -rf "$ENV_PROFILES_DIR"
                print_color "$GREEN" "✓ 删除目录: $ENV_PROFILES_DIR"
            else
                print_color "$YELLOW" "保留配置文件目录: $ENV_PROFILES_DIR"
            fi
        fi
    fi
}

# 显示卸载信息
show_uninstall_info() {
    echo ""
    print_color "$GREEN" "🎉 EnvSphere 卸载完成！"
    echo ""
    print_color "$CYAN" "=== 后续操作 ==="
    echo ""
    echo "1. 重新加载shell配置:"
    local shell_info
    shell_info=$(detect_shell)
    local shell_type
    shell_type=$(echo "$shell_info" | cut -d' ' -f1)
    local shell_config
    shell_config=$(echo "$shell_info" | cut -d' ' -f2)
    
    if [[ -n "$shell_config" ]]; then
        echo "   source $shell_config"
    fi
    echo ""
    echo "2. 或者重启终端会话"
    echo ""
    print_color "$YELLOW" "注意: 如果保留了配置文件，可以手动删除:"
    echo "   rm -rf $ENV_PROFILES_DIR"
    if [[ -f "$ENV_LOADER_TEMPLATE" ]]; then
        echo "   (提示: 如果需要恢复加载器，可重新运行安装脚本生成 ~/.env_loader)"
    fi
    echo ""
}

# 显示帮助信息
show_help() {
    echo ""
    print_color "$CYAN" "╔══════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║                  EnvSphere 卸载帮助                    ║"
    print_color "$CYAN" "╚══════════════════════════════════════════════════════╝"
    echo ""
    
    print_color "$BLUE" "📖 用法:"
    echo "  ./uninstall.sh            # 交互式卸载"
    echo "  ./uninstall.sh --help     # 显示此帮助信息"
    echo ""
    
    print_color "$BLUE" "⚠️  注意事项:"
    echo "  - 卸载会备份您的Shell配置文件"
    echo "  - 会询问是否删除配置文件目录"
    echo "  - 卸载后需要重新加载Shell配置"
    echo ""
    
    print_color "$BLUE" "🔧 卸载后操作:"
    echo "  source ~/.zshrc          # 重新加载zsh配置"
    echo "  source ~/.bashrc         # 重新加载bash配置"
    echo "  # 或重启终端"
    echo ""
}

# 主卸载流程
main() {
    # 检查帮助参数
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    print_header
    
    # 检测系统信息
    local shell_info
    shell_info=$(detect_shell)
    local shell_type
    shell_type=$(echo "$shell_info" | cut -d' ' -f1)
    local shell_config
    shell_config=$(echo "$shell_info" | cut -d' ' -f2)
    
    print_color "$CYAN" "系统信息:"
    echo "  Shell类型: $shell_type"
    echo "  配置文件: $shell_config"
    echo ""
    
    # 确认卸载
    echo -n "确认要卸载EnvSphere? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_color "$YELLOW" "卸载已取消"
        exit 0
    fi
    
    # 从Shell配置中移除集成
    if [[ -n "$shell_config" ]]; then
        remove_shell_integration "$shell_config"
    fi
    
    # 删除文件
    remove_files
    
    # 显示卸载信息
    show_uninstall_info
}

# 运行主函数
main "$@"