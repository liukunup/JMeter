# 镜像区别

```plaintext
├── Alpine                   # 以 Alpine 作为基础镜像（目的是尽可能压缩镜像体积）
│   └── Alpine with Plugins  # Alpine 基础镜像 + 常用插件
|       └── Business         # 业务镜像示例
└── Ubuntu                   # 以 Ubuntu 作为基础镜像（更加常规、主流）
    └── Ubuntu with Plugins  # Ubuntu 基础镜像 + 常用插件
        ├── FullStack        # 同时支持 X11 + VNC + NoVNC + RDP
        │   └── Business     # 业务镜像示例
        ├── X11              # 仅支持 X11（适用于本地开发调试）
        ├── VNC and NoVNC    # 支持 VNC & NoVNC（使用到端口 5900 和 6080）
        └── RDP              # 仅支持 RDP（使用到端口3389）
```
