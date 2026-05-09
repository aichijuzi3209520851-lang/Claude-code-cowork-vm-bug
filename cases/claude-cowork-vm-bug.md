# Claude Desktop Cowork VM 启动失败复盘

日期：2026-05-10

## 现象

Claude Desktop 的 Cowork 功能一直停在 “Workspace still starting”，最终报 VM 启动失败。

## 环境

- Windows 11 Pro / Windows 10 Pro
- Claude Desktop（Windows Store / MSIX 版）
- `CoworkVMService`

## 日志证据

关键报错是：

```text
failed to set VHDX path: VHDX file not found: C:\Users\Lenovo\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle\rootfs.vhdx
```

同时，真实文件实际存在于：

```text
C:\Users\Lenovo\AppData\Local\Claude-3p\vm_bundles\claudevm.bundle
```

## 根因

MSIX 容器看到的是 `Packages\...\LocalCache\Roaming\Claude-3p\...` 这条路径，但 VM bundle 文件实际落在 `AppData\Local\Claude-3p\...`。

这个场景里目录联接（junction）不可靠，NTFS 硬链接才有效。

## 修复步骤

1. 找到真实 bundle 目录。
2. 找到 Claude 的 MSIX 包目录。
3. 为以下 7 个文件创建 NTFS hardlink：
   - `rootfs.vhdx`
   - `vmlinuz`
   - `initrd`
   - `smol-bin.vhdx`
   - `vmlinuz.zst`
   - `initrd.zst`
   - `rootfs.vhdx.zst`
4. 重启 Claude Desktop，再次进入 Cowork。

## 验证结果

修复后，日志不再停在 `VHDX file not found`，而是继续进入：

- `Windows VM service configured`
- `create_network`
- `vm_boot`
- `add_plan9_shares`

这说明 VM 已经正常走到启动流程后段。

## 参考

- [claude-cowork-fix-guide](https://github.com/kirin-ni/claude-cowork-fix-guide)

