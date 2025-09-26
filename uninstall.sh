#!/usr/bin/env bash

# EnvSphere 卸载脚本
# 完全移除EnvSphere及其所有组件

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# 配置
readonly ENVSphere_DIR="${HOME}/.envsphere"
readonly BACKUP_DIR="${ENVSphere_DIR}/uninstall_backup_$(date +%Y%m%d_%H%M%S)"

# 打印彩色输出
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 检查EnvSphere是否已安装
check_installed() {
    if [[ ! -d "$ENVSphere_DIR" ]]; then
        print_color "${YELLOW}" "EnvSphere 似乎未安装"
        exit 0
    fi
}

# 显示卸载信息
show_uninstall_info() {
    echo ""
    print_color "${CYAN}${BOLD}" "╔══════════════════════════════════════════════════════╗"
    print_color "${CYAN}${BOLD}" "║              EnvSphere 卸载程序                       ║"
    print_color "${CYAN}${BOLD}" "╚══════════════════════════════════════════════════════╝"
    echo ""
    
    print_color "${BLUE}" "此操作将完全移除EnvSphere及其所有组件:"
    echo "  - 所有环境变量配置文件"
    echo "  - Shell集成代码"
    echo "  - 临时文件和缓存"
    echo ""
    print_color "${YELLOW}" "⚠️  警告: 此操作不可恢复！"
    echo ""
}

# 创建卸载备份
create_uninstall_backup() {
    print_color "${BLUE}" "正在创建卸载备份..."
    
    mkdir -p "$BACKUP_DIR"
    
    # 备份所有配置文件
    if [[ -d "${ENVSphere_DIR}/profiles" ]]; then
        cp -r "${ENVSphere_DIR}/profiles" "$BACKUP_DIR/"
    fi
    
    # 备份版本信息
    if [[ -f "${ENVSphere_DIR}/.version" ]]; then
        cp "${ENVSphere_DIR}/.version" "$BACKUP_DIR/"
    fi
    
    # 创建卸载清单
    cat > "${BACKUP_DIR}/uninstall_manifest.txt" << EOF
EnvSphere Uninstall Backup
==========================
Uninstall Date: $(date)
Backup Location: $BACKUP_DIR

Included Files:
EOF
    
    find "$BACKUP_DIR" -type f -name "*.env" >> "${BACKUP_DIR}/uninstall_manifest.txt"
    
    print_color "${GREEN}" "✓ 备份已创建: $BACKUP_DIR"
}

# 检测并移除Shell集成
remove_shell_integration() {
    print_color "${BLUE}" "正在移除Shell集成..."
    
    local shell_configs=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.profile"
        "$HOME/.config/fish/config.fish"
    )
    
    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]]; then
            # 检查是否包含EnvSphere集成
            if grep -q "EnvSphere" "$config"; then
                print_color "${YELLOW}" "发现EnvSphere集成在: $config"
                
                # 创建备份
                cp "$config" "${config}.pre-envsphere-uninstall"
                
                # 移除EnvSphere相关行
                # 移除EnvSphere注释行及其后的内容
                sed -i.bak '/^# EnvSphere/,/^$/d' "$config" 2>/dev/null || true
                
                # 移除export PATH中包含envsphere的行
                sed -i.bak '/export.*PATH.*envsphere/d' "$config" 2>/dev/null || true
                
                # 移除source envsphere的行
                sed -i.bak '/source.*envsphere/d' "$config" 2>/dev/null || true
                
                print_color "${GREEN}" "✓ 已从 $config 移除EnvSphere集成"
            fi
        fi
    done
    
    # Windows PowerShell配置
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        local ps_profile="$(powershell -Command '$PROFILE' 2>/dev/null)"
        if [[ -n "$ps_profile" ]] && [[ -f "$ps_profile" ]]; then
            if grep -q "EnvSphere" "$ps_profile" 2>/dev/null; then
                print_color "${YELLOW}" "发现EnvSphere集成在PowerShell配置中"
                cp "$ps_profile" "${ps_profile}.pre-envsphere-uninstall"
                # 这里需要更复杂的PowerShell脚本移除逻辑
            fi
        fi
    fi
}

# 移除EnvSphere目录
remove_envsphere_directory() {
    print_color "${BLUE}" "正在移除EnvSphere目录..."
    
    if [[ -d "$ENVSphere_DIR" ]]; then
        rm -rf "$ENVSphere_DIR"
        print_color "${GREEN}" "✓ EnvSphere目录已移除"
    fi
}

# 清理PATH环境变量
cleanup_path() {
    print_color "${BLUE}" "正在清理PATH环境变量..."
    
    # 从当前会话的PATH中移除
    export PATH=$(echo "$PATH" | sed "s|:${HOME}/.envsphere/bin:||g" | sed "s|${HOME}/.envsphere/bin:||g" | sed "s|:${HOME}/.envsphere/bin||g")
    
    print_color "${GREEN}" "✓ PATH已清理"
}

# 显示卸载后信息
show_post_uninstall_info() {
    echo ""
    print_color "${GREEN}${BOLD}" "🎉 EnvSphere 已成功卸载！"
    echo ""
    print_color "${CYAN}" "卸载摘要:"
    echo "  - EnvSphere 文件已移除"
    echo "  - Shell 集成已清理"
    echo "  - PATH 环境变量已更新"
    echo ""
    
    if [[ -d "$BACKUP_DIR" ]]; then
        print_color "${YELLOW}" "📁 卸载备份已保存到:"
        echo "    $BACKUP_DIR"
        echo ""
        print_color "${GRAY}" "备份包含:"
        echo "  - 所有的环境变量配置文件"
        echo "  - 版本信息"
        echo ""
    fi
    
    print_color "${BLUE}" "如需重新安装 EnvSphere，请访问:"
    echo "  https://github.com/yourusername/EnvSphere"
    echo ""
    
    print_color "${YELLOW}" "⚠️  请重新加载您的shell配置或重启终端:"
    echo "  source ~/.zshrc    # 对于 Zsh"
    echo "  source ~/.bashrc   # 对于 Bash"
    echo ""
}

# 可选：提供恢复选项
offer_restore() {
    echo ""
    read -p "是否需要恢复之前的环境变量配置? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_color "${BLUE}" "恢复功能说明:"
        echo "  1. 手动恢复: 从备份目录复制所需的 .env 文件"
        echo "     cp ${BACKUP_DIR}/profiles/<profile>.env ~/.envsphere/profiles/"
        echo ""
        echo "  2. 重新安装 EnvSphere 并导入配置"
        echo "     curl -fsSL https://raw.githubusercontent.com/user/EnvSphere/main/install.sh | bash"
        echo ""
        print_color "${YELLOW}" "备份文件保存在: $BACKUP_DIR"
    fi
}

# 主卸载流程
main() {
    show_uninstall_info
    
    # 确认卸载
    read -p "确定要卸载 EnvSphere? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_color "${YELLOW}" "卸载已取消"
        exit 0
    fi
    
    # 执行卸载步骤
    check_installed
    create_uninstall_backup
    remove_shell_integration
    cleanup_path
    remove_envsphere_directory
    
    # 完成
    show_post_uninstall_info
    offer_restore
}

# 处理命令行参数
case "${1:-}" in
    --help|-h)
        echo "EnvSphere 卸载程序"
        echo ""
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --help, -h     显示此帮助信息"
        echo "  --force        强制卸载，不提示确认"
        echo "  --no-backup    卸载时不创建备份"
        echo ""
        echo "卸载将:"
        echo "  1. 创建备份（除非指定 --no-backup）"
        echo "  2. 从Shell配置文件中移除EnvSphere集成"
        echo "  3. 删除EnvSphere目录"
        echo "  4. 清理PATH环境变量"
        exit 0
        ;;
    --force)
        # 强制卸载，跳过确认
        check_installed
        create_uninstall_backup
        remove_shell_integration
        cleanup_path
        remove_envsphere_directory
        show_post_uninstall_info
        exit 0
        ;;
    --no-backup)
        # 不创建备份的卸载
        check_installed
        remove_shell_integration
        cleanup_path
        remove_envsphere_directory
        print_color "${GREEN}" "EnvSphere 已卸载（无备份）"
        exit 0
        ;;
    "")
        # 正常卸载流程
        main
        ;;
    *)
        print_color "${RED}" "错误: 未知选项: $1"
        echo "使用 --help 查看可用选项"
        exit 1
        ;;
esac