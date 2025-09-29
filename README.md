# Photo View

A cross-platform image gallery and file explorer built with Flutter. Browse, view, and manage your images with an intuitive interface designed for efficient navigation.

## Features

### 🗂️ **File Explorer**
- **Directory Navigation**: Browse through your file system with a clean sidebar interface
- **Breadcrumb Path**: Click any folder in the path to quickly jump to parent directories
- **Hidden Files Toggle**: Show/hide hidden files and folders (starting with `.`)
- **Home & Parent Navigation**: Quick access buttons in the app bar

### 🖼️ **Image Gallery**
- **Recursive Image Discovery**: Automatically finds all images in subdirectories
- **Smart Sorting**: Sort by modification time (newest/oldest first)
- **Grid Layout**: Adaptive grid that adjusts to screen size (180px square thumbnails)
- **Lazy Loading**: Efficient memory usage with batch processing (50 images at a time)
- **Scroll Position Memory**: Returns to exact position when closing image viewer

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

## Usage

1. **Start Browsing**: Launch the app to begin in your home directory
2. **Navigate Folders**: Use the file explorer sidebar or click path segments
3. **View Gallery**: Switch to gallery view to see all images in current directory tree
4. **Open Images**: Click any thumbnail to open full-screen viewer
5. **Navigate Images**: Use arrow buttons or keyboard to move between images
6. **Quick Navigation**: Click any folder name in the path to jump there instantly

## Architecture

- **State Management**: Built-in Flutter state management with StatefulWidget
- **File System**: Dart's `dart:io` for cross-platform file operations  
- **Image Handling**: Optimized with ResizeImage and efficient caching
- **Performance**: Lazy loading, batch processing, and scroll position memory

## Contributing

Contributions are welcome! This project demonstrates modern Flutter development practices including:
- Efficient file system navigation
- Performance-optimized image handling
- Responsive UI design
- Cross-platform compatibility

## License

This project is open source and available under the [MIT License](LICENSE).