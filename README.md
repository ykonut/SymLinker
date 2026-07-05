# SymLinker

A lightweight macOS GUI tool for creating symbolic links via drag & drop.

[中文](README.zh.md)

## Features

- **Drag & drop** files from Finder into the source list
- **Browse** files via standard file picker (supports multiple selection)
- **Remove** individual files from the list with one click
- **Set target directory** via drag & drop, folder picker, or typing the path
- **One-click** symbolic link creation (`⌘+Return`)
- **Context menu** on source files: Reveal in Finder, Copy Path
- **Native macOS** app — SwiftUI, lightweight, clean design

## Usage

1. Add source files (drag onto the list or click Browse Files)
2. Set a target directory (drag a folder, click Choose Folder, or type a path)
3. Click **Create Symbolic Links** (or press `⌘+Return`)

## Requirements

- macOS 13 (Ventura) or later
- Apple Silicon or Intel

## Installation

Download the latest release from [Releases](https://github.com/ykonut/SymLinker/releases), extract the `.zip`, and drag `SymLinker.app` to your Applications folder.

Or build from source:

```bash
git clone https://github.com/ykonut/SymLinker.git
cd SymLinker
make app        # builds SymLinker.app
make install    # builds and copies to /Applications
```

## Build

```bash
make run        # run via SwiftPM
make app        # build standalone .app bundle
make install    # install to /Applications
```

## License

MIT