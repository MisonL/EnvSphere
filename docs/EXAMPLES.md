# EnvSphere 示例和用例

本文件提供了EnvSphere的实际使用示例和最佳实践。

## 基础示例

### 1. 创建开发环境配置

```bash
# 创建开发环境配置
envsphere create development

# 编辑配置文件
vim ~/.envsphere/profiles/development.env
```

配置文件内容示例：
```bash
# 开发环境配置
export NODE_ENV="development"
export DEBUG="app:*"
export API_BASE_URL="http://localhost:3000"
export DATABASE_URL="postgres://localhost:5432/dev_db"
export REDIS_URL="redis://localhost:6379"

# 开发工具
export EDITOR="code --wait"
export BROWSER="google-chrome"

# 性能调优
export UV_THREADPOOL_SIZE=16
export NODE_OPTIONS="--max-old-space-size=4096"
```

### 2. 创建生产环境配置

```bash
envsphere create production
```

配置文件内容示例：
```bash
# 生产环境配置
export NODE_ENV="production"
export PORT="8080"
export API_BASE_URL="https://api.example.com"

# 数据库（使用环境变量替换敏感信息）
export DATABASE_URL="${PROD_DATABASE_URL}"
export REDIS_URL="${PROD_REDIS_URL}"

# 监控和日志
export LOG_LEVEL="info"
export ENABLE_METRICS="true"
export ENABLE_TRACING="true"

# 安全配置
export FORCE_HTTPS="true"
export ENABLE_CSRF="true"
```

### 3. API密钥管理

```bash
envsphere create api-keys
```

配置文件内容示例：
```bash
# API密钥配置
# ⚠️ 注意：不要将包含真实密钥的文件提交到版本控制

# 第三方服务
export GITHUB_TOKEN="${GITHUB_TOKEN}"
export OPENAI_API_KEY="${OPENAI_API_KEY}"
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"

# 云服务
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="us-west-2"

# 数据库
export DATABASE_PASSWORD="${DATABASE_PASSWORD}"
```

## 高级用例

### 1. 项目特定配置

为每个项目创建独立的配置：

```bash
# 项目Alpha
mkdir ~/projects/alpha
cd ~/projects/alpha
envsphere create alpha-project

# 在项目目录中创建自动加载标记
echo "alpha-project" > .envsphere
```

项目配置示例（`~/.envsphere/profiles/alpha-project.env`）：
```bash
# Alpha项目配置
export PROJECT_ROOT="$HOME/projects/alpha"
export PROJECT_NAME="alpha"
export PROJECT_ENV="development"

# 项目特定的路径
export PATH="$PROJECT_ROOT/bin:$PATH"
export PYTHONPATH="$PROJECT_ROOT/src:$PYTHONPATH"

# 项目数据库
export PROJECT_DB_URL="postgres://localhost:5432/alpha_dev"

# 项目API密钥
export ALPHA_API_KEY="${ALPHA_API_KEY}"
```

### 2. 团队配置共享

创建团队共享的基础配置：

```bash
# 创建团队基础配置
envsphere create team-base

# 创建个人覆盖配置
envsphere create personal-overrides
```

团队基础配置（`team-base.env`）：
```bash
# 团队共享配置
export TEAM_NAME="awesome-team"
export TEAM_SLACK_CHANNEL="#dev-general"
export TEAM_CODE_REVIEW_CHANNEL="#code-review"

# 共享的开发工具版本
export NODE_VERSION="18.17.0"
export PYTHON_VERSION="3.11"
export GO_VERSION="1.21"

# 共享的服务地址
export TEAM_DEV_API="https://dev-api.team.internal"
export TEAM_STAGING_API="https://staging-api.team.internal"
```

个人覆盖配置（`personal-overrides.env`）：
```bash
# 个人偏好设置
export EDITOR="vim"
export PAGER="less"
export SHELL="/bin/zsh"

# 个人别名（需要shell支持）
if [[ -n "$ZSH_VERSION" ]]; then
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi
```

### 3. 多环境切换脚本

创建一个脚本来快速切换环境：

```bash
#!/bin/bash
# env-switcher.sh

case "$1" in
    dev)
        envsphere unload
        envsphere load development
        envsphere load api-keys
        echo "切换到开发环境"
        ;;
    staging)
        envsphere unload
        envsphere load staging
        envsphere load api-keys
        echo "切换到预发布环境"
        ;;
    prod)
        envsphere unload
        read -p "确定要切换到生产环境吗? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            envsphere load production
            envsphere load api-keys
            echo "切换到生产环境"
        fi
        ;;
    *)
        echo "用法: $0 {dev|staging|prod}"
        exit 1
        ;;
esac
```

### 4. CI/CD 集成

在CI/CD管道中使用EnvSphere：

```yaml
# GitHub Actions 示例
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Install EnvSphere
      run: |
        curl -fsSL https://raw.githubusercontent.com/yourusername/EnvSphere/main/install.sh | bash
        echo "$HOME/.envsphere/bin" >> $GITHUB_PATH
    
    - name: Load Production Config
      run: |
        envsphere load production
        envsphere load api-keys
      env:
        # 从GitHub Secrets传递敏感信息
        PROD_DATABASE_URL: ${{ secrets.PROD_DATABASE_URL }}
        PROD_API_KEY: ${{ secrets.PROD_API_KEY }}
    
    - name: Deploy Application
      run: |
        npm install
        npm run build
        npm run deploy
```

### 5. Docker 集成

在Docker容器中使用EnvSphere：

```dockerfile
FROM node:18

# 安装EnvSphere
RUN curl -fsSL https://raw.githubusercontent.com/yourusername/EnvSphere/main/install.sh | bash

# 复制配置文件
COPY profiles/ /root/.envsphere/profiles/

# 加载配置
RUN echo 'source ~/.envsphere/scripts/bash-integration.sh' >> ~/.bashrc
RUN echo 'envsphere load docker' >> ~/.bashrc

WORKDIR /app
COPY . .

CMD ["npm", "start"]
```

## 最佳实践

### 1. 敏感信息管理

```bash
# 不要直接在配置文件中存储敏感信息
# ❌ 错误
echo 'export API_KEY="sk-1234567890"' >> ~/.envsphere/prod.env

# ✅ 正确 - 使用环境变量引用
echo 'export API_KEY="${API_KEY}"' >> ~/.envsphere/prod.env

# 在加载配置前设置敏感信息
export API_KEY="sk-1234567890"
envsphere load prod
```

### 2. 配置继承

```bash
# 创建基础配置
envsphere create base

# 创建继承基础配置的环境
cat > ~/.envsphere/profiles/web-project.env << EOF
# 基础配置
source ~/.envsphere/profiles/base.env

# 项目特定配置
export PROJECT_TYPE="web"
export FRAMEWORK="react"
export BUILD_TOOL="vite"
EOF
```

### 3. 版本控制

```bash
# 创建版本化的配置
envsphere create myproject-v1.0
envsphere create myproject-v2.0

# 使用符号链接管理当前版本
ln -s ~/.envsphere/profiles/myproject-v2.0.env ~/.envsphere/profiles/myproject-current.env

# 切换版本
envsphere load myproject-current
```

### 4. 团队协作

```bash
# 创建团队配置模板
mkdir -p ~/team-configs
cat > ~/team-configs/template.env << EOF
# 团队: TEAM_NAME
# 项目: PROJECT_NAME
# 环境: ENVIRONMENT

# 基础设置
export TEAM_NAME="TEAM_NAME"
export PROJECT_NAME="PROJECT_NAME"
export ENVIRONMENT="ENVIRONMENT"

# API配置
export API_BASE_URL="https://API_ENV.team.internal"
export API_VERSION="v1"

# 数据库
export DB_HOST="DB_ENV-db.team.internal"
export DB_PORT="5432"
export DB_NAME="PROJECT_NAME_DB_ENV"

# 其他配置...
EOF

# 生成团队配置
sed 's/TEAM_NAME/awesome-team/g; s/PROJECT_NAME/alpha/g; s/ENVIRONMENT/dev/g; s/API_ENV/dev/g; s/DB_ENV/dev/g' ~/team-configs/template.env > ~/.envsphere/profiles/alpha-team-dev.env
```

## 故障排除示例

### 1. 配置冲突解决

```bash
# 检查当前加载的配置
envsphere status

# 卸载所有配置
envsphere unload

# 重新加载需要的配置
envsphere load base
envsphere load project-specific
```

### 2. 路径问题

```bash
# 检查PATH变量
echo $PATH | tr ':' '\n' | grep -i envsphere

# 如果PATH中有多余的条目，清理它们
export PATH=$(echo $PATH | sed 's|:$HOME/.envsphere/bin:||g')

# 重新加载shell配置
source ~/.zshrc  # 或 ~/.bashrc
```

### 3. 权限问题

```bash
# 修复权限
chmod -R 755 ~/.envsphere
chmod -R 644 ~/.envsphere/profiles/*.env
chmod +x ~/.envsphere/bin/envsphere
chmod +x ~/.envsphere/scripts/*.sh
```

## 性能优化

### 1. 延迟加载

```bash
# 在shell配置中使用延迟加载
# ~/.zshrc
eval "$(envsphere init -)"

# 或者手动加载
envsphere() {
    if [[ "$1" == "load" ]]; then
        source ~/.envsphere/profiles/$2.env
    fi
}
```

### 2. 配置缓存

```bash
# 创建配置缓存
envsphere load development
env > ~/.envsphere/cache/development.env.cache

# 快速恢复
cp ~/.envsphere/cache/development.env.cache /tmp/current.env
source /tmp/current.env
```

## 更多资源

- [安装指南](INSTALL.md)
- [配置参考](CONFIG.md)
- [API文档](API.md)
- [故障排除](TROUBLESHOOTING.md)