# TimeSync - A Clapper for the Web

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![PWA](https://img.shields.io/badge/PWA-Ready-brightgreen.svg)](https://timesync.app)

TimeSync is an audio visual synchronization tool for recordings and conferences. It provides precise time synchronization by generating sharp audio "tick" sounds paired with spoken UTC timestamps, enabling post-production synchronization of multiple audio/video sources.

🌐 **Live App**: [timesync.app](https://timesync.app)

## Features

- **⏱️ Precise Timing**: Synchronizes to exact second boundaries with millisecond precision
- **🔊 Sharp Audio Tick**: Loud, distinctive tick sound for audio synchronization
- **🗣️ Spoken Timestamps**: Voice announcement of exact UTC time
- **📱 PWA Ready**: Installable on desktop and mobile devices
- **⚡ Instant Logging**: Add immediate time markers without waiting
- **📋 Time URIs**: Copy-friendly time:// URIs for referencing moments
- **🎯 Offline Support**: Works without internet connection

## Quick Start

### For Users
1. Visit [timesync.app](https://timesync.app)
2. Click **"say TIME SYNC"** for precise synchronization with audio tick + spoken time
3. Click **"add TIME SYNC"** for instant silent time logging
4. Install as PWA for offline use

### For Developers

```bash
# Clone the repository
git clone https://github.com/smurp/timesync.app.git
cd timesync.app

# Setup development environment
npm run setup

# Build icons from SVG source
npm run build

# Start development (commits to main don't deploy)
git add .
git commit -m "Development changes"
git push origin main
```

## Development Workflow

TimeSync uses a **dual-branch workflow** to separate development from production:

### 🔧 **Development Branch** (`main`)
- All development happens here
- Commits **do not** go live automatically
- Built assets are `.gitignore`d to keep repo clean
- Safe for work-in-progress commits

### 🚀 **Production Branch** (`deploy`)
- Served by GitHub Pages at [timesync.app](https://timesync.app)
- Contains built assets required for PWA
- Only updated during intentional releases

### **Daily Development**
```bash
# Normal development - safe, won't deploy
vim src/index.html
git add .
git commit -m "Improve user interface"
git push origin main  # ✅ Not deployed
```

### **Release to Production**
```bash
# Option 1: Version bump + deploy
npm run release:patch  # 0.5.8 → 0.5.9, builds & deploys

# Option 2: Deploy current state without version change
npm run deploy

# Option 3: Individual release types
npm run release:minor  # 0.5.9 → 0.6.0
npm run release:major  # 0.6.0 → 1.0.0
```

## Repository Structure

```
timesync.app/
├── bin/                    # Build and deployment scripts
│   ├── generate-icons.sh   # Generate PWA icons from source
│   ├── svg2png.sh         # Convert SVG to PNG
│   ├── update-version.sh   # Version management
│   └── deploy.sh          # Deploy to production branch
├── img/                   # Generated PWA icons (deploy branch only)
├── timesync-icon.svg      # Source icon (version controlled)
├── index.html            # Main application
├── manifest.json         # PWA manifest
├── sw.js                # Service worker
└── package.json         # Scripts and metadata
```

## Available Scripts

### **Build Pipeline**
```bash
npm run render-png     # Convert SVG icon to high-res PNG
npm run generate-icons # Generate all PWA icon sizes
npm run build         # Full build: SVG → PNG → all PWA icons
```

### **Development**
```bash
npm run setup         # Make scripts executable
```

### **Deployment & Versioning**
```bash
npm run release:patch # Patch version (0.5.7 → 0.5.8) + deploy
npm run release:minor # Minor version (0.5.7 → 0.6.0) + deploy  
npm run release:major # Major version (0.5.7 → 1.0.0) + deploy
npm run deploy        # Deploy current main to production
```

## Setup for New Contributors

### 1. **Initial Setup**
```bash
git clone https://github.com/smurp/timesync.app.git
cd timesync.app
npm run setup  # Make scripts executable
```

### 2. **Install Dependencies**
```bash
# macOS
brew install imagemagick

# Ubuntu/Debian  
sudo apt install imagemagick
```

### 3. **Configure GitHub Pages** (maintainers only)
1. Go to repo Settings → Pages
2. Set source to **`deploy` branch** (not `main`)
3. Save - now only releases go live

### 4. **Create Initial Deploy Branch** (one-time setup)
```bash
# Create deploy branch with built assets
git checkout -b deploy
npm run build
git add img/ apple-touch-icon.png favicon.ico -f
git commit -m "Initial deployment assets"
git push origin deploy
git checkout main
```

## Icon Development

TimeSync icons are generated from `timesync-icon.svg`:

```bash
# Edit the source SVG
vim timesync-icon.svg

# Generate all PWA icons (16x16 to 512x512)
npm run build

# Icons are created in img/ directory
# Also generates favicon.ico and apple-touch-icon.png
```

### Icon Design Guidelines
- Source should be square and high contrast
- Simple design that scales well to 16x16
- Uses alternating color pattern: black/white, red/black, white/red

## Contributing

1. **Fork** the repository
2. **Create** a feature branch from `main`
3. **Make** your changes
4. **Test** locally 
5. **Commit** to your feature branch
6. **Push** to your fork
7. **Submit** a pull request to `main`

### Development Notes
- Work on `main` branch - commits don't go live
- Run `npm run build` during development when icons change
- Built assets (img/, favicon.ico) are gitignored on `main`
- Deployment scripts expect assets to already exist
- Use `npm run deploy` to publish built assets to production
- Follow semantic versioning for releases

## License

This project is licensed under the **GNU Affero General Public License v3.0 or later** (AGPL-3.0-or-later).

This ensures that if you use TimeSync code for a network service, you must make your source code available under the same license. See [LICENSE](LICENSE) for full details.

## Links

- **🌐 Live App**: [timesync.app](https://timesync.app)
- **📖 Documentation**: [noosphere.org/blog/timesync/](https://noosphere.org/blog/timesync/)
- **🐛 Issues**: [GitHub Issues](https://github.com/smurp/timesync.app/issues)
- **🏠 More Projects**: [noosphere.org](https://noosphere.org/)

---

<p align="center">
  <strong>TimeSync</strong> - Precise timing for the modern web
</p>