# TimeSync PWA Icon Generation

This directory contains tools to generate all required PWA icons from a single high-resolution source image.

## Prerequisites

### macOS
```bash
brew install imagemagick
```

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install imagemagick
```

## Usage

1. **Prepare your source image:**
   - Create a high-resolution square image (recommended: 1024x1024 or larger)
   - Name it something like `icon-source.png`, `timesync-logo.png`, etc.
   - Place it in the project root directory

2. **Make the scripts executable:**
   ```bash
   chmod +x bin/generate-icons.sh bin/svg2png.sh
   # Or run: npm run setup
   ```

3. **Generate all icons:**
   ```bash
   ./bin/generate-icons.sh your-source-image.png
   
   # Example:
   ./bin/generate-icons.sh timesync-logo-1024.png
   ```

4. **Or use npm scripts:**
   ```bash
   # If your source image is named 'icon-source.png'
   npm run build
   
   # Or generate manually
   npm run generate-icons -- your-image.png
   ```

## Generated Files

The script will create:

```
./
├── img/
│   ├── icon-16x16.png
│   ├── icon-32x32.png
│   ├── icon-72x72.png
│   ├── icon-96x96.png
│   ├── icon-128x128.png
│   ├── icon-144x144.png
│   ├── icon-152x152.png
│   ├── icon-192x192.png
│   ├── icon-384x384.png
│   └── icon-512x512.png
├── apple-touch-icon.png (180x180)
└── favicon.ico (multi-size: 16, 32, 48)
```

## SVG to PNG Conversion

For SVG sources, use the `svg2png.sh` script first:

```bash
# Convert SVG to high-res PNG
./bin/svg2png.sh timesync-icon.svg timesync-source-1024.png --size 1024x1024

# Then generate all PWA icons
./bin/generate-icons.sh timesync-source-1024.png
```

## Source Image Recommendations

- **Minimum size:** 512x512 pixels
- **Recommended size:** 1024x1024 pixels or larger
- **Format:** PNG, JPEG, or any format ImageMagick supports
- **Shape:** Square (non-square images will be cropped)
- **Design:** Simple, high contrast, recognizable at small sizes
- **Padding:** Include some padding around the main icon elements

## Troubleshooting

### "convert: command not found"
- Install ImageMagick using the commands above
- Verify installation: `convert -version`

### "Permission denied"
- Make the scripts executable: `chmod +x bin/generate-icons.sh bin/svg2png.sh`

### Low quality results
- Use a higher resolution source image (1024x1024 or larger)
- Ensure your source image has good contrast and clear details

### Non-square source image
- The script will automatically crop to square from the center
- For best results, prepare a square source image

## Integration with Deployment

After generating icons, your PWA will have all required files for:
- ✅ iOS home screen icons
- ✅ Android adaptive icons  
- ✅ Desktop PWA icons
- ✅ Browser favicons
- ✅ Microsoft/Windows tiles

The generated files work with the PWA manifest and HTML meta tags already configured in `index.html`.

## Version Management

Update versions across all files (package.json, manifest.json, sw.js):

```bash
# Patch version (0.5.7 → 0.5.8)
npm run release:patch

# Minor version (0.5.7 → 0.6.0)  
npm run release:minor

# Major version (0.5.7 → 1.0.0)
npm run release:major
```

The script will:
- Update package.json version
- Update manifest.json version  
- Update service worker cache name
- Create git commit and tag
- Optionally deploy to production

## Deployment Workflow

TimeSync uses a `deploy` branch for GitHub Pages to separate development from production:

### Development (on `main` branch):
```bash
# Normal development - commits don't go live
git add .
git commit -m "Work in progress"
git push origin main  # Safe - not deployed
```

### Release to Production:
```bash
# Option 1: Release with version bump
npm run release:patch  # Updates version AND deploys

# Option 2: Deploy current state without version bump  
npm run deploy
```

### GitHub Pages Setup:
1. Go to repo Settings → Pages
2. Set source to `deploy` branch (not `main`)
3. Now only intentional releases go live at https://timesync.app

This workflow allows continuous development without every commit going to production!