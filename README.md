# Consolas Nerd Font

A robust, reproducible Nerd Fonts generator for Microsoft Consolas, providing both **Standard** (proportional 2-cell icons) and **Mono** (strict 1-cell icons) variants without descender clipping, line height distortion, or cell aspect crushing.

---

## Table of Contents

- [Overview & Variants](#overview--variants)
  - [Standard vs Mono Comparison](#standard-vs-mono-comparison)
- [Why Previous Consolas Patches Failed: Technical Root Causes](#why-previous-consolas-patches-failed-technical-root-causes)
  - [1. `--adjust-line-height` Table Mutation & Descender Clipping](#1---adjust-line-height-table-mutation--descender-clipping)
  - [2. Cell Aspect Ratio & Wide Glyph Squishing under `--mono`](#2-cell-aspect-ratio--wide-glyph-squishing-under---mono)
  - [3. FontForge ClearType Bytecode Hinting Invalidation](#3-fontforge-cleartype-bytecode-hinting-invalidation)
- [Manual Font Installation](#manual-font-installation)
  - [Windows 10 / 11](#windows-10--11)
  - [Linux & WSL](#linux--wsl)
  - [macOS](#macos)
- [Zero-Patch Fallback Guide (Fallback to Symbols Nerd Font)](#zero-patch-fallback-guide-fallback-to-symbols-nerd-font)
  - [Windows Terminal (`settings.json`)](#windows-terminal-settingsjson)
  - [Visual Studio Code (`settings.json`)](#visual-studio-code-settingsjson)
  - [Ghostty (`config`)](#ghostty-config)
  - [WezTerm (`wezterm.lua`)](#wezterm-weztermlua)
  - [Kitty (`kitty.conf`)](#kitty-kittyconf)
- [Building & Patching Instructions](#building--patching-instructions)
  - [Prerequisites](#prerequisites)
  - [Running the Patcher](#running-the-patcher)
- [Directory Layout](#directory-layout)
- [Licensing](#licensing)

---

## Overview & Variants

Microsoft Consolas is a monospace typeface designed by Luc(as) de Groot for Microsoft ClearType. Due to proprietary licensing, pre-patched binaries cannot be redistributed publicly. This repository provides a turnkey Docker-based pipeline to patch your licensed Consolas source files using official Nerd Fonts tooling.

Two distinct font variants are built into separate output directories:

### Standard vs Mono Comparison

| Feature | Consolas Nerd Font (`out/standard/`) | Consolas Nerd Font Mono (`out/mono/`) |
| :--- | :--- | :--- |
| **Family Name** | `Consolas Nerd Font` | `Consolas Nerd Font Mono` |
| **Symbol Cell Width** | **2-cell (proportional / double-width)** | **1-cell (strict monospaced / single-width)** |
| **Icon Clarity** | Crisp, uncompressed, proportional glyphs | Compressed/narrowed to fit strict 1-column em |
| **Recommended For** | Modern terminals, IDEs, code editors | Legacy CLI environments, strict 1-cell grids |
| **Target Terminals** | Windows Terminal, VS Code, Ghostty, WezTerm, Kitty | Windows Console (`conhost`), tmux without wide-char support |

> [!TIP]
> **Recommendation**: Always prefer **Consolas Nerd Font** (Standard variant) for modern workflows (Windows Terminal, VS Code, Ghostty, WezTerm). Modern terminals natively support 2-cell wide Unicode glyphs, rendering file icons, git branches, and devicon logos without distortion.

---

## Why Previous Consolas Patches Failed: Technical Root Causes

Many community-patched Consolas builds suffer from broken descenders (clipping `g`, `j`, `p`, `q`, `y`, `_`), squished glyphs, or fuzzy rendering. Here is the technical breakdown of why those failures occur:

### 1. `--adjust-line-height` Table Mutation & Descender Clipping

When `font-patcher` is invoked with the `--adjust-line-height` (`-l`) flag, it recalculates vertical metrics across three distinct font tables:
- `OS/2`: `sTypoAscender`, `sTypoDescender`, `sTypoLineGap`, `usWinAscent`, `usWinDescent`
- `hhea`: `ascender`, `descender`, `lineGap`
- `VDMX`: Pre-computed vertical device metrics

In Microsoft Consolas:
- Consolas uses a custom `usWinDescent` and `sTypoDescender` ratio tuned specifically for ClearType subpixel rendering.
- `--adjust-line-height` attempts to center Powerline chevron arrows by shifting baseline and shrinking vertical descent metrics.
- As a consequence, character descenders (`g`, `j`, `p`, `y`, and underscores `_`) exceed the bounding box reported in `usWinDescent` and get ruthlessly clipped by terminal renderers (especially Windows Terminal and DirectWrite).
- **The Solution**: Omitting `--adjust-line-height` leaves Consolas' native metrics untouched, preserving perfect descenders and exact line-height spacing.

### 2. Cell Aspect Ratio & Wide Glyph Squishing under `--mono`

- Consolas is an unusually narrow monospace font: its advance width is approximately **55% em** (550 units per 1000-unit em).
- Nerd Fonts symbol sets (Font Awesome, Material Design Icons, Octicons) are natively authored on a 1000x1000 square grid (100% em).
- When `--mono` is passed, the patcher scales all 2-cell and square icons down to 1-cell width (550 units). This causes horizontal compression of ~45%, rendering intricate icons (like Docker whale, Rust crab, Angular shield) unreadable.
- **The Solution**: The Standard variant allows icons to occupy 2 monospace cells (1100 units), preserving their natural aspect ratio while aligning precisely on terminal character grids.

### 3. FontForge ClearType Bytecode Hinting Invalidation

- Original Microsoft Consolas features complex TrueType bytecode hinting (`fpgm`, `prep`, `cvt ` tables) designed specifically for Microsoft's ClearType rasterizer.
- When FontForge regenerates TrueType tables during patching, re-hinting or modifying existing glyph tables can corrupt bytecode streams, leading to blurred stems at standard DPI.
- **The Solution**: By using `--careful`, existing native Consolas glyphs and their TrueType instructions are preserved without re-encoding, ensuring that ASCII rendering remains 100% identical to the stock font.

---

## Manual Font Installation

After running `./patcher.sh`, install the generated `.ttf` files manually.

### Windows 10 / 11

1. Open File Explorer and navigate to:
   - For Standard: `out\standard\`
   - For Mono: `out\mono\`
2. Select all four `.ttf` files (`Regular`, `Bold`, `Italic`, `BoldItalic`).
3. Right-click and select **Install** (or **Install for all users** if you have administrative privileges).
   - Alternatively, drag and drop the files into Windows Settings: `Settings > Personalization > Fonts`.
4. If your terminal or editor is open, restart it to load the newly registered font family.

### Linux & WSL

1. Copy the desired font files to your user fonts directory:
   ```bash
   mkdir -p ~/.local/share/fonts/consolas-nerd-font
   cp out/standard/*.ttf ~/.local/share/fonts/consolas-nerd-font/
   ```
2. Rebuild the font cache:
   ```bash
   fc-cache -fv ~/.local/share/fonts/consolas-nerd-font/
   ```
3. Verify font registration:
   ```bash
   fc-list : family | grep -i "Consolas Nerd Font"
   ```

### macOS

1. Double-click each `.ttf` file in `out/standard/` and click **Install Font** in Font Book.
2. Or copy the files directly to your user font library:
   ```bash
   cp out/standard/*.ttf ~/Library/Fonts/
   ```

---

## Zero-Patch Fallback Guide (Fallback to Symbols Nerd Font)

If you prefer to keep your original, unpatched Microsoft Consolas font intact and avoid font patching altogether, you can use **font fallback chaining**. Modern terminal emulators and editors seamlessly render ASCII characters using standard Consolas, while delegating missing Unicode icon codepoints to **Symbols Nerd Font**.

### 1. Download Symbols Nerd Font
Download `SymbolsNerdFont-Regular.ttf` and `SymbolsNerdFontMono-Regular.ttf` from [Nerd Fonts Releases](https://github.com/ryanoasis/nerd-fonts/releases/latest) and install it on your OS.

### 2. Ready-to-Copy Application Configurations

#### Windows Terminal (`settings.json`)
```json
{
  "profiles": {
    "defaults": {
      "font": {
        "face": "Consolas",
        "cellWidth": null,
        "cellHeight": null
      }
    }
  }
}
```
*(Windows Terminal automatically cascades missing glyphs to `Symbols Nerd Font` when installed).*

Or configure the patched font directly:
```json
{
  "profiles": {
    "defaults": {
      "font": {
        "face": "Consolas Nerd Font",
        "size": 11.0
      }
    }
  }
}
```

#### Visual Studio Code (`settings.json`)
```json
{
  "editor.fontFamily": "'Consolas', 'Symbols Nerd Font', monospace",
  "terminal.integrated.fontFamily": "'Consolas Nerd Font', 'Consolas', monospace"
}
```

#### Ghostty (`config`)
```ini
font-family = "Consolas"
font-family = "Symbols Nerd Font"
font-size = 12
adjust-cursor-height = 0
```
Or with patched font:
```ini
font-family = "Consolas Nerd Font"
font-size = 12
```

#### WezTerm (`wezterm.lua`)
```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({
  { family = 'Consolas', weight = 'Regular' },
  { family = 'Symbols Nerd Font', weight = 'Regular' },
})
config.font_size = 11.5

return config
```

#### Kitty (`kitty.conf`)
```ini
font_family      Consolas
bold_font        Consolas Bold
italic_font      Consolas Italic
bold_italic_font Consolas Bold Italic
font_size 11.5

# Nerd Fonts symbol fallback range
symbol_map U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6B1,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+F0001-U+F1AF0 Symbols Nerd Font
```

---

## Building & Patching Instructions

### Prerequisites
- Docker or Podman installed and running.
- Licensed Consolas TrueType font files placed in `in/`:
  - `Consolas.ttf` (Regular)
  - `Consolas-Bold.ttf` (Bold)
  - `Consolas-Italic.ttf` (Italic)
  - `Consolas-BoldItalic.ttf` (Bold Italic)

### Running the Patcher

Run `patcher.sh` with your desired target:

```bash
# Build both Standard and Mono variants (default)
./patcher.sh all

# Build only the Standard variant (2-cell proportional icons)
./patcher.sh standard

# Build only the Mono variant (1-cell strict monospaced icons)
./patcher.sh mono
```

The script will automatically:
- Mount `./in` and `./out/<variant>` into the official `nerdfonts/patcher:latest` container.
- Run multi-core parallel processing using `nproc` jobs.
- Apply `--careful --complete` (and `--mono` for mono).
- Write generated fonts to `out/standard/` and `out/mono/`.

---

## Directory Layout

```text
~/projects/consolas-nerd-font/
├── .gitignore          # Git ignores font binaries (*.ttf, *.otf)
├── in/                 # Source Consolas TrueType font files & licenses
│   ├── Consolas.ttf
│   ├── Consolas-Bold.ttf
│   ├── Consolas-Italic.ttf
│   ├── Consolas-BoldItalic.ttf
│   └── Licenses/
├── out/
│   ├── standard/       # Consolas Nerd Font (2-cell icons, recommended)
│   └── mono/           # Consolas Nerd Font Mono (1-cell icons)
├── patcher.sh          # Multi-variant Docker patcher build script
└── README.md           # Comprehensive technical documentation
```

---

## Licensing

- **Microsoft Consolas**: Proprietary font software owned by Microsoft Corporation. All rights reserved. Source font binaries and generated derivatives are excluded from version control via `.gitignore`.
- **Nerd Fonts**: Licensed under MIT (scripts & glyphs). Individual upstream glyphs retain their original licenses (Font Awesome, Material Design, Octicons, etc.).
- **Build Scripts & Configuration**: MIT License.
