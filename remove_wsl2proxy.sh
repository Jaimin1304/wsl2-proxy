#!/bin/bash

# 默认值
REMOVE_APT=false
REMOVE_DOCKER=false
REMOVE_GIT=false
REMOVE_SSH=false
REMOVE_NPM=false  # 新增 npm 移除选项

# 显示帮助信息
usage() {
    echo "Usage: $0 [-a] [-d] [-g] [-s] [-n]"
    echo "  -a    Remove apt proxy"
    echo "  -d    Remove Docker proxy"
    echo "  -g    Remove Git proxy"
    echo "  -s    Remove SSH proxy"
    echo "  -n    Remove NPM proxy"  # 新增帮助信息
    exit 1
}

# 解析命令行参数
while getopts "adgsn" opt; do  # 添加 n 选项
    case ${opt} in
        a )
            REMOVE_APT=true
            ;;
        d )
            REMOVE_DOCKER=true
            ;;
        g )
            REMOVE_GIT=true
            ;;
        s )
            REMOVE_SSH=true
            ;;
        n )  # 新增 npm 选项处理
            REMOVE_NPM=true
            ;;
        * )
            usage
            ;;
    esac
done

# 移除环境变量
echo "Removing environment variables..."
sed -i '/export http_proxy=/d' ~/.bashrc
sed -i '/export https_proxy=/d' ~/.bashrc
sed -i '/export no_proxy=/d' ~/.bashrc

# 重新加载 .bashrc
source ~/.bashrc

# 移除 apt 代理
if [ "$REMOVE_APT" = true ]; then
    echo "Removing apt proxy..."
    APT_CONF_DIR="/etc/apt/apt.conf.d"
    APT_PROXY_CONF="$APT_CONF_DIR/proxy.conf"
    
    if [ -f "$APT_PROXY_CONF" ]; then
        sudo rm -f "$APT_PROXY_CONF"
    fi
fi

# 移除 Docker 代理
if [ "$REMOVE_DOCKER" = true ]; then
    echo "Removing Docker proxy..."
    DOCKER_SERVICE_DIR="/etc/systemd/system/docker.service.d"
    DOCKER_PROXY_CONF="$DOCKER_SERVICE_DIR/http-proxy.conf"
    
    if [ -f "$DOCKER_PROXY_CONF" ]; then
        sudo rm -f "$DOCKER_PROXY_CONF"
    fi
    
    # 重新加载并重启 Docker 服务
    sudo systemctl daemon-reload
    sudo systemctl restart docker
fi

# 移除 Git 代理
if [ "$REMOVE_GIT" = true ]; then
    echo "Removing Git proxy..."
    git config --global --unset http.proxy
    git config --global --unset https.proxy
fi

# 移除 SSH 代理
if [ "$REMOVE_SSH" = true ]; then
    echo "Removing SSH proxy..."
    SSH_CONFIG_FILE="$HOME/.ssh/config"
    if [ -f "$SSH_CONFIG_FILE" ]; then
        sed -i '/Host github.com/,+4d' "$SSH_CONFIG_FILE"
    fi
fi

# 移除 NPM 代理
if [ "$REMOVE_NPM" = true ]; then
    echo "Removing NPM proxy..."
    # 移除 HTTP 和 HTTPS 代理配置
    npm config delete proxy
    npm config delete https-proxy
    # 移除 noproxy 配置
    npm config delete noproxy
    echo "NPM proxy configuration removed."
fi

echo "Proxy configurations removed."
