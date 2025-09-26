#!/usr/bin/env bash

# EnvSphere Zsh 集成模板
# 此文件将被添加到用户的 .zshrc 中

# EnvSphere 配置
export ENVSphere_DIR="${HOME}/.envsphere"
export ENVSphere_PROFILES_DIR="${ENVSphere_DIR}/profiles"

# 如果EnvSphere未安装，则退出
[[ ! -d "$ENVSphere_DIR" ]] && return

# 加载EnvSphere核心函数
source "${ENVSphere_DIR}/scripts/envsphere-core.sh" 2>/dev/null

# 自动补全函数
_envsphere_completion() {
    local -a commands profiles
    commands=('load' 'list' 'ls' 'create' 'new' 'remove' 'rm' 'edit' 'help' '-h' '--help')
    
    # 获取所有配置文件
    if [[ -d "$ENVSphere_PROFILES_DIR" ]]; then
        profiles=(${(f)"$(ls "$ENVSphere_PROFILES_DIR"/*.env 2>/dev/null | xargs -n 1 basename -s .env)"})
    fi
    
    case $CURRENT in
        1)
            # 第一层补全：命令
            _describe 'command' commands
            ;;
        2)
            # 第二层补全：配置文件（仅对某些命令）
            case $words[2] in
                load|remove|rm|edit)
                    _describe 'profile' profiles
                    ;;
            esac
            ;;
    esac
}

# 注册自动补全
compdef _envsphere_completion envsphere

# 创建alias
alias es='envsphere'
alias esls='envsphere list'
alias esload='envsphere load'
alias escreate='envsphere create'

# 快速加载常用配置（用户可以自定义）
alias load-dev='envsphere load development 2>/dev/null || echo "未找到 development 配置"'
alias load-prod='envsphere load production 2>/dev/null || echo "未找到 production 配置"'
alias load-api='envsphere load api-keys 2>/dev/null || echo "未找到 api-keys 配置"'

# 显示EnvSphere状态
envsphere_status() {
    print -P "%F{cyan}╔══════════════════════════════════════════════════════╗%f"
    print -P "%F{cyan}║%f %BEnvSphere Status%b %F{cyan}$(printf '%*s' $((45)) '')║%f"
    print -P "%F{cyan}╠══════════════════════════════════════════════════════╣%f"
    
    # 显示版本
    if [[ -f "${ENVSphere_DIR}/.version" ]]; then
        local version=$(cat "${ENVSphere_DIR}/.version")
        print -P "%F{cyan}║%f Version: $version$(printf '%*s' $((50 - ${#version} - 10)) '') %F{cyan}║%f"
    fi
    
    # 显示配置文件数量
    local profile_count=$(ls -1 "$ENVSphere_PROFILES_DIR"/*.env 2>/dev/null | wc -l)
    print -P "%F{cyan}║%f Profiles: $profile_count$(printf '%*s' $((50 - ${#profile_count} - 11)) '') %F{cyan}║%f"
    
    # 显示当前加载的配置（如果有）
    if [[ -n "${ENVSphere_ACTIVE_PROFILE:-}" ]]; then
        print -P "%F{cyan}║%f Active: $ENVSphere_ACTIVE_PROFILE$(printf '%*s' $((50 - ${#ENVSphere_ACTIVE_PROFILE} - 10)) '') %F{cyan}║%f"
    fi
    
    print -P "%F{cyan}╚══════════════════════════════════════════════════════╝%f"
}

# 添加帮助函数
envsphere_help() {
    cat << 'EOF'
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

函数:
  envsphere_status            显示EnvSphere状态
  envsphere_help              显示此帮助信息

更多信息: https://github.com/yourusername/EnvSphere
EOF
}

# 定期清理临时文件（可选）
# 可以添加到cron或使用zsh的定时任务功能
autoload -Uz add-zsh-hook
_envsphere_cleanup() {
    # 清理超过30天的临时文件
    find "${ENVSphere_DIR}/temp" -type f -mtime +30 -delete 2>/dev/null
}
add-zsh-hook zshexit _envsphere_cleanup

# 显示欢迎信息（仅在交互式shell中）
if [[ -o interactive && -z "${ENVSphere_QUIET:-}" ]]; then
    # 只在首次加载时显示
    if [[ -z "${ENVSphere_WELCOME_SHOWN:-}" ]]; then
        export ENVSphere_WELCOME_SHOWN=1
        
        # 检查是否有更新（可选）
        if [[ -f "${ENVSphere_DIR}/.last_update_check" ]]; then
            local last_check=$(cat "${ENVSphere_DIR}/.last_update_check")
            local current_time=$(date +%s)
            local time_diff=$((current_time - last_check))
            
            # 如果超过24小时，可以检查更新
            if [[ $time_diff -gt 86400 ]]; then
                # 可以在这里添加更新检查逻辑
                date +%s > "${ENVSphere_DIR}/.last_update_check"
            fi
        else
            date +%s > "${ENVSphere_DIR}/.last_update_check"
        fi
    fi
fi