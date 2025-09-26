# EnvSphere 核心功能脚本
# 包含所有平台通用的核心函数

# 检查依赖
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -ne 0 ]]; then
        echo "错误: 缺少依赖: ${missing[*]}" >&2
        return 1
    fi
}

# 颜色输出函数
print_error() {
    echo -e "\033[31m错误: $*\033[0m" >&2
}

print_warning() {
    echo -e "\033[33m警告: $*\033[0m" >&2
}

print_info() {
    echo -e "\033[36m信息: $*\033[0m"
}

print_success() {
    echo -e "\033[32m✓ $*\033[0m"
}

# 文件操作
backup_file() {
    local file="$1"
    local backup_suffix="${2:-.backup.$(date +%Y%m%d_%H%M%S)}"
    
    if [[ -f "$file" ]]; then
        cp "$file" "${file}${backup_suffix}"
        echo "已备份: ${file}${backup_suffix}"
    fi
}

# 安全地编辑文件
safe_edit() {
    local file="$1"
    local temp_file=$(mktemp)
    
    cp "$file" "$temp_file"
    "${EDITOR:-vim}" "$temp_file"
    
    if [[ -s "$temp_file" ]]; then
        mv "$temp_file" "$file"
        return 0
    else
        rm "$temp_file"
        print_error "文件为空，取消编辑"
        return 1
    fi
}

# 加载配置文件
load_profile() {
    local profile="$1"
    local profile_file="${ENVSphere_PROFILES_DIR}/${profile}.env"
    
    if [[ ! -f "$profile_file" ]]; then
        print_error "配置文件不存在: $profile"
        return 1
    fi
    
    # 备份当前环境
    local current_env=$(env | sort)
    
    # 加载新配置
    source "$profile_file"
    
    # 记录加载的配置
    export ENVSphere_ACTIVE_PROFILE="$profile"
    export ENVSphere_LAST_LOADED="$(date)"
    
    print_success "已加载配置: $profile"
    return 0
}

# 卸载配置
unload_profile() {
    local profile="${ENVSphere_ACTIVE_PROFILE:-}"
    
    if [[ -z "$profile" ]]; then
        print_warning "没有活动的配置"
        return 1
    fi
    
    # 这里可以实现更复杂的卸载逻辑
    unset ENVSphere_ACTIVE_PROFILE
    unset ENVSphere_LAST_LOADED
    
    print_info "已卸载配置: $profile"
    return 0
}

# 验证环境变量
validate_env_var() {
    local name="$1"
    local value="$2"
    
    # 检查变量名格式
    if ! [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        print_error "无效的环境变量名: $name"
        return 1
    fi
    
    # 检查是否包含敏感信息
    if echo "$name" | grep -qiE "(password|secret|key|token)"; then
        print_warning "变量名 '$name' 可能包含敏感信息"
    fi
    
    return 0
}

# 加密敏感数据
encrypt_value() {
    local value="$1"
    local key="${ENVSphere_ENCRYPTION_KEY:-}"
    
    if [[ -z "$key" ]]; then
        echo "$value"
        return 0
    fi
    
    # 使用openssl加密（需要安装）
    if command -v openssl &> /dev/null; then
        echo "$value" | openssl enc -aes-256-cbc -a -salt -pass pass:"$key" 2>/dev/null || echo "$value"
    else
        echo "$value"
    fi
}

# 解密敏感数据
decrypt_value() {
    local encrypted="$1"
    local key="${ENVSphere_ENCRYPTION_KEY:-}"
    
    if [[ -z "$key" ]]; then
        echo "$encrypted"
        return 0
    fi
    
    # 使用openssl解密
    if command -v openssl &> /dev/null; then
        echo "$encrypted" | openssl enc -aes-256-cbc -d -a -pass pass:"$key" 2>/dev/null || echo "$encrypted"
    else
        echo "$encrypted"
    fi
}

# 获取系统信息
get_system_info() {
    local os="unknown"
    local arch="unknown"
    local shell="unknown"
    
    # 检测操作系统
    case "$(uname -s)" in
        Darwin*) os="macos" ;;
        Linux*) os="linux" ;;
        CYGWIN*|MINGW*|MSYS*) os="windows" ;;
    esac
    
    # 检测架构
    case "$(uname -m)" in
        x86_64|amd64) arch="x64" ;;
        i386|i686) arch="x86" ;;
        arm64|aarch64) arch="arm64" ;;
        arm*) arch="arm" ;;
    esac
    
    # 检测Shell
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell="zsh"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        shell="bash"
    elif [[ "${SHELL##*/}" == "fish" ]]; then
        shell="fish"
    fi
    
    echo "$os $arch $shell"
}

# 检查更新
check_updates() {
    local current_version="${1:-}"
    local repo="MisonL/EnvSphere"
    
    if [[ -z "$current_version" ]] && [[ -f "${ENVSphere_DIR}/.version" ]]; then
        current_version=$(cat "${ENVSphere_DIR}/.version")
    fi
    
    # 使用GitHub API检查最新版本
    if command -v curl &> /dev/null; then
        local latest_version=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | \
                              grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
        
        if [[ -n "$latest_version" ]] && [[ "$latest_version" != "$current_version" ]]; then
            echo "发现新版本: $latest_version (当前: $current_version)"
            return 0
        fi
    fi
    
    return 1
}

# 记录日志
log_message() {
    local level="$1"
    local message="$2"
    local log_file="${ENVSphere_DIR}/logs/envsphere.log"
    
    mkdir -p "$(dirname "$log_file")"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$log_file"
}

# 性能监控
start_timer() {
    echo $(date +%s.%N)
}

stop_timer() {
    local start_time="$1"
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
    echo "${duration%.*}"
}