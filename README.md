# Claude Code Cowork VM Bug

Windows Store / MSIX 版 Claude Desktop 的 Cowork VM 启动失败修复记录。

## 内容

- `scripts/create-hardlinks.ps1` - 一键修复脚本
- `cases/claude-cowork-vm-bug.md` - 详细复盘与验证记录

## 用法

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\create-hardlinks.ps1
```

如需手动指定路径：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\create-hardlinks.ps1 `
  -SourcePath "C:\Users\<you>\AppData\Local\Claude-3p\vm_bundles\claudevm.bundle" `
  -DestPath "C:\Users\<package>\AppData\Local\Packages\<ClaudePackage>\LocalCache\Roaming\Claude-3p\vm_bundles\claudevm.bundle"
```

