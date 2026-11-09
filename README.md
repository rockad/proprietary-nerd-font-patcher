# Proprietary Nerd Font Patcher

A robust, containerized Nerd Fonts patching pipeline and zero-patch fallback guide for proprietary, commercial, and unredistributable programming fonts.

Built for typefaces that cannot be redistributed in pre-patched form due to licensing—including **Microsoft Consolas**, **Apple SF Mono**, **Berkeley Mono**, **PragmataPro**, **Dank Mono**, **Menlo**, and **Aptos Mono**.

> [!IMPORTANT]
> **Prerequisite — User-Supplied Font Required**: This repository does **NOT** bundle, host, or distribute proprietary font binaries due to commercial licensing restrictions. You must provide your own legally acquired font files (`.ttf` or `.otf`) by placing them into the `in/` directory before running the patcher.

---

## Featured Showcase: Consolas Nerd Font

While this tool supports any proprietary monospace font, **Microsoft Consolas** serves as the primary showcase and reference implementation. 

Consolas is one of the most widely deployed developer fonts in the world, yet community attempts to patch it frequently fail due to:
- **Descender clipping**: Cutting off the bottoms of `g`, `j`, `p`, `q`, `y`, and underscores `_`.
- **Line height distortion**: Unnatural vertical spacing or squashed row padding.
- **Icon squishing**: Shrunken, illegible glyphs under naive `--mono` settings.
- **ClearType blurriness**: Degradation of native Microsoft TrueType bytecode hinting (`fpgm`, `prep`, `cvt ` tables).

This repository provides the definitive fix for **Consolas Nerd Font**, preserving native ClearType rasterization metrics, offering both **Standard** (2-cell proportional icons) and **Mono** (1-cell icons) variants, and detailing zero-patch terminal fallback chains.

---

## Table of Contents

- [Supported Fonts & Universal Input](#supported-fonts--universal-input)
- [Overview & Variants](#overview--variants)
  - [Standard vs Mono Comparison](#standard-vs-mono-comparison)
- [Consolas Showcase: Why Previous Patches Failed](#consolas-showcase-why-previous-patches-failed)
  - [1. `--adjust-line-height` Table Mutation & Descender Clipping](#1---adjust-line-height-table-mutation--descender-clipping)
  - [2. Cell Aspect Ratio & Wide Glyph Squishing under `--mono`](#2-cell-aspect-ratio--wide-glyph-squishing-under---mono)
  - [3. FontForge ClearType Bytecode Hinting Invalidation](#3-fontforge-cleartype-bytecode-hinting-invalidation)
- [Quick Start: Patching Consolas Step-by-Step](#quick-start-patching-consolas-step-by-step)
- [Using with Other Proprietary Fonts (SF Mono, Berkeley Mono, Menlo, etc.)](#using-with-other-proprietary-fonts-sf-mono-berkeley-mono-menlo-etc)
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
- [Credits & Acknowledgments](#credits--acknowledgments)

---

## Supported Fonts & Universal Input

The patching pipeline automatically processes any TrueType (`.ttf`) or OpenType (`.otf`) fonts placed in the `in/` directory:

| Font Family | Typical Source | Format |
| :--- | :--- | :--- |
| **Microsoft Consolas** | Windows (`C:\Windows\Fonts\consola*.ttf`), Office, or MyFonts | `.ttf` |
| **Apple SF Mono** | macOS (`/System/Applications/Utilities/Terminal.app/...`) or Xcode | `.otf` |
| **Berkeley Mono** | US Graphics commercial license | `.ttf` / `.otf` |
| **PragmataPro** | Fabrizio Schiavi commercial license | `.ttf` |
| **Dank Mono** | Phil Plückthun commercial license | `.otf` |
| **Menlo** | macOS system font (`/System/Library/Fonts/`) | `.ttf` |
| **Microsoft Aptos Mono** | Microsoft 365 / Windows 11 font update | `.ttf` |

---

## Overview & Variants

When patching programming fonts, icon width is a critical architectural choice:

### Standard vs Mono Comparison

| Feature | Standard Variant (`out/standard/`) | Mono Variant (`out/mono/`) |
| :--- | :--- | :--- |
| **Naming Convention** | `<FontName> Nerd Font` (e.g. `Consolas Nerd Font`) | `<FontName> Nerd Font Mono` (e.g. `Consolas Nerd Font Mono`) |
| **Symbol Cell Width** | **2-cell (proportional / double-width)** | **1-cell (strict monospaced / single-width)** |
| **Icon Clarity** | Crisp, uncompressed, proportional glyphs | Compressed/narrowed to fit strict 1-column em |
| **Recommended For** | Modern terminals, IDEs, code editors | Legacy CLI environments, strict 1-cell grids |
| **Target Terminals** | Windows Terminal, VS Code, Ghostty, WezTerm, Kitty | Windows Console (`conhost`), tmux without wide-char support |

> [!TIP]
> **Recommendation**: Always prefer the **Standard** variant for modern workflows. Modern terminals natively support 2-cell wide Unicode glyphs, rendering file icons, git branches, and devicon logos with proper proportions.

---

## Consolas Showcase: Why Previous Patches Failed

Consolas has a character advance width of approximately **55% em** (550 units per 1000-unit em) and finely balanced vertical metrics. When patched with default Nerd Fonts scripts, several severe issues arise:

### 1. `--adjust-line-height` Table Mutation & Descender Clipping

When `font-patcher` is invoked with `--adjust-line-height` (`-l`), it recalculates vertical metrics across three distinct tables:
- `OS/2`: `sTypoAscender`, `sTypoDescender`, `sTypoLineGap`, `usWinAscent`, `usWinDescent`
- `hhea`: `ascender`, `descender`, `lineGap`
- `VDMX`: Pre-computed vertical device metrics

In Consolas:
- Consolas uses a custom `usWinDescent` and `sTypoDescender` ratio tuned specifically for ClearType subpixel rendering.
- `--adjust-line-height` attempts to center Powerline chevron arrows by shifting baseline and shrinking vertical descent metrics.
- As a consequence, character descenders (`g`, `j`, `p`, `y`, and underscores `_`) exceed the bounding box reported in `usWinDescent` and get ruthlessly clipped by terminal renderers (especially Windows Terminal and DirectWrite).
- **The Fix**: Omitting `--adjust-line-height` leaves Consolas' native metrics untouched, preserving perfect descenders and exact line-height spacing.

### 2. Cell Aspect Ratio & Wide Glyph Squishing under `--mono`

- Consolas is an unusually narrow monospace font (advance width ~550 units).
- Nerd Fonts symbol sets (Font Awesome, Material Design Icons, Octicons) are natively authored on a 1000x1000 square grid.
- When `--mono` is passed, the patcher scales all icons down to fit a single 550-unit cell. This causes horizontal compression of ~45%, rendering intricate icons (Docker whale, Rust crab, Angular shield) unreadable.
- **The Fix**: The Standard variant allows icons to occupy 2 monospace cells (1100 units), preserving their natural aspect ratio while aligning precisely on terminal character grids.

### 3. FontForge ClearType Bytecode Hinting Invalidation

- Original Microsoft Consolas features complex TrueType bytecode hinting (`fpgm`, `prep`, `cvt ` tables) designed specifically for Microsoft's ClearType rasterizer.
- When FontForge regenerates TrueType tables during patching, re-hinting or modifying existing glyph tables can corrupt bytecode streams, leading to blurred stems at standard DPI.
- **The Fix**: By passing `--careful`, existing native glyphs and their TrueType instructions are preserved without re-encoding, ensuring that ASCII text rendering remains 100% identical to the stock font.

---

## Quick Start: Patching Consolas Step-by-Step

### 1. Obtain Your Consolas Files
Copy your licensed Consolas `.ttf` files into the `in/` directory:
- **From Windows:** Copy `C:\Windows\Fonts\consola*.ttf` into `in/`
- **From WSL:**
  ```bash
  cp /mnt/c/Windows/Fonts/consola*.ttf in/
  ```
- **From MyFonts / Monotype Purchase:** Unpack your order and copy `Consolas*.ttf` into `in/`

### 2. Run the Patcher
```bash
# Build both Standard (2-cell) and Mono (1-cell) variants
./patcher.sh all

# Or build only the recommended Standard variant
./patcher.sh standard
```

### 3. Install the Fonts
- Windows: Select all `.ttf` files in `out/standard/`, right-click, and select **Install**.
- Linux / WSL: Copy to `~/.local/share/fonts/` and run `fc-cache -fv`.

---

## Using with Other Proprietary Fonts (SF Mono, Berkeley Mono, Menlo, etc.)

The patcher pipeline works identically for any proprietary monospace font:

1. **Clear `in/` and add your target fonts**: Drop your `.ttf` or `.otf` files into `in/` (e.g. `SF-Mono-Regular.otf`, `BerkeleyMono-Regular.ttf`).
2. **Run `./patcher.sh all`**: The script automatically detects the font format, applies multi-threaded containerized patching with metric preservation, and outputs into `out/standard/` and `out/mono/`.
3. **Enjoy intact metrics**: The omission of `--adjust-line-height` guarantees that your font's custom vertical metrics, descenders, and typography are preserved.

---

## Manual Font Installation

After running `./patcher.sh`, install the generated `.ttf` files manually.

### Windows 10 / 11

1. Open File Explorer and navigate to:
   - For Standard: `out\standard\`
   - For Mono: `out\mono\`
2. Select all generated `.ttf` files.
3. Right-click and select **Install** (or **Install for all users**).
4. Restart your terminal emulator or code editor.

### Linux & WSL

1. Copy the desired font files to your user fonts directory:
   ```bash
   mkdir -p ~/.local/share/fonts/nerd-fonts
   cp out/standard/*.ttf ~/.local/share/fonts/nerd-fonts/
   ```
2. Rebuild the font cache:
   ```bash
   fc-cache -fv ~/.local/share/fonts/nerd-fonts/
   ```
3. Verify font registration:
   ```bash
   fc-list : family | grep -i "Nerd Font"
   ```

### macOS

1. Double-click each `.ttf` file in `out/standard/` and click **Install Font** in Font Book.
2. Or copy the files directly to your user font library:
   ```bash
   cp out/standard/*.ttf ~/Library/Fonts/
   ```

---

## Zero-Patch Fallback Guide (Fallback to Symbols Nerd Font)

If you prefer to keep your original, unpatched font files 100% untouched and avoid font patching altogether, use **font fallback chaining**. Modern terminal emulators and editors seamlessly render ASCII characters using standard Consolas, while delegating missing Unicode icon codepoints to **Symbols Nerd Font**.

### 1. Download Symbols Nerd Font
Download `SymbolsNerdFont-Regular.ttf` and `SymbolsNerdFontMono-Regular.ttf` from [Nerd Fonts Releases](https://github.com/ryanoasis/nerd-fonts/releases/latest) and install it on your OS.

### 2. Ready-to-Copy Application Configurations

#### Windows Terminal (`settings.json`)
```json
{
  "profiles": {
    "defaults": {
      "font": {
        "face": "Consolas"
      }
    }
  }
}
```
*(Windows Terminal automatically resolves missing symbol glyphs from installed system fonts, including Symbols Nerd Font).*

#### Visual Studio Code (`settings.json`)
```json
{
  "editor.fontFamily": "Consolas, 'Symbols Nerd Font', monospace",
  "terminal.integrated.fontFamily": "Consolas, 'Symbols Nerd Font Mono'"
}
```

#### Ghostty (`config`)
```ini
font-family = Consolas
font-family = Symbols Nerd Font
```

#### WezTerm (`wezterm.lua`)
```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({
  'Consolas',
  'Symbols Nerd Font',
})

return config
```

#### Kitty (`kitty.conf`)
```conf
font_family Consolas

# Map Nerd Font Unicode ranges to Symbols Nerd Font
symbol_map U+e000-U+e00a,U+ea60-U+ebeb,U+e0a0-U+e0c8,U+e0ca,U+e0cc-U+e0d4,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b1,U+e700-U+e7c5,U+f000-U+f2e9,U+f300-U+f372,U+f400-U+f532,U+f0001-U+f1af0 Symbols Nerd Font
```

---

## Building & Patching Instructions

### Prerequisites

- **Docker**: Docker Engine or Docker Desktop installed and running.
- **Source Fonts**: Your licensed `.ttf` or `.otf` font files placed in `in/`.

### Running the Patcher

```bash
# Make patcher executable
chmod +x patcher.sh

# Build all variants (Standard 2-cell and Mono 1-cell)
./patcher.sh all

# Build only Standard variant (recommended)
./patcher.sh standard

# Build only Mono variant
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
proprietary-nerd-font-patcher/
├── .gitignore          # Git ignores font binaries (*.ttf, *.otf, *.zip)
├── in/                 # Source proprietary font files (user-supplied)
│   ├── .gitkeep
│   └── (Consolas.ttf, SF-Mono.otf, etc. - gitignored)
├── out/
│   ├── .gitkeep
│   ├── standard/       # Standard variant (2-cell icons, recommended)
│   └── mono/           # Mono variant (1-cell icons)
├── patcher.sh          # Multi-variant Docker patcher build script
└── README.md           # Comprehensive technical documentation
```

---

## Licensing

- **Proprietary Fonts**: All rights belong to their respective copyright holders (Microsoft Corporation, Apple Inc., US Graphics, etc.). Source font binaries and generated derivatives are excluded from version control via `.gitignore`.
- **Nerd Fonts**: Licensed under MIT (scripts & glyphs). Individual upstream glyph sets retain their respective licenses (Font Awesome, Material Design, Octicons, etc.).
- **Build Scripts & Configuration**: MIT License.

---

## Credits & Acknowledgments

This project is built upon the foundational work of the following typographers, engineers, and open-source projects:

- **[Ryan L McIntyre](https://github.com/ryanoasis) & [Nerd Fonts](https://www.nerdfonts.com/)** — For creating the iconic [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) ecosystem, curated glyph aggregates, and the automated `font-patcher` toolchain.
- **[Luc(as) de Groot](https://fontfabrik.com/) & [Microsoft Corporation](https://www.microsoft.com/)** — For designing the legendary Consolas typeface, finely tuned ClearType rasterization parameters, and enduring programming ergonomics.
- **[George Williams](https://fontforge.org/) & the [FontForge](https://github.com/fontforge/fontforge) Team** — For the open-source font editor and outline transformation engine that powers automated glyph injection.
- **[Docker](https://www.docker.com/)** — For enabling completely reproducible, isolated containerized font compilation environments across any operating system.
