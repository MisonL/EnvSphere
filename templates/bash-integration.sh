#!/usr/bin/env bash

# EnvSphere Bash 集成模板
# 此文件将被添加到用户的 .bashrc 或 .bash_profile 中

# EnvSphere 配置
export ENVSphere_DIR="${HOME}/.envsphere"
export ENVSphere_PROFILES_DIR="${ENVSphere_DIR}/profiles"

# 如果EnvSphere未安装，则退出
[[ ! -d "$ENVSphere_DIR" ]] && return

# 加载EnvSphere核心函数
source "${ENVSphere_DIR}/scripts/envsphere-core.sh" 2>/dev/null || true

# Bash自动补全函数
_envsphere_completion() {
    local cur prev opts profiles
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # 基本命令
    opts="load list ls create new remove rm edit help -h --help"
    
    case "${COMP_CWORD}" in
        1)
            # 第一层补全：命令
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
        2)
            # 第二层补全：配置文件（仅对某些命令）
            case "${prev}" in
                load|remove|rm|edit)
                    if [[ -d "$ENVSphere_PROFILES_DIR" ]]; then
                        profiles=$(ls "$ENVSphere_PROFILES_DIR"/*.env 2>/dev/null | xargs -n 1 basename -s .env)
                        COMPREPLY=( $(compgen -W "${profiles}" -- ${cur}) )
                    fi
                    ;;
            esac
            ;;
    esac
}

# 注册自动补全
complete -F _envsphere_completion envsphere

# 创建alias
alias es='envsphere'
alias esls='envsphere list'
alias esload='envsphere load'
alias escreate='envsphere create'

# 快速加载常用配置（用户可以自定义）
alias load-dev='envsphere load development 2>/dev/null || echo "未找到 development 配置"'
alias load-prod='envsphere load production 2>/dev/null || echo "未找到 production 配置"'
alias load-api='envsphere load api-keys 2>/dev/null || echo "未找到 api-keys 配置"'

# Bash特有的功能

# 显示EnvSphere状态
envsphere_status() {
    cat << EOF
$(tput setaf 6)╔══════════════════════════════════════════════════════╗$(tput sgr0)
$(tput setaf 6)║$(tput sgr0) $(tput bold)EnvSphere Status$(tput sgr0) $(tput setaf 6)$(printf '%*s' $((45)) '')║$(tput sgr0)
$(tput setaf 6)╠══════════════════════════════════════════════════════╣$(tput sgr0)
EOF
    
    # 显示版本
    if [[ -f "${ENVSphere_DIR}/.version" ]]; then
        local version=$(cat "${ENVSphere_DIR}/.version")
        printf "$(tput setaf 6)║$(tput sgr0) Version: $version$(printf '%*s' $((50 - ${#version} - 10)) '') $(tput setaf 6)║$(tput sgr0)\n"
    fi
    
    # 显示配置文件数量
    local profile_count=$(ls -1 "$ENVSphere_PROFILES_DIR"/*.env 2>/dev/null | wc -l)
    printf "$(tput setaf 6)║$(tput sgr0) Profiles: $profile_count$(printf '%*s' $((50 - ${#profile_count} - 11)) '') $(tput setaf 6)║$(tput sgr0)\n"
    
    # 显示当前加载的配置（如果有）
    if [[ -n "${ENVSphere_ACTIVE_PROFILE:-}" ]]; then
        printf "$(tput setaf 6)║$(tput sgr0) Active: $ENVSphere_ACTIVE_PROFILE$(printf '%*s' $((50 - ${#ENVSphere_ACTIVE_PROFILE} - 10)) '') $(tput setaf 6)║$(tput sgr0)\n"
    fi
    
    cat << EOF
$(tput setaf 6)╚══════════════════════════════════════════════════════╝$(tput sgr0)
EOF
}

# Bash特有的命令历史功能
# 记录加载的配置
_envsphere_history_hook() {
    if [[ -n "${ENVSphere_ACTIVE_PROFILE:-}" ]]; then
        # 可以选择将加载的配置记录到历史文件中
        echo "# [EnvSphere] Loaded profile: $ENVSphere_ACTIVE_PROFILE" >> "${HOME}/.bash_history"
    fi
}

# 更智能的目录切换
# 当切换到特定目录时自动加载对应的配置
cd() {
    builtin cd "$@" || return
    
    # 检查当前目录是否有.envsphere文件
    if [[ -f ".envsphere" ]]; then
        local profile=$(cat .envsphere)
        if [[ -n "$profile" ]]; then
            envsphere load "$profile" 2>/dev/null
        fi
    fi
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

Bash特有功能:
  envsphere_status            显示EnvSphere状态
  cd <directory>              自动检测并加载.envsphere文件

更多信息: https://github.com/yourusername/EnvSphere
EOF
}

# PROMPT_COMMAND支持
# 可以在提示符中显示当前加载的配置
_envsphere_prompt_info() {
    if [[ -n "${ENVSphere_ACTIVE_PROFILE:-}" ]]; then
        # 可以自定义显示的格式
        echo " [${ENVSphere_ACTIVE_PROFILE}]"
    fi
}

# 可选：修改PS1以显示当前配置
# 取消注释以下行来启用
# if [[ -n "$PS1" ]]; then
#     PS1='\[\e[36m\]$(_envsphere_prompt_info)\[\e[0m\]'"$PS1"
# fi

# 定期清理临时文件
# 使用PROMPT_COMMAND来定期执行（每100次命令）
_envsphere_cleanup_counter=0
_envsphere_cleanup() {
    ((_envsphere_cleanup_counter++))
    if [[ $_envsphere_cleanup_counter -ge 100 ]]; then
        _envsphere_cleanup_counter=0
        # 清理超过30天的临时文件
        find "${ENVSphere_DIR}/temp" -type f -mtime +30 -delete 2>/dev/null || true
    fi
}

# 如果PROMPT_COMMAND已存在，则追加；否则设置
if [[ -n "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND="${PROMPT_COMMAND}; _envsphere_cleanup"
else
    PROMPT_COMMAND="_envsphere_cleanup"
fi

# 显示欢迎信息（仅在交互式shell中）
if [[ $- == *i* && -z "${ENVSphere_QUIET:-}" ]]; then
    # 只在首次加载时显示
    if [[ -z "${ENVSphere_WELCOME_SHOWN:-}" ]]; then
        export ENVSphere_WELCOME_SHOWN=1
        
        # 可以在这里添加欢迎消息或检查更新
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