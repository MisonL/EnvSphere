#!/usr/bin/env bash

# EnvSphere - 优雅的环境变量管理器
# 一键安装脚本
# 支持: macOS, Linux, Windows(WSL/Git Bash)
# 支持终端: zsh, bash, fish

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# 安装配置
readonly ENVSphere_VERSION="1.0.0"
readonly ENVSphere_DIR="${HOME}/.envsphere"
readonly ENVSphere_BIN_DIR="${ENVSphere_DIR}/bin"
readonly ENVSphere_PROFILES_DIR="${ENVSphere_DIR}/profiles"
readonly ENVSphere_BACKUP_DIR="${ENVSphere_DIR}/backups"

# 检测系统信息
detect_system() {
    local os=""
    local arch=""
    local shell_type=""
    local shell_config=""

    # 检测操作系统
    case "$(uname -s)" in
        Darwin*) os="macos" ;;
        Linux*) os="linux" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
        *) os="unknown" ;;
    esac

    # 检测架构
    case "$(uname -m)" in
        x86_64|amd64) arch="x64" ;;
        i386|i686) arch="x86" ;;
        arm64|aarch64) arch="arm64" ;;
        arm*) arch="arm" ;;
        *) arch="unknown" ;;
    esac

    # 检测Shell类型
    if [ -n "${ZSH_VERSION:-}" ]; then
        shell_type="zsh"
        shell_config="${HOME}/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ]; then
        shell_type="bash"
        shell_config="${HOME}/.bashrc"
        # 检查是否存在.bash_profile（macOS默认）
        if [ "${os}" = "macos" ] && [ -f "${HOME}/.bash_profile" ]; then
            shell_config="${HOME}/.bash_profile"
        fi
    elif [ "${SHELL##*/}" = "fish" ]; then
        shell_type="fish"
        shell_config="${HOME}/.config/fish/config.fish"
    else
        shell_type="unknown"
        shell_config=""
    fi

    echo "${os} ${arch} ${shell_type} ${shell_config}"
}

# 打印彩色输出
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 打印标题
print_header() {
    echo ""
    print_color "${CYAN}${BOLD}" "╔══════════════════════════════════════════════════════╗"
    print_color "${CYAN}${BOLD}" "║                  EnvSphere Installer                 ║"
    print_color "${CYAN}${BOLD}" "║          优雅的环境变量管理器 v${ENVSphere_VERSION}              ║"
    print_color "${CYAN}${BOLD}" "╚══════════════════════════════════════════════════════╝"
    echo ""
}

# 检查依赖
check_dependencies() {
    local deps=("curl" "grep" "sed" "awk")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" &> /dev/null; then
            missing_deps+=("${dep}")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_color "${RED}" "错误: 缺少必要的依赖工具: ${missing_deps[*]}"
        print_color "${YELLOW}" "请先安装这些工具后再运行安装脚本"
        exit 1
    fi
}

# 创建目录结构
create_directories() {
    print_color "${BLUE}" "正在创建EnvSphere目录结构..."
    
    mkdir -p "${ENVSphere_DIR}"/{bin,scripts,templates,profiles,backups}
    
    # 创建隐藏标记文件
    echo "${ENVSphere_VERSION}" > "${ENVSphere_DIR}/.version"
    
    print_color "${GREEN}" "✓ 目录结构创建完成"
}

# 下载并安装核心脚本
install_core_scripts() {
    print_color "${BLUE}" "正在安装EnvSphere核心脚本..."
    
    # 复制脚本文件到安装目录
    local script_dir="${BASH_SOURCE%/*}"
    
    # 复制核心功能脚本
    if [[ -f "$script_dir/scripts/envsphere-core.sh" ]]; then
        cp "$script_dir/scripts/envsphere-core.sh" "${ENVSphere_DIR}/scripts/"
    fi
    
    # 复制分析器脚本
    if [[ -f "$script_dir/scripts/env-analyzer.sh" ]]; then
        cp "$script_dir/scripts/env-analyzer.sh" "${ENVSphere_DIR}/scripts/"
        chmod +x "${ENVSphere_DIR}/scripts/env-analyzer.sh"
    fi
    
    # 复制交互式CLI脚本
    if [[ -f "$script_dir/scripts/interactive-cli.sh" ]]; then
        cp "$script_dir/scripts/interactive-cli.sh" "${ENVSphere_DIR}/scripts/"
        chmod +x "${ENVSphere_DIR}/scripts/interactive-cli.sh"
    fi
    
    # 复制模板文件
    if [[ -d "$script_dir/templates" ]]; then
        cp "$script_dir/templates/"*.sh "${ENVSphere_DIR}/templates/" 2>/dev/null || true
        cp "$script_dir/templates/"*.ps1 "${ENVSphere_DIR}/templates/" 2>/dev/null || true
    fi
    
    # 创建核心加载器
    cat > "${ENVSphere_BIN_DIR}/envsphere" << 'EOF'
#!/usr/bin/env bash
# EnvSphere 核心加载器

ENVSphere_DIR="${HOME}/.envsphere"
ENVSphere_PROFILES_DIR="${ENVSphere_DIR}/profiles"

# 加载核心功能
if [[ -f "${ENVSphere_DIR}/scripts/envsphere-core.sh" ]]; then
    source "${ENVSphere_DIR}/scripts/envsphere-core.sh"
fi

# 主要功能函数
envsphere_load() {
    local profile="$1"
    if command -v load_profile &> /dev/null; then
        load_profile "$profile"
    else
        local profile_file="${ENVSphere_PROFILES_DIR}/${profile}.env"
        if [[ -f "$profile_file" ]]; then
            echo "正在加载环境配置: ${profile}"
            source "$profile_file"
            export ENVSphere_ACTIVE_PROFILE="$profile"
            echo "✓ 配置加载成功"
        else
            echo "错误: 找不到配置文件 ${profile_file}"
            return 1
        fi
    fi
}

envsphere_list() {
    echo "可用的环境配置："
    for file in "${ENVSphere_PROFILES_DIR}"/*.env; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file" .env)
            echo "  - ${name}"
        fi
    done
}

envsphere_create() {
    local name="$1"
    local profile_file="${ENVSphere_PROFILES_DIR}/${name}.env"
    
    if [[ -f "$profile_file" ]]; then
        echo "警告: 配置文件已存在，将覆盖: ${profile_file}"
        read -p "继续吗? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # 创建新的配置文件
    cat > "$profile_file" << EOL
# EnvSphere Profile: $name
# 创建于: $(date)

# 在此添加环境变量
# export VARIABLE_NAME="value"

EOL
    
    echo "✓ 配置文件已创建: ${profile_file}"
    echo "请编辑该文件并添加您的环境变量"
}

# 主命令处理
case "$1" in
    load)
        if [[ -z "$2" ]]; then
            echo "用法: envsphere load <profile>"
            exit 1
        fi
        envsphere_load "$2"
        ;;
    list|ls)
        envsphere_list
        ;;
    create|new)
        if [[ -z "$2" ]]; then
            echo "用法: envsphere create <profile>"
            exit 1
        fi
        envsphere_create "$2"
        ;;
    *)
        echo "EnvSphere - 优雅的环境变量管理器"
        echo ""
        echo "用法:"
        echo "  envsphere load <profile>  加载环境配置"
        echo "  envsphere list            列出所有配置"
        echo "  envsphere create <name>   创建新配置"
        echo ""
        ;;
esac
EOF

    chmod +x "${ENVSphere_BIN_DIR}/envsphere"
    
    # 创建分析器命令链接
    ln -sf "${ENVSphere_DIR}/scripts/env-analyzer.sh" "${ENVSphere_BIN_DIR}/envsphere-analyze" 2>/dev/null || true
    ln -sf "${ENVSphere_DIR}/scripts/interactive-cli.sh" "${ENVSphere_BIN_DIR}/envsphere-migrate" 2>/dev/null || true
    
    print_color "${GREEN}" "✓ 核心脚本安装完成"
}

# 集成到Shell配置
integrate_shell() {
    local shell_config="$1"
    local shell_type="$2"
    
    if [[ -z "$shell_config" ]]; then
        print_color "${YELLOW}" "警告: 无法检测到Shell配置文件"
        return 1
    fi
    
    print_color "${BLUE}" "正在集成到 ${shell_type} 配置..."
    
    # 检查文件权限
    if [[ ! -w "$shell_config" ]] && [[ -f "$shell_config" ]]; then
        print_color "${YELLOW}" "⚠️  无法写入 $shell_config (权限不足)"
        print_color "${CYAN}" "将使用替代方案..."
        
        # 创建个人启动脚本
        local personal_init="$HOME/.envsphere/init.sh"
        
        cat > "$personal_init" << EOF
# EnvSphere - 环境变量管理器
export PATH="\$HOME/.envsphere/bin:\$PATH"
# 启用EnvSphere自动补全（如果可用）
[[ -f "\$HOME/.envsphere/completions/envsphere.${shell_type}" ]] && source "\$HOME/.envsphere/completions/envsphere.${shell_type}"

# 如果已安装，加载EnvSphere核心功能
if [[ -f "\$HOME/.envsphere/scripts/envsphere-core.sh" ]]; then
    source "\$HOME/.envsphere/scripts/envsphere-core.sh"
fi
EOF
        
        chmod +x "$personal_init"
        
        print_color "${GREEN}" "✓ 已创建个人初始化脚本: $personal_init"
        print_color "${CYAN}" "\n请在您的 shell 配置文件中添加以下内容："
        echo
        echo "# EnvSphere (替代安装方案)"
        echo "[[ -f \"$personal_init\" ]] && source \"$personal_init\""
        echo
        
        # 提供手动添加的说明
        case "$shell_type" in
            "zsh")
                echo "添加到 ~/.zshrc:"
                echo "echo '[[ -f \"$personal_init\" ]] && source \"$personal_init\"' >> ~/.zshrc"
                echo "然后运行: source ~/.zshrc"
                ;;
            "bash")
                echo "添加到 ~/.bashrc 或 ~/.bash_profile:"
                echo "echo '[[ -f \"$personal_init\" ]] && source \"$personal_init\"' >> ~/.bashrc"
                echo "然后运行: source ~/.bashrc"
                ;;
        esac
        
        return 0
    fi
    
    # 检查是否已集成
    if grep -q "EnvSphere" "$shell_config" 2>/dev/null; then
        print_color "${YELLOW}" "EnvSphere 已存在于 ${shell_config} 中，跳过集成"
        return 0
    fi
    
    # 备份原配置文件
    cp "$shell_config" "${ENVSphere_BACKUP_DIR}/$(basename "$shell_config").backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || {
        print_color "$YELLOW" "⚠️  无法备份配置文件，继续安装..."
    }
    
    # 添加EnvSphere集成
    {
        echo ""
        echo "# EnvSphere - 环境变量管理器"
        echo "export PATH=\"\$HOME/.envsphere/bin:\$PATH\""
        echo "# 启用EnvSphere自动补全（如果可用）"
        echo "[[ -f \"\$HOME/.envsphere/completions/envsphere.${shell_type}\" ]] && source \"\$HOME/.envsphere/completions/envsphere.${shell_type}\""
        echo ""
    } >> "$shell_config"
    
    print_color "${GREEN}" "✓ 已成功集成到 ${shell_config}"
}

# 创建示例配置
create_sample_profiles() {
    print_color "${BLUE}" "正在创建示例配置文件..."
    
    # 创建开发环境示例
    cat > "${ENVSphere_PROFILES_DIR}/development.env" << 'EOF'
# 开发环境配置示例
export NODE_ENV="development"
export DEBUG="true"
export LOG_LEVEL="debug"

# 开发工具路径
export EDITOR="vim"
export PAGER="less"
EOF

    # 创建API密钥示例
    cat > "${ENVSphere_PROFILES_DIR}/api-keys.env" << 'EOF'
# API密钥配置
# 请将以下示例替换为实际的API密钥

# GitHub
# export GITHUB_TOKEN="your_github_token_here"

# OpenAI
# export OPENAI_API_KEY="your_openai_api_key_here"

# 其他API
# export CUSTOM_API_KEY="your_api_key_here"
EOF

    print_color "${GREEN}" "✓ 示例配置文件创建完成"
}

# 主安装流程
main() {
    print_header
    
    # 检测系统信息
    local system_info
    system_info=$(detect_system)
    local os=$(echo "$system_info" | cut -d' ' -f1)
    local arch=$(echo "$system_info" | cut -d' ' -f2)
    local shell_type=$(echo "$system_info" | cut -d' ' -f3)
    local shell_config=$(echo "$system_info" | cut -d' ' -f4)
    
    print_color "${CYAN}" "系统信息:"
    echo "  操作系统: ${os}"
    echo "  架构: ${arch}"
    echo "  Shell类型: ${shell_type}"
    echo "  配置文件: ${shell_config}"
    echo ""
    
    # 检查依赖
    check_dependencies
    
    # 创建目录结构
    create_directories
    
    # 安装核心脚本
    install_core_scripts
    
    # 集成到Shell
    if [[ "$shell_type" != "unknown" ]]; then
        integrate_shell "$shell_config" "$shell_type"
    fi
    
    # 创建示例配置
    create_sample_profiles
    
    # 完成提示
    echo ""
    print_color "${GREEN}${BOLD}" "🎉 EnvSphere 安装成功！"
    echo ""
    print_color "${CYAN}" "=== 快速开始教程 ==="
    echo ""
    echo "1. 重新加载您的shell配置或重启终端:"
    if [[ -n "$shell_config" ]]; then
        echo "   source ${shell_config}"
    fi
    echo ""
    echo "2. 分析您当前的环境变量:"
    echo "   envsphere analyze"
    echo ""
    echo "3. 运行迁移向导（推荐）:"
    echo "   envsphere migrate"
    echo ""
    echo "4. 查看可用配置:"
    echo "   envsphere list"
    echo ""
    echo "5. 加载配置:"
    echo "   envsphere load development    # 加载开发环境"
    echo "   envsphere load api-keys       # 加载API密钥"
    echo ""
    echo "快捷方式:"
    echo "   es ls                         # 列出配置"
    echo "   es load dev                   # 加载开发配置"
    echo ""
    print_color "${YELLOW}" "=== 详细教程 ==="
    echo ""
    print_color "${CYAN}" "📚 完整文档: https://github.com/MisonL/EnvSphere"
    echo ""
    print_color "${CYAN}" "🎥 视频教程: https://github.com/MisonL/EnvSphere#tutorial"
    echo ""
    print_color "${CYAN}" "💡 高级用法:"
    echo "   - 在项目目录创建 .envsphere 文件实现自动加载"
    echo "   - 使用 envsphere create <name> 创建自定义配置"
    echo "   - 编辑 ~/.envsphere/profiles/ 下的配置文件"
    echo ""
    print_color "${RED}" "⚠️  重要提示:"
    echo "   - 不要将真实的API密钥提交到版本控制"
    echo "   - 定期备份您的配置文件"
    echo "   - 使用 envsphere migrate 时仔细检查要迁移的变量"
    echo ""
    print_color "${GREEN}" "🚀 开始使用 EnvSphere 管理您的环境变量吧！"
}

# 运行主函数
main "$@"