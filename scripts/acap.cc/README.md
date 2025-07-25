# acap.cc
加速服务器快速配置脚本

## https://github.com/dqzboy/Docker-Proxy

1. 通过 docker-compose 方式启动了 UI 和 HUB （对应 hub.docker.com）
2. 开启了认证，用户名密码存在 vault 中
3. 认证文件，修改或设置方式参照 `htpasswd -Bbn username password >  ./htpasswd`
4. UI 使用的用户密码和上面是一样的


## https://github.com/MoRan23/Github-Proxy-GO

1. 由于作者生成的docker不支持`arm64`所以重新编译版本放置在DOCKER公开仓库 `hanzhichen/github-proxy-go:latest`
2. 这个账号密码和上面一样，但实际使用时，不适用账号密码而使用加密后的`X-My-Auth`，加密方式`md5(USER:PASSWORD)`
    ```bash
    git config --global url."https://git.acap.cc/https://github.com/".insteadOf "https://github.com/"
    git config --global http."https://git.acap.cc/".extraHeader "X-My-Auth: xxxxxxx"
    ```
3. 当前测试时，私有仓库push会有问题，所以只适用于共有仓库加速获取，私有仓库使用ssh方式，保证互不影响。


## https://github.com/louislam/uptime-kuma

1. 服务存活检测，账号密码，第一次启动服务时自己设置
2. 挂载持久化存储在 /root/acap.cc/uptime 目录


## https://github.com/SagerNet/sing-box

1. 备用代理，配置存放在 vault 中，如果之前已经配置过直连