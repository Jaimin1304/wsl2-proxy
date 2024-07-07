# wsl2-proxy
wsl2-proxy is a simple tool to configure wsl2 to use the windows host's proxy. Effortless and simple, done with one click.

wsl2-proxy是一个配置wsl2使用windows宿主机代理的简单工具。轻松简单，一键搞定。

# How to use 如何使用
The tool assumes you have enabled a proxy on the Windows host, exposed a local proxy port, and allowed LAN connections to the proxy.

此工具默认你已经在windows宿主机上开启了代理，暴露了一个本地代理端口，并且该代理允许来自局域网的连接。

## Configure proxy settings 配置代理
```
./config_wsl2proxy.sh:
Usage: ./config_wsl2proxy.sh [-a] [-d] [-g] [-s] [-p PORT]
  -a    Configure apt proxy
  -d    Configure Docker proxy
  -g    Configure Git proxy
  -s    Configure SSH proxy
  -p    Set proxy port (default: 1080)
```

## Remove proxy settings 移除代理
```
./remove_wsl2proxy.sh:
Usage: ./remove_wsl2proxy.sh [-a] [-d] [-g] [-s]
  -a    Remove apt proxy
  -d    Remove Docker proxy
  -g    Remove Git proxy
  -s    Remove SSH proxy
```
