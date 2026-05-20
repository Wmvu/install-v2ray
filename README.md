# install-v2ray

这是一个帮助你在Alpine系统上一键安装V2Ray服务端的脚本。

- 安装 `v2ray-core`
- 创建 `/etc/v2ray/config.json`
- 注册 OpenRC 服务
- 启动 `v2ray`
- 输出 `IP`、`Port`、`UUID` 等连接信息

### 你或许可以使用一键安装脚本
```sh
apk add --no-cache bash curl && sh <(wget -qO- https://raw.githubusercontent.com/Wmvu/install-v2ray/refs/heads/main/install-v2ray-server-alpine.sh)
```

---

运行方法：

```sh
chmod +x install-v2ray-server-alpine.sh
./install-v2ray-server-alpine.sh
```

指定端口或 UUID：

```sh
PORT=10000 UUID=your-uuid ./install-v2ray-server-alpine.sh
```

## 生成的服务端配置路径

```sh
/etc/v2ray/config.json
```

查看配置：

```sh
cat /etc/v2ray/config.json
```

## 常用服务命令

查看状态：

```sh
rc-service v2ray status
```

重启服务：

```sh
rc-service v2ray restart
```

停止服务：

```sh
rc-service v2ray stop
```

查看是否开机自启：

```sh
rc-update show | grep v2ray
```

## 常用排错命令

测试配置文件：

```sh
v2ray test -config /etc/v2ray/config.json
```

前台运行查看报错：

```sh
v2ray run -config /etc/v2ray/config.json
```

查看监听端口：

```sh
netstat -lntp | grep v2ray
```

## Windows 客户端说明

如果在 Windows 命令行运行客户端配置时提示端口占用，可以把本地入站改成：

```txt
HTTP: 127.0.0.1:7890
SOCKS5: 127.0.0.1:7891
```

## 说明

这套脚本生成的是 `VMess + TCP` 配置，适合 `v2ray-core` 使用。
windows的v2ray可以使用以下配置：
```txt
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "hosts": {
      "dns.google": [
        "8.8.8.8",
        "8.8.4.4",
        "2001:4860:4860::8888",
        "2001:4860:4860::8844"
      ],
      "dns.alidns.com": [
        "223.5.5.5",
        "223.6.6.6",
        "2400:3200::1",
        "2400:3200:baba::1"
      ],
      "one.one.one.one": [
        "1.1.1.1",
        "1.0.0.1",
        "2606:4700:4700::1111",
        "2606:4700:4700::1001"
      ],
      "1dot1dot1dot1.cloudflare-dns.com": [
        "1.1.1.1",
        "1.0.0.1",
        "2606:4700:4700::1111",
        "2606:4700:4700::1001"
      ],
      "cloudflare-dns.com": [
        "104.16.249.249",
        "104.16.248.249",
        "2606:4700::6810:f8f9",
        "2606:4700::6810:f9f9"
      ],
      "dns.cloudflare.com": [
        "104.16.132.229",
        "104.16.133.229",
        "2606:4700::6810:84e5",
        "2606:4700::6810:85e5"
      ],
      "dot.pub": [
        "1.12.12.12",
        "120.53.53.53"
      ],
      "doh.pub": [
        "1.12.12.12",
        "120.53.53.53"
      ],
      "dns.quad9.net": [
        "9.9.9.9",
        "149.112.112.112",
        "2620:fe::fe",
        "2620:fe::9"
      ],
      "dns.yandex.net": [
        "77.88.8.8",
        "77.88.8.1",
        "2a02:6b8::feed:0ff",
        "2a02:6b8:0:1::feed:0ff"
      ],
      "dns.sb": [
        "185.222.222.222",
        "2a09::"
      ],
      "dns.umbrella.com": [
        "208.67.220.220",
        "208.67.222.222",
        "2620:119:35::35",
        "2620:119:53::53"
      ],
      "dns.sse.cisco.com": [
        "208.67.220.220",
        "208.67.222.222",
        "2620:119:35::35",
        "2620:119:53::53"
      ],
      "engage.cloudflareclient.com": [
        "162.159.192.1"
      ]
    },
    "servers": [
      "119.29.29.29",
      "https://cloudflare-dns.com/dns-query"
    ]
  },
  "inbounds": [
  {
    "tag": "http",
    "port": 7890,
    "listen": "127.0.0.1",
    "protocol": "http",
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"],
      "routeOnly": false
    },
    "settings": {}
  },
  {
    "tag": "socks",
    "port": 7891,
    "listen": "127.0.0.1",
    "protocol": "socks",
    "sniffing": {
      "enabled": true,
      "destOverride": ["http", "tls"],
      "routeOnly": false
    },
    "settings": {
      "auth": "noauth",
      "udp": true,
      "allowTransparent": false
    }
  }
],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "154.12.189.154",
            "port": 49295,
            "users": [
              {
                "id": "b2887692-5168-4e29-84d2-2568990451d2",
                "alterId": 0,
                "email": "t@t.tt",
                "security": "auto"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp"
      },
      "mux": {
        "enabled": false,
        "concurrency": -1
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "port": "443",
        "network": "udp",
        "outboundTag": "block"
      },
      {
        "type": "field",
        "outboundTag": "proxy",
        "domain": [
          "geosite:google"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:private",
          "geoip:cn"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:private",
          "geosite:cn",
          "domain:alidns.com",
          "domain:doh.pub",
          "domain:dot.pub",
          "domain:360.cn",
          "domain:onedns.net"
        ]
      }
    ]
  }
}
```
最后启动系统代理监听7890端口就可以了。
