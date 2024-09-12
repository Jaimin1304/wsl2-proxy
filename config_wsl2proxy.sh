#!/bin/bash

# 默认值
CONFIGURE_APT=false
CONFIGURE_DOCKER=false
CONFIGURE_GIT=false
CONFIGURE_SSH=false
HTTP_PROXY_PORT=1080
HTTPS_PROXY_PORT=1080

# 显示帮助信息
usage() {
    echo "Usage: $0 [-a] [-d] [-g] [-s] [-p PORT]"
    echo "  -a    Configure apt proxy"
    echo "  -d    Configure Docker proxy"
    echo "  -g    Configure Git proxy"
    echo "  -s    Configure SSH proxy"
    echo "  -p    Set proxy port (default: 1080)"
    exit 1
}

# 解析命令行参数
while getopts "adgsp:" opt; do
    case ${opt} in
    a)
        CONFIGURE_APT=true
        ;;
    d)
        CONFIGURE_DOCKER=true
        ;;
    g)
        CONFIGURE_GIT=true
        ;;
    s)
        CONFIGURE_SSH=true
        ;;
    p)
        HTTP_PROXY_PORT=$OPTARG
        HTTPS_PROXY_PORT=$OPTARG
        ;;
    *)
        usage
        ;;
    esac
done

# 获取 Windows 宿主机的 IP 地址
WINDOWS_HOST_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{ print $2 }')

# 检查是否成功获取 IP 地址
if [ -z "$WINDOWS_HOST_IP" ]; then
    echo "Unable to retrieve the IP address of the Windows host. Please check if the /etc/resolv.conf file exists and contains a nameserver entry."
    exit 1
fi

# 配置环境变量
echo "Configuring environment variables..."
BASHRC_CONTENT=$(
    cat <<EOF
export http_proxy="http://$WINDOWS_HOST_IP:$HTTP_PROXY_PORT"
export https_proxy="http://$WINDOWS_HOST_IP:$HTTPS_PROXY_PORT"
export no_proxy="localhost,127.0.0.1,::1"
EOF
)

# 检查是否已存在相同的代理设置，避免重复添加
if ! grep -q "$BASHRC_CONTENT" ~/.bashrc; then
    echo "$BASHRC_CONTENT" >>~/.bashrc
fi

# 重新加载 .bashrc
source ~/.bashrc

# 配置 apt 代理
if [ "$CONFIGURE_APT" = true ]; then
    echo "Configuring apt proxy..."
    APT_CONF_DIR="/etc/apt/apt.conf.d"
    APT_PROXY_CONF="$APT_CONF_DIR/proxy.conf"

    if [ ! -d "$APT_CONF_DIR" ]; then
        sudo mkdir -p "$APT_CONF_DIR"
    fi

    echo "Acquire::http::Proxy \"http://$WINDOWS_HOST_IP:$HTTP_PROXY_PORT\";" | sudo tee $APT_PROXY_CONF >/dev/null
    echo "Acquire::https::Proxy \"http://$WINDOWS_HOST_IP:$HTTPS_PROXY_PORT\";" | sudo tee -a $APT_PROXY_CONF >/dev/null
fi

# 配置 Docker 代理
if [ "$CONFIGURE_DOCKER" = true ]; then
    echo "Configuring Docker proxy..."
    DOCKER_SERVICE_DIR="/etc/systemd/system/docker.service.d"
    DOCKER_PROXY_CONF="$DOCKER_SERVICE_DIR/http-proxy.conf"

    if [ ! -d "$DOCKER_SERVICE_DIR" ]; then
        sudo mkdir -p "$DOCKER_SERVICE_DIR"
    fi

    echo "[Service]" | sudo tee $DOCKER_PROXY_CONF >/dev/null
    echo "Environment=\"HTTP_PROXY=http://$WINDOWS_HOST_IP:$HTTP_PROXY_PORT\"" | sudo tee -a $DOCKER_PROXY_CONF >/dev/null
    echo "Environment=\"HTTPS_PROXY=http://$WINDOWS_HOST_IP:$HTTPS_PROXY_PORT\"" | sudo tee -a $DOCKER_PROXY_CONF >/dev/null

    # 重新加载并重启 Docker 服务
    sudo systemctl daemon-reload
    sudo systemctl restart docker
fi

# 配置 Git 代理
if [ "$CONFIGURE_GIT" = true ]; then
    echo "Configuring Git proxy..."
    git config --global http.proxy "http://$WINDOWS_HOST_IP:$HTTP_PROXY_PORT"
    git config --global https.proxy "http://$WINDOWS_HOST_IP:$HTTPS_PROXY_PORT"
fi

# 配置 SSH 代理
if [ "$CONFIGURE_SSH" = true ]; then
    echo "Configuring SSH proxy..."
    mkdir -p ~/.ssh
    SSH_CONFIG_CONTENT=$(
        cat <<EOF
Host github.com
    Hostname ssh.github.com
    Port 443
    ProxyCommand nc -X 5 -x $WINDOWS_HOST_IP:$HTTP_PROXY_PORT %h %p
EOF
    )

    # 检查是否已存在相同的代理设置，避免重复添加
    if ! grep -q "$SSH_CONFIG_CONTENT" ~/.ssh/config; then
        echo "$SSH_CONFIG_CONTENT" >>~/.ssh/config
    fi
fi

echo "Proxy configuration completed. Please reopen the terminal to apply the changes."
