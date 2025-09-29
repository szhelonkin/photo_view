import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo View with File Explorer',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Photo View'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Directory? _currentDirectory;
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;
  File? _selectedImage;
  List<File> _imageFiles = [];
  int _currentImageIndex = -1;
  final List<File> _allGalleryImages = [];
  bool _isLoadingGallery = false;
  bool _showHiddenFiles = false;
  
  static const List<String> _imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeDirectory();
  }

  Future<void> _loadHomeDirectory() async {
    try {
      final homeDir = Directory(Platform.environment['HOME'] ?? '/home');
      await _loadDirectory(homeDir);
    } catch (e) {
      debugPrint('Error loading home directory: $e');
    }
  }

  Future<void> _loadDirectory(Directory directory) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allEntities = await directory.list().toList();
      
      // Filter hidden files if needed
      final entities = allEntities.where((entity) {
        return _showHiddenFiles || !_isHiddenFile(entity);
      }).toList();
      
      entities.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return path.basename(a.path).toLowerCase().compareTo(
            path.basename(b.path).toLowerCase());
      });

      // Filter image files
      final imageFiles = entities
          .whereType<File>()
          .where((file) => _isImageFile(file))
          .toList();

      setState(() {
        _currentDirectory = directory;
        _entities = entities;
        _imageFiles = imageFiles;
        _isLoading = false;
        // Reset selection when changing directory
        _selectedImage = null;
        _currentImageIndex = -1;
        // Reset gallery when changing directory
        _allGalleryImages.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading directory: $e');
    }
  }

  void _navigateToParent() {
    if (_currentDirectory != null) {
      final parent = _currentDirectory!.parent;
      if (parent.path != _currentDirectory!.path) {
        _loadDirectory(parent);
      }
    }
  }

  bool _isImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return _imageExtensions.contains(extension);
  }
  
  bool _isSvgFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return extension == '.svg';
  }

  bool _isHiddenFile(FileSystemEntity entity) {
    final name = path.basename(entity.path);
    return name.startsWith('.');
  }

  Widget _buildFileIcon(FileSystemEntity entity, bool isDirectory, bool isImageFile) {
    if (isDirectory) {
      return Icon(
        Icons.folder,
        color: Colors.blue,
        size: 32,
      );
    }
    
    if (isImageFile && entity is File) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 32,
            height: 32,
            child: _isSvgFile(entity)
                ? SvgPicture.file(
                    entity,
                    fit: BoxFit.contain,
                    placeholderBuilder: (context) => Icon(
                      Icons.image,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  )
                : Image.file(
                    entity,
                    fit: BoxFit.contain,
                    cacheWidth: 64,
                    cacheHeight: 64,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 20,
                      );
                    },
                  ),
          ),
        ),
      );
    }
    
    return Icon(
      Icons.insert_drive_file,
      color: Colors.grey,
      size: 32,
    );
  }

  void _onEntityTap(FileSystemEntity entity) {
    if (entity is Directory) {
      _loadDirectory(entity);
    } else if (entity is File && _isImageFile(entity)) {
      final index = _imageFiles.indexOf(entity);
      setState(() {
        _selectedImage = entity;
        _currentImageIndex = index;
      });
    }
  }

  void _navigateToPreviousImage() {
    if (_imageFiles.isNotEmpty && _currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
        _selectedImage = _imageFiles[_currentImageIndex];
      });
    }
  }

  void _navigateToNextImage() {
    if (_imageFiles.isNotEmpty && _currentImageIndex < _imageFiles.length - 1) {
      setState(() {
        _currentImageIndex++;
        _selectedImage = _imageFiles[_currentImageIndex];
      });
    }
  }

  Future<void> _loadGalleryImages(Directory directory) async {
    if (_isLoadingGallery) return;
    
    setState(() {
      _isLoadingGallery = true;
      _allGalleryImages.clear();
    });

    try {
      await for (FileSystemEntity entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File && _isImageFile(entity)) {
          // Filter hidden files if needed
          if (_showHiddenFiles || !_isHiddenFile(entity)) {
            _allGalleryImages.add(entity);
            if (_allGalleryImages.length % 20 == 0) {
              setState(() {});
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error discovering images: $e');
    }
    
    setState(() {
      _isLoadingGallery = false;
    });
  }


  Widget _buildOptimizedGallery() {
    if (_allGalleryImages.isEmpty && !_isLoadingGallery) {
      _loadGalleryImages(_currentDirectory!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gallery',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLoadingGallery 
                        ? 'Scanning for images...'
                        : '${_allGalleryImages.length} images found',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (_isLoadingGallery)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: _allGalleryImages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoadingGallery) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Scanning for images...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ] else ...[
                        Icon(
                          Icons.photo_library,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No images found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final itemSize = 180.0;
                    final crossAxisCount = (constraints.maxWidth / (itemSize + 12)).floor().clamp(1, 10);
                    
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _allGalleryImages.length,
                      itemBuilder: (context, index) {
                        final imageFile = _allGalleryImages[index];
                        return _buildGalleryThumbnail(imageFile);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGalleryThumbnail(File imageFile) {
    return GestureDetector(
      onTap: () {
        final index = _imageFiles.indexOf(imageFile);
        setState(() {
          _selectedImage = imageFile;
          _currentImageIndex = index >= 0 ? index : 0;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          color: Theme.of(context).colorScheme.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              Positioned.fill(
                child: _isSvgFile(imageFile)
                    ? ClipRect(
                        child: SvgPicture.file(
                          imageFile,
                          fit: BoxFit.cover,
                          placeholderBuilder: (context) => Center(
                            child: Icon(
                              Icons.image,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(imageFile),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            onError: (error, stackTrace) {},
                          ),
                        ),
                        child: Container(), // Пустой контейнер для показа ошибки
                      ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    path.basename(imageFile.path),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_currentDirectory != null) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _showHiddenFiles = !_showHiddenFiles;
                });
                _loadDirectory(_currentDirectory!);
              },
              icon: Icon(_showHiddenFiles ? Icons.visibility_off : Icons.visibility),
              tooltip: _showHiddenFiles ? 'Hide hidden files' : 'Show hidden files',
            ),
            IconButton(
              onPressed: _loadHomeDirectory,
              icon: const Icon(Icons.home),
              tooltip: 'Go to home directory',
            ),
            IconButton(
              onPressed: _navigateToParent,
              icon: const Icon(Icons.arrow_upward),
              tooltip: 'Go to parent directory',
            ),
          ],
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    'File Explorer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_currentDirectory != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      _currentDirectory!.path,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : ListView.builder(
                          itemCount: _entities.length,
                          itemBuilder: (context, index) {
                            final entity = _entities[index];
                            final isDirectory = entity is Directory;
                            final name = path.basename(entity.path);

                            final isImageFile = !isDirectory && 
                                entity is File && _isImageFile(entity);
                            final isSelected = _selectedImage != null && 
                                entity is File && 
                                entity.path == _selectedImage!.path;
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: ListTile(
                                leading: _buildFileIcon(entity, isDirectory, isImageFile),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: isDirectory
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : null,
                                  ),
                                ),
                                onTap: () => _onEntityTap(entity),
                                dense: false,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _selectedImage != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.image,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      path.basename(_selectedImage!.path),
                                      style: Theme.of(context).textTheme.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedImage!.path,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                icon: const Icon(Icons.close),
                                tooltip: 'Close image',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Stack(
                            children: [
                              Center(
                                child: InteractiveViewer(
                              panEnabled: true,
                              boundaryMargin: const EdgeInsets.all(20),
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: _isSvgFile(_selectedImage!)
                                  ? SvgPicture.file(
                                      _selectedImage!,
                                      fit: BoxFit.contain,
                                      placeholderBuilder: (context) => Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Loading SVG...',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Image.file(
                                _selectedImage!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 64,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Error loading image',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        error.toString(),
                                        style: Theme.of(context).textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                            ],
                          ),
                        ),
                        // Navigation controls
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _currentImageIndex > 0 ? _navigateToPreviousImage : null,
                              icon: const Icon(Icons.arrow_back_ios),
                              tooltip: 'Previous image',
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1} / ${_imageFiles.length}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: _currentImageIndex < _imageFiles.length - 1 ? _navigateToNextImage : null,
                              icon: const Icon(Icons.arrow_forward_ios),
                              tooltip: 'Next image',
                            ),
                          ],
                        ),
                      ],
                    )
                  : _currentDirectory != null
                      ? _buildOptimizedGallery()
                      
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Photo View',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Navigate to a directory to view images',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
