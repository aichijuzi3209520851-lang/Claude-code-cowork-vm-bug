# Claude Code Cowork VM Bug Fix

Windows Store / MSIX 版 Claude Desktop 的 Cowork VM 启动失败修复仓库。

## 问题

如果你看到下面这种情况：

- Cowork 一直卡在 `Workspace still starting`
- 日志里出现 `failed to set VHDX path`
- 报错路径是 `C:\Users\<you>\AppData\Local\Packages\...\LocalCache\Roaming\Claude-3p\...`

通常就是 MSIX 容器路径和真实文件路径不一致。

## 原因

真实文件在：

```text
C:\Users\<you>\AppData\Local\Claude-3p\vm_bundles\claudevm.bundle
```

但 Cowork VM 实际读取的是：

```text
C:\Users\<you>\AppData\Local\Packages\<ClaudePackage>\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle
```

这里需要 NTFS 硬链接，不是目录联接。

## 一键修复

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\create-hardlinks.ps1
```

脚本会：

1. 自动找到真实 VM bundle 目录
2. 自动找到 Claude 的 MSIX 包目录
3. 为 7 个关键文件创建硬链接
4. 输出每个文件的修复结果

## 支持的文件

- `rootfs.vhdx`
- `vmlinuz`
- `initrd`
- `smol-bin.vhdx`
- `vmlinuz.zst`
- `initrd.zst`
- `rootfs.vhdx.zst`

## 手动指定路径

如果自动探测失败：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\create-hardlinks.ps1 `
  -SourcePath "C:\Users\<you>\AppData\Local\Claude-3p\vm_bundles\claudevm.bundle" `
  -PackageFolderName "Claude_pzs8sxrjxfjjc"
```

## 验证方法

修复后重新打开 Claude Desktop，再点 Cowork。

如果成功，你应该能在日志里看到：

- `Windows VM service configured`
- `create_network`
- `vm_boot`
- `add_plan9_shares`

## 复盘

详细排查过程见：

- [cases/claude-cowork-vm-bug.md](/C:/Users/Lenovo/Documents/New project 2/cases/claude-cowork-vm-bug.md)

## 参考

- [claude-cowork-fix-guide](https://github.com/kirin-ni/claude-cowork-fix-guide)

