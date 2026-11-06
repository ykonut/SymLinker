# SymLinker

轻量级 macOS 符号链接创建工具，支持拖拽操作。

[English](README.md)

## 功能

- 从访达 **拖拽文件** 到源文件列表
- 通过文件选择器 **浏览文件**（支持多选）
- 支持 **删除** 误加入的文件条目
- **设置目标目录**：拖拽文件夹、选择文件夹或直接输入路径
- 目标位置已有 **同名软链接** 时自动覆盖（含已失效的软链接）；真实的文件或文件夹不会被覆盖
- **一键创建** 符号链接（`⌘+Return`）
- 创建后可 **撤回（Undo）**：删除刚创建的链接，并恢复被覆盖的原链接
- 源文件右键菜单：在访达中显示、复制路径
- **原生 macOS 应用** — SwiftUI 构建，轻量简洁

## 使用方法

1. 添加源文件（拖拽到列表，或点击 Browse Files）
2. 设置目标目录（把文件夹拖到目标行即可，会直接覆盖原有路径；也可点击 Browse…，或点击路径文字手动输入）
3. 点击 **Create Symbolic Links**（或按 `⌘+Return`）

## 系统要求

- macOS 13 (Ventura) 或更高版本
- Apple Silicon 或 Intel

## 安装

从 [Releases](https://github.com/ykonut/SymLinker/releases) 下载最新版本，解压后将 `SymLinker.app` 拖入应用程序文件夹即可。

或从源码构建：

```bash
git clone https://github.com/ykonut/SymLinker.git
cd SymLinker
make app        # 构建 SymLinker.app
make install    # 构建并复制到 /Applications
```

## 构建

```bash
make run        # 通过 SwiftPM 直接运行
make app        # 构建独立 .app 包
make install    # 构建并安装到 /Applications
```

## 许可证

MIT