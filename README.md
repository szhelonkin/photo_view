# Photo View

A cross-platform image gallery and file explorer built with Flutter. Browse, view, and manage your images with an intuitive interface designed for efficient navigation.

## Features

### 🗂️ **File Explorer**
- **Directory Navigation**: Browse through your file system with a clean sidebar interface
- **Breadcrumb Path**: Click any folder in the path to quickly jump to parent directories
- **Hidden Files Toggle**: Show/hide hidden files and folders (starting with `.`)
- **Home & Parent Navigation**: Quick access buttons in the app bar
- **Folder Creation**: Create new folders directly from the file explorer with validation

### 🖼️ **Image Gallery**
- **Recursive Image Discovery**: Automatically finds all images in subdirectories
- **Smart Sorting**: Sort by modification time (newest/oldest first) with improved accuracy
- **Grid Layout**: Adaptive grid that adjusts to screen size (180px square thumbnails)
- **Lazy Loading**: Efficient memory usage with batch processing (50 images at a time)
- **Scroll Position Memory**: Returns to exact position when closing image viewer
- **Multiple Selection**: Select multiple images with visual indicators (long-press to start)
- **Batch Operations**: Copy selected images to different folders
- **Quick Preview**: Right-click any image for instant full-size preview overlay
- **Folder Information**: Each thumbnail displays both filename and parent folder name with color-coded folder badges

### 🔍 **Image Viewer**
- **Full-Screen Viewing**: Clean, distraction-free image display
- **Pan & Zoom**: Interactive viewer with zoom (0.5x - 4x) and pan support
- **Navigation Controls**: Previous/next buttons with current position indicator
- **File Information**: Display filename and full clickable path
- **SVG Support**: Full support for SVG files alongside standard image formats
- **Image Copy**: Copy images to clipboard with Ctrl+C (Linux with xclip)
- **Country Flags**: 🌍 Automatic country detection from GPS EXIF data (217 countries, offline!)
- **Geo Visualization**: Display country flags on photos based on GPS coordinates

### 🎨 **User Interface**
- **Material Design**: Modern Flutter UI following Material Design principles
- **Responsive Layout**: Works seamlessly on desktop, mobile, and web
- **Performance Optimized**: 
  - ResizeImage for memory efficiency
  - GridView caching for smooth scrolling
  - Batch processing for large directories
- **Cross-Platform**: Supports Linux, Windows, macOS, iOS, Android, and web

## Supported Formats

- **Raster Images**: JPG, JPEG, PNG, GIF, BMP, WebP
- **Vector Images**: SVG (with flutter_svg)

## 🌍 Geolocation Features

### Country Detection from Photos
Photo View automatically extracts GPS coordinates from EXIF metadata and displays country flags on images:

- **🗺️ Offline Database**: Built-in database of 217 countries/territories (~16KB)
- **📍 GPS Extraction**: Reads coordinates from image EXIF data
- **🏳️ Country Flags**: Displays flag emoji for detected countries
- **⚡ Instant Detection**: No network required, works offline
- **🌐 Global Coverage**: Supports ~98% of world territories including:
  - Major countries worldwide
  - Caribbean islands (Jamaica, Barbados, Trinidad, etc.)
  - Pacific islands (Fiji, Samoa, Kiribati, etc.)
  - European microstates (Monaco, Vatican, San Marino, etc.)
  - Autonomous territories (Hong Kong, Macau, Greenland, etc.)

### Visual Indicators
- **Flag Badge**: Country flag shown on image thumbnail when GPS detected
- **Location Icon**: 📍 indicator for photos without GPS data
- **Toggle Button**: Show/hide country flags in gallery view

### How It Works
1. Photo View reads GPS coordinates from image EXIF metadata
2. Coordinates are matched against offline country bounding boxes
3. Country code is converted to flag emoji (🇷🇺, 🇺🇸, 🇫🇷, etc.)
4. Flag displayed on image thumbnail and in viewer

**Note**: Only works with photos that have GPS location data in EXIF. Photos without GPS show a location-off icon instead.

## 📋 Clipboard Features

### Copy Image to Clipboard
Quickly copy images to system clipboard for pasting into other applications:

- **🖱️ Copy Button**: Click the copy icon in image viewer header
- **⌨️ Keyboard Shortcut**: Press `Ctrl+C` (or `Cmd+C` on Mac) while viewing an image
- **📎 Smart Copy**: Automatically detects image format (PNG, JPEG, GIF, BMP, WebP)
- **✅ Visual Feedback**: Green notification when image copied successfully
- **⚠️ Requirements**: On Linux, requires `xclip` package:
  ```bash
  sudo apt install xclip
  ```

### Platform Support
- **Linux**: Full image copy support via xclip
- **Windows/macOS**: Copies file path (image copy support coming soon)

### Usage
1. Open any image in the viewer
2. Press `Ctrl+C` or click the copy button
3. Paste into any application with `Ctrl+V`
   - Image editors (GIMP, Krita, etc.)
   - Office applications (LibreOffice, etc.)
   - Web browsers and messaging apps

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- For desktop builds: platform-specific requirements
  - **Linux**: `clang cmake ninja-build pkg-config libgtk-3-dev`
  - **Windows**: Visual Studio with C++ components
- **Optional for Linux clipboard support**: `xclip` (for copying images)
  ```bash
  sudo apt install xclip
  ```

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd photo_view

# Install dependencies
flutter pub get

# Run on your preferred platform
flutter run                    # Default device
flutter run -d linux          # Linux desktop
flutter run -d windows        # Windows desktop
flutter run -d chrome         # Web browser
```

### Building for Distribution
```bash
# Linux
flutter build linux

# Windows  
flutter build windows

# Web
flutter build web
```

### Installing on Linux
After building, you can install the application system-wide:
```bash
# Copy the executable
sudo cp build/linux/x64/release/bundle/photo_view /usr/local/bin/

# Copy the desktop file
sudo cp linux/photo_view.desktop /usr/share/applications/

# Copy the icon
sudo cp linux/photo_view.png /usr/share/pixmaps/

# Update desktop database
sudo update-desktop-database
```

## Usage

### Basic Navigation
1. **Start Browsing**: Launch the app to begin in your home directory
2. **Navigate Folders**: Use the file explorer sidebar or click path segments
3. **View Gallery**: Switch to gallery view to see all images in current directory tree
4. **Open Images**: Click any thumbnail to open full-screen viewer
5. **Navigate Images**: Use arrow buttons or keyboard to move between images
6. **Quick Navigation**: Click any folder name in the path to jump there instantly

### Advanced Features
7. **Create Folders**: Click the folder icon in File Explorer to create new directories
8. **Multiple Selection**: Long-press any image in gallery to start selection mode
9. **Batch Copy**: Select multiple images and use the copy button to move them to another folder
10. **Quick Preview**: Right-click any gallery thumbnail for instant full-size preview
11. **Sort Images**: Toggle between newest-first and oldest-first sorting in gallery
12. **Hidden Files**: Use the eye icon to show/hide hidden files and folders

## Controls

### Mouse Controls
- **Left Click**: Select/open files and folders
- **Right Click**: Quick preview of images in gallery (hold to view, release to close)
- **Long Press**: Start multi-selection mode in gallery

### Keyboard Shortcuts
- **Escape**: Close image preview overlay
- **Arrow Keys**: Navigate between images in viewer
- **Enter**: Confirm dialog actions
- **Ctrl+C**: Copy image to clipboard (requires xclip on Linux)

### Selection Mode
- **Long Press**: Enter selection mode and select first image
- **Tap**: Add/remove images from selection while in selection mode
- **Select All**: Button to select all visible images
- **Copy**: Copy selected images to chosen destination folder
- **Cancel**: Exit selection mode (X button)

## Architecture

- **State Management**: Built-in Flutter state management with StatefulWidget
- **File System**: Dart's `dart:io` for cross-platform file operations
- **Image Handling**: Optimized with ResizeImage and efficient caching
- **Performance**: Lazy loading, batch processing, and scroll position memory
- **Sorting**: Real-time sorting with `statSync()` for accurate file modification times
- **Memory Management**: Efficient batch processing prevents UI blocking during large scans
- **EXIF Processing**: Image metadata extraction using `exif` package
- **Geolocation**: Offline country detection with custom bounding box database (217 countries)
- **Clipboard**: Platform-specific clipboard integration (xclip on Linux)
- **Country Database**: Lightweight offline database (~16KB) with smart conflict resolution

## Dependencies

### Flutter Packages
- **flutter_svg** (^2.0.10+1): SVG image rendering
- **exif** (^3.3.0): EXIF metadata extraction from images
- **path** (^1.8.3): Cross-platform path manipulation
- **path_provider** (^2.1.1): Access to common file system locations

### System Requirements (Linux)
- **xclip**: Clipboard management for image copy functionality
  ```bash
  sudo apt install xclip
  ```

## Contributing

Contributions are welcome! This project demonstrates modern Flutter development practices including:
- Efficient file system navigation
- Performance-optimized image handling
- Responsive UI design
- Cross-platform compatibility
- Advanced user interactions (multi-selection, drag operations)
- Real-time file system monitoring and updates
- Custom dialog implementations with validation
- Pointer event handling for enhanced user experience
- EXIF metadata processing and GPS coordinate extraction
- Offline geolocation with custom database implementation
- Platform-specific clipboard integration
- Keyboard shortcuts and hotkey handling

## License

This project is open source and available under the [MIT License](LICENSE).