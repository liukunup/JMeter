# 镜像区别

```plaintext
├── Alpine                   # 以 Alpine 作为基础镜像（目的是尽可能压缩镜像体积）
│   └── Alpine with Plugins  # Alpine 基础镜像 + 常用插件
|       └── Business         # 业务镜像示例
└── Ubuntu                   # 以 Ubuntu 作为基础镜像（更加常规、主流）
    └── Ubuntu with Plugins  # Ubuntu 基础镜像 + 常用插件
        ├── Business         # 业务镜像示例
        ├── FullStack        # 同时支持 X11 + VNC + NoVNC + RDP
        ├── X11              # 仅支持 X11（适用于本地开发调试）
        ├── VNC and NoVNC    # 支持 VNC & NoVNC（使用到端口 5900 和 6080）
        └── RDP              # 仅支持 RDP（使用到端口3389）
```

```plaintext
Xvfb（提供图形输出）
  ├─ XFCE4（桌面环境，可选）
  ├─ x11vnc（暴露VNC服务）
  │   └─ websockify（转WebSocket）
  │       └─ noVNC（浏览器访问）
  └─ Xrdp（直接通过RDP协议访问）
Supervisor（监控所有后台服务）
```