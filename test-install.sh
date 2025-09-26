#!/usr/bin/env bash

# EnvSphere 安装测试脚本

set -euo pipefail

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 测试函数
test_installation() {
    echo "正在测试EnvSphere安装..."
    
    # 1. 检查目录结构
    echo -n "检查目录结构... "
    if [[ -d "$HOME/.envsphere" ]] && \
       [[ -d "$HOME/.envsphere/bin" ]] && \
       [[ -d "$HOME/.envsphere/scripts" ]] && \
       [[ -d "$HOME/.envsphere/templates" ]] && \
       [[ -d "$HOME/.envsphere/profiles" ]]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
    
    # 2. 检查核心脚本
    echo -n "检查核心脚本... "
    if [[ -f "$HOME/.envsphere/bin/envsphere" ]] && \
       [[ -x "$HOME/.envsphere/bin/envsphere" ]]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
    
    # 3. 检查分析器脚本
    echo -n "检查分析器脚本... "
    if [[ -f "$HOME/.envsphere/scripts/env-analyzer.sh" ]] && \
       [[ -x "$HOME/.envsphere/scripts/env-analyzer.sh" ]]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
    
    # 4. 测试基本功能
    echo -n "测试基本功能... "
    if "$HOME/.envsphere/bin/envsphere" list >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
    
    # 5. 测试创建配置
    echo -n "测试创建配置... "
    if "$HOME/.envsphere/bin/envsphere" create test-config >/dev/null 2>&1 && \
       [[ -f "$HOME/.envsphere/profiles/test-config.env" ]]; then
        echo -e "${GREEN}✓${NC}"
        # 清理测试配置
        rm -f "$HOME/.envsphere/profiles/test-config.env"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
    
    # 6. 检查版本文件
    echo -n "检查版本文件... "
    if [[ -f "$HOME/.envsphere/.version" ]]; then
        echo -e "${GREEN}✓${NC} (版本: $(cat "$HOME/.envsphere/.version"))"
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${GREEN}所有测试通过！EnvSphere安装成功。${NC}"
    return 0
}

# 运行测试
test_installation