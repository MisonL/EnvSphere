#!/usr/bin/env bash

# EnvSphere 权限安全的安装脚本
# 处理各种权限和兼容性问题

set -e

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 检查文件是否可写
check_writable() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # 检查是否可写
        if [[ -w "$file" ]]; then
            return 0
        else
            return 1
        fi
    else
        # 检查目录是否可写
        local dir=$(dirname "$file")
        if [[ -w "$dir" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# 安全的 shell 集成
safe_shell_integration() {
    local shell_type="$1"
    local shell_config="$2"
    
    print_color "$BLUE" "正在检查 $shell_config 的权限..."
    
    # 如果配置文件不可写，提供替代方案
    if ! check_writable "$shell_config"; then
        print_color "$YELLOW" "⚠️  无法写入 $shell_config (权限不足)"
        print_color "$CYAN" "将使用替代方案..."
        
        # 创建个人启动脚本
        local personal_init="$HOME/.envsphere/init.sh"
        mkdir -p "$HOME/.envsphere"
        
        cat > "$personal_init" << 'EOF'
# EnvSphere - 环境变量管理器
export PATH="$HOME/.envsphere/bin:$PATH"
# 启用EnvSphere自动补全（如果可用）
[[ -f "$HOME/.envsphere/completions/envsphere.zsh" ]] && source "$HOME/.envsphere/completions/envsphere.zsh"
[[ -f "$HOME/.envsphere/completions/envsphere.bash" ]] && source "$HOME/.envsphere/completions/envsphere.bash"

# 如果已安装，加载EnvSphere核心功能
if [[ -f "$HOME/.envsphere/scripts/envsphere-core.sh" ]]; then
    source "$HOME/.envsphere/scripts/envsphere-core.sh"
fi
EOF
        
        chmod +x "$personal_init"
        
        print_color "$GREEN" "✓ 已创建个人初始化脚本: $personal_init"
        print_color "$CYAN" "\n请在您的 shell 配置文件中添加以下内容："
        echo
        echo "# EnvSphere (替代安装方案)"
        echo "[[ -f \"$personal_init\" ]] && source \"$personal_init\""
        echo
        
        # 提供手动添加的说明
        case "$shell_type" in
            "zsh")
                echo "添加到 ~/.zshrc:"
                echo "echo '[[ -f \"$personal_init\" ]] && source \"$personal_init\"' >> ~/.zshrc"
                ;;
            "bash")
                echo "添加到 ~/.bashrc 或 ~/.bash_profile:"
                echo "echo '[[ -f \"$personal_init\" ]] && source \"$personal_init\"' >> ~/.bashrc"
                ;;
        esac
        
        return 0
    fi
    
    # 检查是否已集成
    if grep -q "EnvSphere" "$shell_config" 2>/dev/null; then
        print_color "$YELLOW" "EnvSphere 已存在于 $shell_config 中，跳过集成"
        return 0
    fi
    
    # 备份原配置文件
    local backup_dir="$HOME/.envsphere/backups"
    mkdir -p "$backup_dir"
    cp "$shell_config" "$backup_dir/$(basename "$shell_config").backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # 添加EnvSphere集成
    {
        echo ""
        echo "# EnvSphere - 环境变量管理器"
        echo "export PATH=\"\$HOME/.envsphere/bin:\$PATH\""
        echo "# 启用EnvSphere自动补全（如果可用）"
        echo "[[ -f \"\$HOME/.envsphere/completions/envsphere.$shell_type\" ]] && source \"\$HOME/.envsphere/completions/envsphere.$shell_type\""
        echo ""
    } >> "$shell_config"
    
    print_color "$GREEN" "✓ 已成功集成到 $shell_config"
    return 0
}

# 检测并处理各种系统情况
detect_and_handle_issues() {
    print_color "$BLUE" "正在检测系统兼容性问题..."
    
    # 检查 bash 版本
    if [[ -n "${BASH_VERSION:-}" ]]; then
        local bash_major=${BASH_VERSION%%.*}
        if [[ $bash_major -lt 4 ]]; then
            print_color "$YELLOW" "⚠️  Bash 版本低于 4.0 ($BASH_VERSION)"
            print_color "$CYAN" "建议使用 zsh 或升级 bash 以获得最佳体验"
        fi
    fi
    
    # 检查 jq 是否安装
    if ! command -v jq &> /dev/null; then
        print_color "$YELLOW" "ℹ️  jq 未安装，将使用文本处理方式"
    fi
    
    # 检查是否有其他环境管理工具
    if command -v direnv &> /dev/null; then
        print_color "$YELLOW" "ℹ️  检测到 direnv，两者可以共存"
    fi
    
    if command -v autoenv &> /dev/null; then
        print_color "$YELLOW" "ℹ️  检测到 autoenv，两者可以共存"
    fi
}

# 显示安装后说明
show_post_install_info() {
    print_color "$CYAN" "\n=== 安装完成 ==="
    print_color "$GREEN" "✓ EnvSphere 已成功安装！"
    
    echo
    print_color "$CYAN" "请重新加载您的 shell 配置："
    echo "  source ~/.zshrc    # 对于 zsh"
    echo "  source ~/.bashrc   # 对于 bash"
    echo
    
    print_color "$CYAN" "或者重新打开终端窗口"
    echo
    
    print_color "$CYAN" "然后您可以使用："
    echo "  envsphere list     # 列出所有配置"
    echo "  envsphere analyze  # 分析环境变量"
    echo "  envsphere migrate  # 交互式迁移向导"
    echo
    print_color "$CYAN" "快捷方式："
    echo "  es ls              # 列出配置"
    echo "  es load dev        # 加载开发配置"
    
    echo
    print_color "$YELLOW" "如果遇到问题，请查看："
    echo "  文档: https://github.com/MisonL/EnvSphere"
    echo "  报告问题: https://github.com/MisonL/EnvSphere/issues"
}

# 主函数
main() {
    print_color "$CYAN$BOLD" "╔══════════════════════════════════════════════════════╗"
    print_color "$CYAN$BOLD" "║          EnvSphere 权限安全安装程序                  ║"
    print_color "$CYAN$BOLD" "║          优雅的环境变量管理器 v1.0.0                ║"
    print_color "$CYAN$BOLD" "╚══════════════════════════════════════════════════════╝"
    echo
    
    # 检测系统兼容性问题
    detect_and_handle_issues
    
    echo
    print_color "$BLUE" "正在安装 EnvSphere..."
    
    # 创建目录结构
    mkdir -p "$HOME/.envsphere"/{bin,scripts,templates,profiles,backups,analysis,temp}
    
    # 下载并安装核心脚本
    print_color "$BLUE" "正在下载核心脚本..."
    curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/scripts/envsphere-core.sh -o "$HOME/.envsphere/scripts/envsphere-core.sh" || {
        print_color "$RED" "错误: 无法下载核心脚本"
        exit 1
    }
    curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/scripts/env-analyzer.sh -o "$HOME/.envsphere/scripts/env-analyzer.sh" || {
        print_color "$RED" "错误: 无法下载分析器脚本"
        exit 1
    }
    curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/scripts/migrate-simple-fixed.sh -o "$HOME/.envsphere/scripts/envsphere-migrate.sh" || {
        print_color "$RED" "错误: 无法下载迁移脚本"
        exit 1
    }
    
    # 设置执行权限
    chmod +x "$HOME/.envsphere/scripts/"*.sh
    
    # 创建主命令
    cat > "$HOME/.envsphere/bin/envsphere" << 'EOF'
#!/usr/bin/env bash
# EnvSphere 主命令

export ENVSphere_DIR="$HOME/.envsphere"
export ENVSphere_PROFILES_DIR="$HOME/.envsphere/profiles"

# 加载核心功能
if [[ -f "${ENVSphere_DIR}/scripts/envsphere-core.sh" ]]; then
    source "${ENVSphere_DIR}/scripts/envsphere-core.sh"
fi

# 主要功能函数
envsphere_load() {
    local profile="$1"
    if [[ -z "$profile" ]]; then
        echo "错误: 请指定配置名称"
        return 1
    fi
    
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
}

envsphere_list() {
    echo "可用的环境配置："
    for file in "${ENVSphere_PROFILES_DIR}"/*.env; do
        if [[ -f "$file" ]]; then
            local name=$(basename "$file" .env)
            echo "  - $name"
        fi
    done
}

envsphere_create() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "错误: 请指定配置名称"
        return 1
    fi
    
    local profile_file="${ENVSphere_PROFILES_DIR}/${name}.env"
    if [[ -f "$profile_file" ]]; then
        echo "警告: 配置 $name 已存在，将被覆盖"
    fi
    
    cat > "$profile_file" << EOL
# EnvSphere Profile: $name
# 创建于: $(date)

# 在此添加环境变量
# export KEY="value"
EOL
    
    echo "✓ 已创建新配置: $name"
    echo "请编辑: $profile_file"
}

case "$1" in
    list|ls)
        envsphere_list
        ;;
    load)
        envsphere_load "$2"
        ;;
    create|new)
        envsphere_create "$2"
        ;;
    analyze)
        "${ENVSphere_DIR}/scripts/env-analyzer.sh"
        ;;
    migrate)
        # 使用 zsh 运行迁移脚本
        if command -v zsh &> /dev/null; then
            zsh "${ENVSphere_DIR}/scripts/envsphere-migrate.sh"
        else
            echo "错误: 需要 zsh 来运行迁移向导"
            echo "请安装 zsh 或使用：envsphere analyze 手动分析"
        fi
        ;;
    *)
        echo "EnvSphere - 环境变量管理器"
        echo ""
        echo "用法:"
        echo "  envsphere list          # 列出所有配置"
        echo "  envsphere load <name>   # 加载配置"
        echo "  envsphere create <name> # 创建新配置"
        echo "  envsphere analyze       # 分析环境变量"
        echo "  envsphere migrate       # 交互式迁移"
        echo ""
        echo "快捷方式:"
        echo "  es ls          # 列出配置"
        echo "  es load dev    # 加载开发配置"
        ;;
esac
EOF

    chmod +x "$HOME/.envsphere/bin/envsphere"
    
    # 创建快捷方式
    ln -sf "$HOME/.envsphere/bin/envsphere" "$HOME/.envsphere/bin/es"
    
    # 下载示例配置
    print_color "$BLUE" "正在下载示例配置..."
    curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/profiles/development.env -o "$HOME/.envsphere/profiles/development.env" 2>/dev/null || true
    curl -fsSL https://raw.githubusercontent.com/MisonL/EnvSphere/main/profiles/api-keys.env -o "$HOME/.envsphere/profiles/api-keys.env" 2>/dev/null || true
    
    # 创建版本文件
    echo "1.0.0" > "$HOME/.envsphere/.version"
    
    # 检测 shell 类型并集成
    local shell_type=""
    local shell_config=""
    
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_type="zsh"
        shell_config="$HOME/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        shell_type="bash"
        if [[ -f "$HOME/.bash_profile" ]]; then
            shell_config="$HOME/.bash_profile"
        elif [[ -f "$HOME/.bashrc" ]]; then
            shell_config="$HOME/.bashrc"
        else
            shell_config="$HOME/.profile"
        fi
    else
        shell_type="unknown"
    fi
    
    if [[ "$shell_type" != "unknown" ]]; then
        safe_shell_integration "$shell_type" "$shell_config"
    fi
    
    # 显示安装后信息
    show_post_install_info
}

# 运行主函数
main "$@"