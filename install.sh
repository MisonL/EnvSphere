#!/usr/bin/env bash

# EnvSphere - 简洁的环境变量管理器
# 基于loadenv模式的一键安装脚本
# 复刻用户主机上的环境变量管理模式

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

# 安装配置
readonly ENVSphere_VERSION="1.0.0"
readonly ENV_PROFILES_DIR="$HOME/.env_profiles"
readonly ENV_LOADER_FILE="$HOME/.env_loader"

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
    local system_info=$(detect_system)
    local os=$(echo "$system_info" | cut -d' ' -f1)
    local windows_env=$(echo "$system_info" | cut -d' ' -f4)
    
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
    
    cat > "$ENV_LOADER_FILE" << 'EOF'
# 环境变量加载器
# 用法：loadenv [profile_name] 或 loadenv -l 或 loadenv -a

env_profile() {
    local profile_dir="$HOME/.env_profiles"
    
    case "$1" in
        -l|--list)
            echo "可用的环境变量配置："
            ls "$profile_dir"/*.env 2>/dev/null | xargs -n 1 basename -s .env | sed 's/^/  - /'
            ;;
        -a|--all)
            echo "加载所有环境变量配置..."
            for env_file in "$profile_dir"/*.env; do
                if [ -f "$env_file" ]; then
                    local name=$(basename "$env_file" .env)
                    echo "  加载 $name 配置..."
                    source "$env_file"
                fi
            done
            echo "所有环境变量配置加载完成！"
            ;;
        -h|--help)
            echo "用法："
            echo "  loadenv [profile]     加载指定的环境变量配置"
            echo "  loadenv -l, --list    列出所有可用配置"
            echo "  loadenv -a, --all     加载所有配置"
            echo "  loadenv -h, --help    显示帮助信息"
            ;;
        "")
            echo "错误：请指定要加载的配置文件"
            echo "可用配置："
            ls "$profile_dir"/*.env 2>/dev/null | xargs -n 1 basename -s .env | sed 's/^/  - /'
            return 1
            ;;
        *)
            local env_file="$profile_dir/$1.env"
            if [ -f "$env_file" ]; then
                echo "加载 $1 环境变量配置..."
                source "$env_file"
                echo "✓ $1 环境变量配置加载成功！"
            else
                echo "错误：找不到配置文件 $env_file"
                echo "可用配置："
                ls "$profile_dir"/*.env 2>/dev/null | xargs -n 1 basename -s .env | sed 's/^/  - /'
                return 1
            fi
            ;;
    esac
}

# 创建loadenv alias指向函数
alias loadenv='env_profile'

# 快速加载常用配置的alias
alias load-all-env='env_profile --all'
alias list-envs='env_profile --list'
EOF

    chmod +x "$ENV_LOADER_FILE"
    print_color "$GREEN" "✓ 创建环境变量加载器: $ENV_LOADER_FILE"
}

# 创建示例配置文件
create_sample_profiles() {
    print_color "$BLUE" "正在创建示例配置文件..."
    
    # 开发环境示例
    cat > "$ENV_PROFILES_DIR/development.env" << 'EOF'
# 开发环境配置
export NODE_ENV="development"
export DEBUG="true"
export LOG_LEVEL="debug"
EOF

    # API密钥模板
    cat > "$ENV_PROFILES_DIR/api-keys.env" << 'EOF'
# API密钥配置模板
# 请替换为实际的API密钥

# 示例：
# export OPENAI_API_KEY="your-api-key-here"
# export GITHUB_TOKEN="your-github-token-here"
EOF

    # Claude配置示例（基于你的现有配置）
    cat > "$ENV_PROFILES_DIR/claude.env" << 'EOF'
# Claude Code 环境变量配置
export ANTHROPIC_API_KEY="your-api-key-here"
export ANTHROPIC_BASE_URL="https://www.k2sonnet.com/api/claudecode"
export CLAUDE_FORCE_ENV="true"
EOF

    print_color "$GREEN" "✓ 创建示例配置文件完成"
}

# 集成到Shell配置
integrate_shell() {
    local shell_config="$1"
    local shell_type="$2"
    
    if [[ -z "$shell_config" ]]; then
        print_color "$YELLOW" "警告: 无法检测到Shell配置文件"
        return 1
    fi
    
    print_color "$BLUE" "正在集成到 $shell_type 配置..."
    
    # 检查是否已集成
    if grep -q "加载环境变量管理器" "$shell_config" 2>/dev/null; then
        print_color "$YELLOW" "环境变量管理器已存在，跳过集成"
        return 0
    fi
    
    # 添加到shell配置文件
    {
        echo ""
        echo "# 加载环境变量管理器"
        echo "if [ -f ~/.env_loader ]; then"
        echo "    source ~/.env_loader"
        echo "fi"
    } >> "$shell_config"
    
    print_color "$GREEN" "✓ 已集成到 $shell_config"
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
    echo "   - 安装将修改您的shell配置文件"
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
        # 管道环境 - 提供替代方案
        print_color "$YELLOW" "⚠️  检测到管道环境，无法交互式输入"
        echo ""
        echo "解决方案："
        echo "  1. 手动安装: git clone https://github.com/MisonL/EnvSphere.git && cd EnvSphere && ./install.sh"
        echo "  2. 强制安装: 添加 --force 参数 (不推荐)"
        echo "  3. 查看帮助: curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/install.sh | bash -s -- --help"
        echo ""
        echo "是否强制继续安装？(风险自负) [y/N]: "
        read -r response < /dev/tty 2>/dev/null || {
            print_color "$YELLOW" "无法读取终端输入，安装已取消"
            exit 1
        }
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

# 主安装流程
main() {
    print_header
    
    # 检测系统信息
    local system_info=$(detect_system)
    local os=$(echo "$system_info" | cut -d' ' -f1)
    local is_wsl=$(echo "$system_info" | cut -d' ' -f2)
    local distro=$(echo "$system_info" | cut -d' ' -f3)
    local windows_env=$(echo "$system_info" | cut -d' ' -f4)
    
    local shell_info=$(detect_shell)
    local shell_type=$(echo "$shell_info" | cut -d' ' -f1)
    local shell_config=$(echo "$shell_info" | cut -d' ' -f2)
    
    print_color "$CYAN" "系统信息:"
    echo "  操作系统: $os"
    if [ "$distro" != "unknown" ] && [ "$os" = "ubuntu" ] || [ "$os" = "centos" ] || [ "$os" = "alpine" ] || [ "$os" = "arch" ] || [ "$os" = "suse" ]; then
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
    
    # 显示简要安装信息（不显示完整实施方案）
    print_color "$CYAN" "正在安装 EnvSphere..."
    echo "  目标目录: $ENV_PROFILES_DIR"
    echo "  Shell配置: $shell_config"
    echo ""
    
    # 直接开始安装（跳过交互式确认）
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
        integrate_shell "$shell_config" "$shell_type"
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