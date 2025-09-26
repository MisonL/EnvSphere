#!/usr/bin/env bash

# EnvSphere 交互式配置界面
# 提供用户友好的环境变量迁移界面

set -euo pipefail

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly GRAY='\033[0;90m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# 配置
readonly ENVSphere_DIR="${HOME}/.envsphere"
readonly ANALYSIS_FILE="${ENVSphere_DIR}/analysis/current_env_analysis.json"
readonly TEMP_DIR="${ENVSphere_DIR}/temp"
readonly MIGRATION_PLAN="${TEMP_DIR}/migration_plan.json"

# 状态变量
declare -A SELECTED_VARS
declare -A CATEGORY_SELECTIONS
declare -a CATEGORIES_ORDER
MIGRATION_MODE="ask"  # ask, keep, remove

# 初始化
check_prerequisites() {
    if [[ ! -f "$ANALYSIS_FILE" ]]; then
        echo "错误: 未找到环境变量分析文件"
        echo "请先运行: envsphere-analyze"
        exit 1
    fi
    
    mkdir -p "$TEMP_DIR"
}

# 打印彩色输出
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 清除屏幕并打印标题
clear_screen() {
    clear
    print_color "${CYAN}${BOLD}" "╔══════════════════════════════════════════════════════╗"
    print_color "${CYAN}${BOLD}" "║              EnvSphere 环境变量迁移向导               ║"
    print_color "${CYAN}${BOLD}" "╚══════════════════════════════════════════════════════╝"
    echo ""
}

# 获取分类列表
get_categories() {
    jq -r '.[].category' "$ANALYSIS_FILE" 2>/dev/null | sort | uniq
}

# 获取分类中的变量数量
get_category_count() {
    local category="$1"
    jq ".[] | select(.category == \"$category\") | .name" "$ANALYSIS_FILE" 2>/dev/null | wc -l
}

# 获取分类显示名称
get_category_display_name() {
    local category="$1"
    case "$category" in
        "api_keys") echo "🔑 API密钥与安全" ;;
        "cloud_services") echo "☁️  云服务配置" ;;
        "databases") echo "🗄️  数据库连接" ;;
        "development") echo "🛠️  开发工具" ;;
        "paths") echo "📁 路径配置" ;;
        "languages") echo "🌐 语言区域" ;;
        "editors") echo "📝 编辑器配置" ;;
        "shell") echo "🐚 Shell配置" ;;
        "system") echo "⚙️  系统信息" ;;
        "display") echo "🖥️  显示设置" ;;
        "proxy") echo "🔗 代理配置" ;;
        "colors") echo "🎨 颜色主题" ;;
        "urls") echo "🌐 URL地址" ;;
        "numbers") echo "🔢 数值配置" ;;
        "booleans") echo "✅ 布尔配置" ;;
        *) echo "📦 其他配置" ;;
    esac
}

# 显示分类选择菜单
show_category_menu() {
    clear_screen
    
    print_color "${BLUE}${BOLD}" "📋 步骤 1/3: 选择要迁移的配置分类"
    echo ""
    
    local categories=($(get_categories))
    local i=1
    
    for category in "${categories[@]}"; do
        local count=$(get_category_count "$category")
        local display_name=$(get_category_display_name "$category")
        local selected="${CATEGORY_SELECTIONS[$category]:-false}"
        
        local status_icon="⭕"
        if [[ "$selected" == "true" ]]; then
            status_icon="✅"
        fi
        
        printf "  ${BOLD}%2d.${RESET} %s %-30s ${GRAY}(%d 个变量)${RESET}\n" "$i" "$status_icon" "$display_name" "$count"
        CATEGORIES_ORDER[$i]="$category"
        ((i++))
    done
    
    echo ""
    echo "  ${BOLD} 0.${RESET} 继续到下一步"
    echo ""
    print_color "${GRAY}" "提示: 输入分类编号切换选择状态，输入0继续"
}

# 切换分类选择状态
toggle_category() {
    local index="$1"
    local category="${CATEGORIES_ORDER[$index]}"
    
    if [[ "${CATEGORY_SELECTIONS[$category]:-false}" == "true" ]]; then
        CATEGORY_SELECTIONS[$category]="false"
    else
        CATEGORY_SELECTIONS[$category]="true"
    fi
}

# 获取选中的变量列表
get_selected_variables() {
    local selected_categories=()
    
    for category in "${!CATEGORY_SELECTIONS[@]}"; do
        if [[ "${CATEGORY_SELECTIONS[$category]}" == "true" ]]; then
            selected_categories+=("$category")
        fi
    done
    
    if [[ ${#selected_categories[@]} -eq 0 ]]; then
        echo ""
        return
    fi
    
    # 构建jq查询
    local query=".["
    local first=true
    for category in "${selected_categories[@]}"; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            query+=" or "
        fi
        query+="select(.category == \"$category\")"
    done
    query+="]"
    
    jq -r "$query" "$ANALYSIS_FILE" 2>/dev/null
}

# 显示变量详细选择界面
show_variable_selection() {
    clear_screen
    
    local selected_vars=$(get_selected_variables)
    if [[ -z "$selected_vars" ]]; then
        print_color "${YELLOW}" "⚠️  没有选择任何分类"
        echo ""
        read -p "按回车键返回分类选择..."
        return 1
    fi
    
    print_color "${BLUE}${BOLD}" "🔍 步骤 2/3: 选择具体的环境变量"
    echo ""
    
    # 按分类分组显示变量
    local current_category=""
    local i=1
    
    while IFS= read -r var_json; do
        if [[ -n "$var_json" ]]; then
            local name=$(echo "$var_json" | jq -r '.name')
            local value=$(echo "$var_json" | jq -r '.value')
            local category=$(echo "$var_json" | jq -r '.category')
            local sensitive=$(echo "$var_json" | jq -r '.sensitive')
            
            # 显示分类标题
            if [[ "$category" != "$current_category" ]]; then
                current_category="$category"
                echo ""
                print_color "${PURPLE}${BOLD}" "$(get_category_display_name "$category"):"
            fi
            
            # 显示变量信息
            local status_icon="⭕"
            if [[ "${SELECTED_VARS[$name]:-false}" == "true" ]]; then
                status_icon="✅"
            fi
            
            local value_display="$value"
            if [[ "$sensitive" == "true" ]]; then
                value_display="${GRAY}********${RESET}"
            elif [[ ${#value} -gt 50 ]]; then
                value_display="${value:0:47}..."
            fi
            
            printf "  ${BOLD}%2d.${RESET} %s ${YELLOW}%-25s${RESET} = %s\n" "$i" "$status_icon" "$name" "$value_display"
            
            # 存储变量信息
            SELECTED_VARS["${i}_name"]="$name"
            SELECTED_VARS["${i}_value"]="$value"
            ((i++))
        fi
    done <<< "$selected_vars"
    
    echo ""
    echo "  ${BOLD} 0.${RESET} 继续到下一步"
    echo ""
    print_color "${GRAY}" "提示: 输入变量编号切换选择状态，输入0继续"
    
    return 0
}

# 切换变量选择状态
toggle_variable() {
    local index="$1"
    local var_name="${SELECTED_VARS["${index}_name"]}"
    
    if [[ "${SELECTED_VARS[$var_name]:-false}" == "true" ]]; then
        SELECTED_VARS[$var_name]="false"
    else
        SELECTED_VARS[$var_name]="true"
    fi
}

# 显示迁移选项
show_migration_options() {
    clear_screen
    
    print_color "${BLUE}${BOLD}" "⚙️  步骤 3/3: 配置迁移选项"
    echo ""
    
    # 统计选中的变量
    local selected_count=0
    for key in "${!SELECTED_VARS[@]}"; do
        if [[ "$key" != *"_name" && "$key" != *"_value" && "${SELECTED_VARS[$key]}" == "true" ]]; then
            ((selected_count++))
        fi
    done
    
    print_color "${GREEN}" "📊 将要迁移 ${selected_count} 个环境变量"
    echo ""
    
    # 迁移模式选择
    print_color "${PURPLE}" "选择原配置文件处理方式:"
    echo ""
    echo "  1. 询问每个变量 (${BOLD}推荐${RESET})"
    echo "     - 逐个确认是否从原配置中移除"
    echo ""
    echo "  2. 保留所有原配置"
    echo "     - 不修改现有配置文件"
    echo ""
    echo "  3. 移除所有已迁移的变量"
    echo "     - 自动清理原配置文件"
    echo ""
    
    # 显示当前选择
    case "$MIGRATION_MODE" in
        "ask")
            print_color "${GREEN}" "当前选择: 询问每个变量"
            ;;
        "keep")
            print_color "${GREEN}" "当前选择: 保留所有原配置"
            ;;
        "remove")
            print_color "${GREEN}" "当前选择: 移除所有已迁移的变量"
            ;;
    esac
    
    echo ""
    read -p "请选择 (1-3) 或直接按回车确认: " choice
    
    case "$choice" in
        1) MIGRATION_MODE="ask" ;;
        2) MIGRATION_MODE="keep" ;;
        3) MIGRATION_MODE="remove" ;;
        "") return 0 ;;
        *) print_color "${RED}" "无效选择"; sleep 1; show_migration_options ;;
    esac
}

# 生成分类选择界面
category_selection_loop() {
    while true; do
        show_category_menu
        
        read -p "请选择 (输入编号): " choice
        
        if [[ "$choice" == "0" ]]; then
            break
        elif [[ -n "${CATEGORIES_ORDER[$choice]}" ]]; then
            toggle_category "$choice"
        else
            print_color "${RED}" "无效选择"
            sleep 0.5
        fi
    done
}

# 生成变量选择界面
variable_selection_loop() {
    while true; do
        if ! show_variable_selection; then
            return 1
        fi
        
        read -p "请选择 (输入编号): " choice
        
        if [[ "$choice" == "0" ]]; then
            break
        elif [[ -n "${SELECTED_VARS["${choice}_name"]}" ]]; then
            toggle_variable "$choice"
        else
            print_color "${RED}" "无效选择"
            sleep 0.5
        fi
    done
    
    return 0
}

# 执行迁移
execute_migration() {
    clear_screen
    
    print_color "${BLUE}${BOLD}" "🚀 正在执行环境变量迁移..."
    echo ""
    
    # 创建迁移计划
    create_migration_plan
    
    # 执行迁移
    if [[ "$MIGRATION_MODE" == "ask" ]]; then
        execute_migration_with_prompts
    else
        execute_migration_auto
    fi
    
    echo ""
    print_color "${GREEN}${BOLD}" "✨ 迁移完成！"
    echo ""
    print_color "${CYAN}" "您现在可以使用以下命令管理环境变量:"
    echo "  envsphere list          # 查看配置"
    echo "  envsphere load <name>   # 加载配置"
    echo ""
    
    # 显示迁移结果
    local migrated_count=0
    for key in "${!SELECTED_VARS[@]}"; do
        if [[ "$key" != *"_name" && "$key" != *"_value" && "${SELECTED_VARS[$key]}" == "true" ]]; then
            ((migrated_count++))
        fi
    done
    
    if [[ $migrated_count -gt 0 ]]; then
        print_color "${GREEN}" "成功迁移了 $migrated_count 个环境变量到EnvSphere配置中。"
        echo ""
        print_color "${YELLOW}" "提示: 您可以随时使用 'envsphere-migrate' 重新运行迁移向导。"
    fi
}

# 创建迁移计划
create_migration_plan() {
    local plan_file="${MIGRATION_PLAN}"
    
    # 创建JSON格式的迁移计划
    echo "{" > "$plan_file"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$plan_file"
    echo "  \"mode\": \"$MIGRATION_MODE\"," >> "$plan_file"
    echo "  \"variables\": [" >> "$plan_file"
    
    local first=true
    for key in "${!SELECTED_VARS[@]}"; do
        if [[ "$key" != *"_name" && "$key" != *"_value" && "${SELECTED_VARS[$key]}" == "true" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo "," >> "$plan_file"
            fi
            
            # 查找完整的变量信息
            local var_info=$(jq ".[] | select(.name == \"$key\")" "$ANALYSIS_FILE" 2>/dev/null)
            echo "    $var_info" >> "$plan_file"
        fi
    done
    
    echo "  ]" >> "$plan_file"
    echo "}" >> "$plan_file"
}

# 带提示的执行迁移
execute_migration_with_prompts() {
    # 这里将实现具体的迁移逻辑
    print_color "${YELLOW}" "执行带提示的迁移..."
    # TODO: 实现具体的迁移逻辑
}

# 自动执行迁移
execute_migration_auto() {
    # 这里将实现自动迁移逻辑
    print_color "${YELLOW}" "执行自动迁移..."
    # TODO: 实现具体的迁移逻辑
}

# 主交互流程
main_interactive() {
    check_prerequisites
    
    # 步骤1: 分类选择
    category_selection_loop
    
    # 步骤2: 变量选择
    if ! variable_selection_loop; then
        # 用户没有选择任何变量，重新开始
        main_interactive
        return
    fi
    
    # 步骤3: 迁移选项
    show_migration_options
    
    # 确认和执行
    clear_screen
    print_color "${BLUE}${BOLD}" "📋 迁移配置确认"
    echo ""
    
    # 显示选择的摘要
    local selected_vars=()
    for key in "${!SELECTED_VARS[@]}"; do
        if [[ "$key" != *"_name" && "$key" != *"_value" && "${SELECTED_VARS[$key]}" == "true" ]]; then
            selected_vars+=("$key")
        fi
    done
    
    print_color "${GREEN}" "将迁移 ${#selected_vars[@]} 个环境变量"
    print_color "${GRAY}" "迁移模式: $MIGRATION_MODE"
    echo ""
    
    read -p "确认执行迁移? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        execute_migration
    else
        print_color "${YELLOW}" "迁移已取消"
    fi
}

# 主函数
main() {
    case "${1:-interactive}" in
        interactive)
            main_interactive
            ;;
        auto)
            # 自动模式，使用默认设置
            MIGRATION_MODE="keep"
            # 选择所有变量
            # TODO: 实现自动选择逻辑
            execute_migration
            ;;
        *)
            echo "EnvSphere 交互式配置界面"
            echo ""
            echo "用法:"
            echo "  $0 interactive    # 启动交互式向导"
            echo "  $0 auto           # 自动模式"
            ;;
    esac
}

# 运行主函数
main "$@"