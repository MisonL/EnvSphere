#!/usr/bin/env bash

# EnvSphere 环境变量分析器
# 自动分析当前环境变量并按类别分组

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

# 分析结果存储目录
readonly ANALYSIS_DIR="${HOME}/.envsphere/analysis"
readonly ANALYSIS_FILE="${ANALYSIS_DIR}/current_env_analysis.json"
readonly CATEGORIES_FILE="${ANALYSIS_DIR}/categories.txt"

# 环境变量分类定义
declare -A CATEGORY_PATTERNS=(
    ["api_keys"]="API|SECRET|TOKEN|KEY|PASSWORD|PWD|AUTH"
    ["cloud_services"]="AWS|AZURE|GCP|CLOUD|ALIBABA|TENCENT"
    ["databases"]="DB|DATABASE|MYSQL|POSTGRES|MONGO|REDIS|SQL"
    ["development"]="NODE|PYTHON|JAVA|GO|RUST|DEVELOPMENT|DEBUG|BUILD"
    ["paths"]="PATH|HOME|ROOT|DIR|FOLDER|BIN|LIB|INCLUDE"
    ["languages"]="LANG|LC_|LOCALE|CHARSET|ENCODING"
    ["editors"]="EDITOR|PAGER|VISUAL|IDE"
    ["shell"]="SHELL|PS1|PROMPT|HIST|TERM"
    ["system"]="USER|HOSTNAME|MAIL|LOGNAME|TMP|TEMP"
    ["display"]="DISPLAY|X11|WAYLAND|SCREEN"
    ["proxy"]="PROXY|HTTP_PROXY|HTTPS_PROXY|FTP_PROXY"
    ["colors"]="COLOR|CLICOLOR|LS_COLORS"
)

# 创建分析目录
init_analysis_dir() {
    mkdir -p "${ANALYSIS_DIR}"
}

# 获取当前所有环境变量
get_all_env_vars() {
    env | sort
}

# 从shell配置文件中提取导出的变量
get_shell_exported_vars() {
    local shell_configs=("$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
    local exported_vars=""
    
    for config in "${shell_configs[@]}"; do
        if [[ -f "$config" ]]; then
            # 提取export语句中的变量名
            local vars=$(grep -E '^\s*export\s+[A-Za-z_][A-Za-z0-9_]*=' "$config" 2>/dev/null | \
                        sed -E 's/^\s*export\s+([A-Za-z_][A-Za-z0-9_]*)=.*/\1/' | sort -u)
            exported_vars+="${vars}\n"
        fi
    done
    
    echo -e "$exported_vars" | grep -v '^$' | sort -u
}

# 分类环境变量
classify_variable() {
    local var_name="$1"
    local var_value="$2"
    
    # 检查每个分类的匹配模式
    for category in "${!CATEGORY_PATTERNS[@]}"; do
        local pattern="${CATEGORY_PATTERNS[$category]}"
        if echo "$var_name" | grep -qiE "$pattern"; then
            echo "$category"
            return
        fi
    done
    
    # 检查变量值是否包含特定模式
    if echo "$var_value" | grep -qiE "(http|https|ftp)://"; then
        echo "urls"
    elif echo "$var_value" | grep -qiE "^[0-9]+$"; then
        echo "numbers"
    elif echo "$var_value" | grep -qiE "(true|false|yes|no|1|0)$"; then
        echo "booleans"
    else
        echo "other"
    fi
}

# 分析单个环境变量
analyze_variable() {
    local line="$1"
    local name="${line%%=*}"
    local value="${line#*=}"
    
    # 跳过系统关键变量
    case "$name" in
        "PWD"|"OLDPWD"|"SHLVL"|"_"|"PS1"|"PS2"|"IFS")
            return
            ;;
    esac
    
    local category=$(classify_variable "$name" "$value")
    local sensitive="false"
    
    # 检测是否包含敏感信息
    if echo "$name" | grep -qiE "(password|secret|key|token|private)"; then
        sensitive="true"
    fi
    
    # 输出JSON格式的分析结果
    cat << EOF
{
    "name": "$name",
    "value": "$value",
    "category": "$category",
    "sensitive": $sensitive,
    "size": ${#value},
    "contains_path": $(echo "$value" | grep -q ":" && echo "true" || echo "false"),
    "is_path": $(echo "$name" | grep -qi "path" && echo "true" || echo "false")
}
EOF
}

# 执行完整分析
perform_analysis() {
    print_color "${BLUE}" "正在分析环境变量..."
    
    init_analysis_dir
    
    # 获取所有环境变量
    local all_vars=$(get_all_env_vars)
    local shell_vars=$(get_shell_exported_vars)
    
    # 创建JSON数组开始
    echo "[" > "${ANALYSIS_FILE}.tmp"
    local first=true
    
    # 分析每个变量
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo "," >> "${ANALYSIS_FILE}.tmp"
            fi
            
            analyze_variable "$line" >> "${ANALYSIS_FILE}.tmp"
        fi
    done <<< "$all_vars"
    
    # 关闭JSON数组
    echo "" >> "${ANALYSIS_FILE}.tmp"
    echo "]" >> "${ANALYSIS_FILE}.tmp"
    
    # 格式化JSON
    if command -v jq &> /dev/null; then
        jq '.' "${ANALYSIS_FILE}.tmp" > "${ANALYSIS_FILE}"
    else
        mv "${ANALYSIS_FILE}.tmp" "${ANALYSIS_FILE}"
    fi
    
    # 生成分类统计
    generate_category_stats
    
    print_color "${GREEN}" "✓ 环境变量分析完成"
}

# 生成分类统计
generate_category_stats() {
    local categories=$(jq -r '.[].category' "${ANALYSIS_FILE}" 2>/dev/null | sort | uniq -c | sort -nr)
    
    if [[ -n "$categories" ]]; then
        echo "$categories" > "${CATEGORIES_FILE}"
    fi
}

# 获取特定分类的变量
get_variables_by_category() {
    local category="$1"
    if command -v jq &> /dev/null; then
        jq -r ".[] | select(.category == \"$category\") | .name" "${ANALYSIS_FILE}" 2>/dev/null
    else
        # 如果没有jq，使用简单的文本处理
        grep -E '"category":\s*"'"$category"'"' "${ANALYSIS_FILE}" 2>/dev/null | \
        grep -B5 -A1 '"category":' | grep '"name":' | sed 's/.*"name":\s*"\([^"]*\)".*/\1/'
    fi
}

# 显示分析结果摘要
show_analysis_summary() {
    print_color "${CYAN}${BOLD}" "环境变量分析摘要"
    echo "================================"
    
    if [[ -f "${CATEGORIES_FILE}" ]]; then
        while IFS= read -r line; do
            local count=$(echo "$line" | awk '{print $1}')
            local category=$(echo "$line" | awk '{print $2}')
            local category_name=$(get_category_display_name "$category")
            printf "  ${YELLOW}%-20s${RESET}: %d 个变量\n" "$category_name" "$count"
        done < "${CATEGORIES_FILE}"
    fi
    
    echo ""
    
    # 显示敏感变量警告
    local sensitive_count=$(jq '.[] | select(.sensitive == true) | .name' "${ANALYSIS_FILE}" 2>/dev/null | wc -l)
    if [[ $sensitive_count -gt 0 ]]; then
        print_color "${RED}" "⚠️  检测到 ${sensitive_count} 个可能包含敏感信息的变量"
    fi
}

# 获取分类的显示名称
get_category_display_name() {
    local category="$1"
    case "$category" in
        "api_keys") echo "API密钥" ;;
        "cloud_services") echo "云服务" ;;
        "databases") echo "数据库" ;;
        "development") echo "开发工具" ;;
        "paths") echo "路径配置" ;;
        "languages") echo "语言区域" ;;
        "editors") echo "编辑器" ;;
        "shell") echo "Shell配置" ;;
        "system") echo "系统信息" ;;
        "display") echo "显示配置" ;;
        "proxy") echo "代理设置" ;;
        "colors") echo "颜色配置" ;;
        "urls") echo "URL地址" ;;
        "numbers") echo "数值配置" ;;
        "booleans") echo "布尔配置" ;;
        *) echo "其他" ;;
    esac
}

# 导出特定分类的配置文件
export_category_to_env() {
    local category="$1"
    local output_file="$2"
    
    print_color "${BLUE}" "正在导出 ${category} 分类到 ${output_file}..."
    
    {
        echo "# EnvSphere Profile - $(date)"
        echo "# 分类: $(get_category_display_name "$category")"
        echo ""
        
        jq -r ".[] | select(.category == \"$category\") | \"export \(.name)=\\\"\(.value)\\\"\"" "${ANALYSIS_FILE}" 2>/dev/null
        
    } > "$output_file"
    
    print_color "${GREEN}" "✓ 导出完成: ${output_file}"
}

# 主函数
main() {
    local command="${1:-analyze}"
    
    case "$command" in
        analyze)
            perform_analysis
            show_analysis_summary
            ;;
        summary)
            if [[ -f "${ANALYSIS_FILE}" ]]; then
                show_analysis_summary
            else
                print_color "${RED}" "错误: 找不到分析结果文件，请先运行 analyze"
                exit 1
            fi
            ;;
        export)
            local category="$2"
            local output_file="$3"
            if [[ -z "$category" || -z "$output_file" ]]; then
                echo "用法: $0 export <category> <output_file>"
                exit 1
            fi
            export_category_to_env "$category" "$output_file"
            ;;
        list-categories)
            if [[ -f "${CATEGORIES_FILE}" ]]; then
                cat "${CATEGORIES_FILE}"
            else
                print_color "${RED}" "错误: 找不到分类统计文件"
                exit 1
            fi
            ;;
        *)
            echo "EnvSphere 环境变量分析器"
            echo ""
            echo "用法:"
            echo "  $0 analyze              # 执行完整分析"
            echo "  $0 summary              # 显示分析摘要"
            echo "  $0 export <cat> <file>  # 导出分类到文件"
            echo "  $0 list-categories      # 列出所有分类"
            echo ""
            echo "可用的分类:"
            for cat in "${!CATEGORY_PATTERNS[@]}"; do
                echo "  - $cat: $(get_category_display_name "$cat")"
            done
            echo "  - urls, numbers, booleans, other"
            ;;
    esac
}

# 运行主函数
main "$@"