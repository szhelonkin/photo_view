import 'package:flutter/material.dart';
import 'dart:io';
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
      home: const MyHomePage(title: 'File Explorer'),
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
      final entities = await directory.list().toList();
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

  Widget _buildFileIcon(FileSystemEntity entity, bool isDirectory, bool isImageFile) {
    if (isDirectory) {
      return Icon(
        Icons.folder,
        color: Colors.blue,
        size: 32,
      );
    }
    
    if (isImageFile && entity is File) {
      if (_isSvgFile(entity)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 32,
            height: 32,
            child: SvgPicture.file(
              entity,
              fit: BoxFit.cover,
              placeholderBuilder: (context) => Icon(
                Icons.image,
                color: Colors.grey,
                size: 24,
              ),
            ),
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Image.file(
              entity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 32,
                );
              },
            ),
          ),
        );
      }
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

  Future<List<File>> _discoverAllImages(Directory directory) async {
    List<File> allImages = [];
    try {
      await for (FileSystemEntity entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File && _isImageFile(entity)) {
          allImages.add(entity);
        }
      }
    } catch (e) {
      debugPrint('Error discovering images: $e');
    }
    return allImages;
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _isSvgFile(imageFile)
              ? SvgPicture.file(
                  imageFile,
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  },
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
                                child: Text(
                                  path.basename(_selectedImage!.path),
                                  style: Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
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
                      ? FutureBuilder<List<File>>(
                          future: _discoverAllImages(_currentDirectory!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            
                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading gallery',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            final allImages = snapshot.data ?? [];
                            
                            if (allImages.isEmpty) {
                              return Center(
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
                                      'No Images Found',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This directory and its subdirectories contain no images',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gallery',
                                        style: Theme.of(context).textTheme.headlineMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${allImages.length} images found',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1,
                                    ),
                                    itemCount: allImages.length,
                                    itemBuilder: (context, index) {
                                      return _buildGalleryThumbnail(allImages[index]);
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        )
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
