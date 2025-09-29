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

### 🔍 **Image Viewer**
- **Full-Screen Viewing**: Clean, distraction-free image display
- **Pan & Zoom**: Interactive viewer with zoom (0.5x - 4x) and pan support
- **Navigation Controls**: Previous/next buttons with current position indicator
- **File Information**: Display filename and full clickable path
- **SVG Support**: Full support for SVG files alongside standard image formats

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

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- For desktop builds: platform-specific requirements
  - **Linux**: `clang cmake ninja-build pkg-config libgtk-3-dev`
  - **Windows**: Visual Studio with C++ components

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

## License

This project is open source and available under the [MIT License](LICENSE).