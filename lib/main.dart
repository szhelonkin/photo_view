import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:exif/exif.dart';

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
  bool _sortNewestFirst = true;
  bool _sortByExifDate = false;
  Directory? _currentGalleryDirectory;
  bool _galleryLoadCompleted = false;
  final ScrollController _galleryScrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<File> _selectedImages = {};
  File? _previewImage;
  bool _showPreview = false;
  
  // Кэш для EXIF-дат
  final Map<String, DateTime?> _exifDateCache = {};
  bool _isSortingByExif = false;
  
  static const List<String> _imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeDirectory();
  }

  @override
  void dispose() {
    _galleryScrollController.dispose();
    super.dispose();
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
        _currentGalleryDirectory = null;
        _isLoadingGallery = false;
        _galleryLoadCompleted = false;
        // Reset selection mode when changing directory
        _isSelectionMode = false;
        _selectedImages.clear();
        // Clear EXIF cache when changing directory
        _exifDateCache.clear();
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

  Future<DateTime?> _getExifDateTime(File file) async {
    final filePath = file.path;
    
    // Проверяем кэш сначала
    if (_exifDateCache.containsKey(filePath)) {
      return _exifDateCache[filePath];
    }
    
    // Только для JPEG файлов - другие форматы редко содержат EXIF
    final extension = path.extension(filePath).toLowerCase();
    if (!extension.contains('jpg') && !extension.contains('jpeg')) {
      _exifDateCache[filePath] = null;
      return null;
    }
    
    try {
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);
      
      // Пробуем разные EXIF теги для даты съемки
      String? dateTimeString = data['EXIF DateTimeOriginal']?.toString() ??
                              data['EXIF DateTime']?.toString() ??
                              data['Image DateTime']?.toString();
      
      DateTime? result;
      if (dateTimeString != null) {
        // EXIF дата в формате: "YYYY:MM:DD HH:MM:SS"
        // Заменяем первые два двоеточия на дефисы для даты
        final parts = dateTimeString.split(' ');
        if (parts.isNotEmpty) {
          final datePart = parts[0].replaceAll(':', '-');
          final timePart = parts.length > 1 ? parts[1] : '00:00:00';
          dateTimeString = '${datePart}T$timePart';
        }
        
        try {
          result = DateTime.parse(dateTimeString);
        } catch (e) {
          // Если парсинг не удался, пробуем другой формат
          final parts = dateTimeString.split(' ');
          if (parts.length >= 2) {
            final datePart = parts[0].replaceAll(':', '-');
            final timePart = parts[1];
            result = DateTime.parse('${datePart}T$timePart');
          }
        }
      }
      
      // Кэшируем результат
      _exifDateCache[filePath] = result;
      return result;
    } catch (e) {
      // Ошибка чтения EXIF - кэшируем null
      _exifDateCache[filePath] = null;
      return null;
    }
  }

  String _getFolderName(File file) {
    final directory = path.dirname(file.path);
    return path.basename(directory);
  }

  Color _getFolderColor(String folderName) {
    // Набор красивых цветов для папок
    final colors = [
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF2196F3), // Blue
      const Color(0xFF03DAC6), // Teal
      const Color(0xFF4CAF50), // Green
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFCDDC39), // Lime
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFFFF9800), // Orange
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
      const Color(0xFF009688), // Teal variant
      const Color(0xFFFF6F00), // Amber
    ];

    // Создаем простой хеш из имени папки
    int hash = 0;
    for (int i = 0; i < folderName.length; i++) {
      hash = hash * 31 + folderName.codeUnitAt(i);
    }
    
    // Используем абсолютное значение хеша для выбора цвета
    final colorIndex = hash.abs() % colors.length;
    return colors[colorIndex];
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    // Вычисляем яркость цвета используя формулу относительной яркости
    final r = (backgroundColor.r * 255.0).round() & 0xff;
    final g = (backgroundColor.g * 255.0).round() & 0xff;
    final b = (backgroundColor.b * 255.0).round() & 0xff;
    
    final brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    
    // Если цвет темный, используем белый текст, иначе черный
    return brightness < 0.5 ? Colors.white : Colors.black;
  }

  void _sortGalleryImages() {
    if (_sortByExifDate) {
      _sortGalleryImagesByExif();
    } else {
      _sortGalleryImagesByFileDate();
    }
  }

  void _sortGalleryImagesByFileDate() {
    _allGalleryImages.sort((a, b) {
      try {
        // Используем statSync для более точной информации о файле
        final aStat = a.statSync();
        final bStat = b.statSync();
        
        // Используем modified time (время изменения файла)
        final aModified = aStat.modified;
        final bModified = bStat.modified;
        
        return _sortNewestFirst 
            ? bModified.compareTo(aModified) // Новые сначала
            : aModified.compareTo(bModified); // Старые сначала
      } catch (e) {
        // Fallback к старому методу в случае ошибки
        try {
          final aModified = a.lastModifiedSync();
          final bModified = b.lastModifiedSync();
          return _sortNewestFirst 
              ? bModified.compareTo(aModified)
              : aModified.compareTo(bModified);
        } catch (e2) {
          // Если и это не работает, сортируем по имени
          return path.basename(a.path).compareTo(path.basename(b.path));
        }
      }
    });
  }

  void _sortGalleryImagesByExif() {
    // Для EXIF сортировки используем асинхронный подход
    setState(() {
      _isSortingByExif = true;
    });
    _sortGalleryImagesAsync();
  }

  Future<void> _sortGalleryImagesAsync() async {
    if (_allGalleryImages.isEmpty) return;
    
    // Создаем список пар [файл, дата] для эффективной сортировки
    final List<({File file, DateTime date})> fileWithDates = [];
    
    // Обрабатываем файлы батчами для лучшей производительности
    const batchSize = 10;
    for (int i = 0; i < _allGalleryImages.length; i += batchSize) {
      final end = (i + batchSize > _allGalleryImages.length) 
          ? _allGalleryImages.length 
          : i + batchSize;
      final batch = _allGalleryImages.sublist(i, end);
      
      // Обрабатываем батч параллельно
      final futures = batch.map((file) async {
        DateTime date;
        
        // Пробуем получить EXIF дату
        final exifDate = await _getExifDateTime(file);
        if (exifDate != null) {
          date = exifDate;
        } else {
          // Fallback к дате изменения файла
          try {
            date = file.statSync().modified;
          } catch (e) {
            try {
              date = file.lastModifiedSync();
            } catch (e2) {
              date = DateTime(1970); // Очень старая дата для файлов с ошибками
            }
          }
        }
        
        return (file: file, date: date);
      });
      
      // Ждем завершения батча
      final batchResults = await Future.wait(futures);
      fileWithDates.addAll(batchResults);
      
      // Небольшая пауза между батчами для отзывчивости UI
      if (i % (batchSize * 5) == 0) {
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
    
    // Финальная сортировка
    fileWithDates.sort((a, b) {
      return _sortNewestFirst 
          ? b.date.compareTo(a.date) // Новые сначала
          : a.date.compareTo(b.date); // Старые сначала
    });
    
    // Обновляем список файлов
    _allGalleryImages.clear();
    _allGalleryImages.addAll(fileWithDates.map((item) => item.file));
    
    // Финальное обновление UI
    if (mounted) {
      setState(() {
        _isSortingByExif = false;
      });
    }
  }

  List<String> _getPathSegments(String filePath) {
    final directory = path.dirname(filePath);
    final parts = directory.split(Platform.pathSeparator);
    return parts.where((part) => part.isNotEmpty).toList();
  }

  String _buildPathUpTo(List<String> segments, int index) {
    if (index < 0) return Platform.pathSeparator;
    final pathParts = segments.sublist(0, index + 1);
    return Platform.pathSeparator + pathParts.join(Platform.pathSeparator);
  }

  Future<void> _copySelectedImages() async {
    if (_selectedImages.isEmpty) return;

    // Показать диалог выбора папки
    final result = await showDialog<Directory>(
      context: context,
      builder: (context) => _FolderPickerDialog(currentDirectory: _currentDirectory!),
    );

    if (result != null) {
      try {
        // Копировать файлы
        for (final file in _selectedImages) {
          final fileName = path.basename(file.path);
          final newPath = path.join(result.path, fileName);
          await file.copy(newPath);
        }

        // Показать уведомление об успехе
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied ${_selectedImages.length} images'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Выйти из режима выбора
        setState(() {
          _isSelectionMode = false;
          _selectedImages.clear();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copy error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _selectAllImages() {
    setState(() {
      _selectedImages.addAll(_allGalleryImages);
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedImages.clear();
    });
  }

  void _showImagePreview(File imageFile) {
    setState(() {
      _previewImage = imageFile;
      _showPreview = true;
    });
  }

  void _hideImagePreview() {
    setState(() {
      _showPreview = false;
      _previewImage = null;
    });
  }

  Future<void> _createNewFolder() async {
    if (_currentDirectory == null) return;

    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => _CreateFolderDialog(),
    );

    if (folderName != null && folderName.trim().isNotEmpty) {
      try {
        final newFolderPath = path.join(_currentDirectory!.path, folderName.trim());
        final newFolder = Directory(newFolderPath);
        
        // Проверяем, что папка не существует
        if (await newFolder.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Folder "$folderName" already exists'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Создаем папку
        await newFolder.create();
        
        // Обновляем список файлов
        await _loadDirectory(_currentDirectory!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Folder "$folderName" created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating folder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildImagePreview() {
    if (_previewImage == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event.logicalKey.keyLabel == 'Escape') {
            _hideImagePreview();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _hideImagePreview,
          child: Container(
          color: Colors.black.withValues(alpha: 0.8),
          child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isSvgFile(_previewImage!)
                  ? SvgPicture.file(
                      _previewImage!,
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Image.file(
                      _previewImage!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ошибка загрузки изображения',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
        ),
        ),
      ),
    );
  }

  void _scrollToImageInGallery(File imageFile) {
    final index = _allGalleryImages.indexOf(imageFile);
    if (index >= 0 && _galleryScrollController.hasClients) {
      // Получаем размеры из LayoutBuilder контекста
      final screenWidth = MediaQuery.of(context).size.width;
      const double itemSize = 180.0;
      const double spacing = 12.0;
      const double padding = 16.0;
      
      // Точно вычисляем количество колонок как в LayoutBuilder
      final availableWidth = screenWidth - (padding * 2);
      final crossAxisCount = ((availableWidth + spacing) / (itemSize + spacing)).floor().clamp(1, 10);
      
      // Вычисляем строку элемента
      final row = (index / crossAxisCount).floor();
      
      // Точно вычисляем высоту строки
      final rowHeight = itemSize + spacing;
      
      // Целевая позиция с учетом паддинга
      final targetOffset = (row * rowHeight).clamp(0.0, _galleryScrollController.position.maxScrollExtent);
      
      _galleryScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildClickablePath(String filePath) {
    final segments = _getPathSegments(filePath);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Root directory
          GestureDetector(
            onTap: () {
              _loadDirectory(Directory(Platform.pathSeparator));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                Platform.pathSeparator,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Path segments
          ...segments.asMap().entries.map((entry) {
            final index = entry.key;
            final segment = entry.value;
            final fullPath = _buildPathUpTo(segments, index);
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Platform.pathSeparator,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _loadDirectory(Directory(fullPath));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      segment,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
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
    if (_allGalleryImages.isNotEmpty && _currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
        _selectedImage = _allGalleryImages[_currentImageIndex];
      });
    }
  }

  void _navigateToNextImage() {
    if (_allGalleryImages.isNotEmpty && _currentImageIndex < _allGalleryImages.length - 1) {
      setState(() {
        _currentImageIndex++;
        _selectedImage = _allGalleryImages[_currentImageIndex];
      });
    }
  }

  Future<void> _loadGalleryImages(Directory directory) async {
    // If already loading the same directory, don't start again
    if (_isLoadingGallery && _currentGalleryDirectory?.path == directory.path) return;
    
    setState(() {
      _isLoadingGallery = true;
      _allGalleryImages.clear();
      _currentGalleryDirectory = directory;
    });

    try {
      final List<File> batch = [];
      const int batchSize = 50;
      
      await for (FileSystemEntity entity in directory.list(recursive: true, followLinks: false)) {
        // Check if we're still loading the same directory
        if (_currentGalleryDirectory?.path != directory.path) {
          // Directory changed, stop loading
          return;
        }
        
        if (entity is File && _isImageFile(entity)) {
          // Filter hidden files if needed
          if (_showHiddenFiles || !_isHiddenFile(entity)) {
            batch.add(entity);
            
            // Process in batches for better performance
            if (batch.length >= batchSize) {
              _allGalleryImages.addAll(batch);
              batch.clear();
              
              // Sort after adding each batch so user sees correctly ordered images
              _sortGalleryImages();
              
              // Update UI and yield to prevent blocking
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 1));
            }
          }
        }
      }
      
      // Add remaining files
      if (batch.isNotEmpty) {
        _allGalleryImages.addAll(batch);
        // Sort the final batch too
        _sortGalleryImages();
      }
    } catch (e) {
      debugPrint('Error discovering images: $e');
    }
    
    // Only update state if we're still loading the same directory
    if (_currentGalleryDirectory?.path == directory.path) {
      setState(() {
        _isLoadingGallery = false;
        _galleryLoadCompleted = true;
      });
      
      // Final sort to ensure everything is in correct order
      // (though images should already be sorted from batches)
      _sortGalleryImages();
    }
  }


  Widget _buildOptimizedGallery() {
    if (_allGalleryImages.isEmpty && !_isLoadingGallery && !_galleryLoadCompleted) {
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
                        : _isSortingByExif
                            ? 'Sorting by EXIF data...'
                            : '${_allGalleryImages.length} images found',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSelectionMode) ...[
                    Text(
                      '${_selectedImages.length} selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _selectAllImages,
                      icon: const Icon(Icons.select_all),
                      tooltip: 'Select all',
                    ),
                    IconButton(
                      onPressed: _selectedImages.isNotEmpty ? _copySelectedImages : null,
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy selected',
                    ),
                    IconButton(
                      onPressed: _cancelSelection,
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel selection',
                    ),
                  ] else ...[
                    if (!_isLoadingGallery && _allGalleryImages.isNotEmpty) ...[
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _sortByExifDate = !_sortByExifDate;
                          });
                          _sortGalleryImages();
                        },
                        icon: Icon(_sortByExifDate ? Icons.camera_alt : Icons.access_time),
                        tooltip: _sortByExifDate ? 'Sort by EXIF date' : 'Sort by file date',
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _sortNewestFirst = !_sortNewestFirst;
                            _sortGalleryImages();
                          });
                        },
                        icon: Icon(_sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward),
                        tooltip: _sortNewestFirst ? 'Sort oldest first' : 'Sort newest first',
                      ),
                    ],
                  ],
                  if (_isLoadingGallery || _isSortingByExif)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
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
                    const double itemSize = 180.0;
                    const double spacing = 12.0;
                    const double padding = 16.0;
                    
                    // Используем тот же расчет, что и в _scrollToImageInGallery
                    final availableWidth = constraints.maxWidth - (padding * 2);
                    final crossAxisCount = ((availableWidth + spacing) / (itemSize + spacing)).floor().clamp(1, 10);
                    
                    return GridView.builder(
                      controller: _galleryScrollController,
                      padding: const EdgeInsets.all(padding),
                      cacheExtent: 1000, // Кэшируем больше элементов
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
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
    final isSelected = _selectedImages.contains(imageFile);
    
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        if (event.buttons == 2) { // Правая кнопка мыши
          _showImagePreview(imageFile);
        }
      },
      onPointerUp: (PointerUpEvent event) {
        if (event.buttons == 0 && _showPreview) { // Отпускание любой кнопки
          _hideImagePreview();
        }
      },
      child: GestureDetector(
        onTap: () {
          if (_isSelectionMode) {
            // В режиме выбора - добавить/убрать из выбранных
            setState(() {
              if (isSelected) {
                _selectedImages.remove(imageFile);
              } else {
                _selectedImages.add(imageFile);
              }
            });
          } else {
            // Обычный режим - открыть просмотрщик
            final galleryIndex = _allGalleryImages.indexOf(imageFile);
            setState(() {
              _selectedImage = imageFile;
              _currentImageIndex = galleryIndex >= 0 ? galleryIndex : 0;
            });
            
            // Через небольшую задержку прокрутить к изображению при возврате
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToImageInGallery(imageFile);
            });
          }
        },
        onLongPress: () {
          // Долгое нажатие включает режим выбора
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedImages.add(imageFile);
            });
          }
        },
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                )
              : null,
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
                            image: ResizeImage(
                              FileImage(imageFile),
                              width: 360, // Больший размер для качества
                              allowUpscaling: false,
                            ),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            onError: (error, stackTrace) {},
                          ),
                        ),
                        child: Container(), // Пустой контейнер для показа ошибки
                      ),
              ),
              // File name at bottom
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
              // Folder name at top
              Positioned(
                top: 4,
                left: 4,
                right: _isSelectionMode ? 40 : 4, // Leave space for selection indicator
                child: Builder(
                  builder: (context) {
                    final folderName = _getFolderName(imageFile);
                    final backgroundColor = _getFolderColor(folderName);
                    final textColor = _getTextColorForBackground(backgroundColor);
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: backgroundColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        folderName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              // Добавляем индикатор выбора
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
                ),
              // Показываем номер в режиме выбора
              if (_isSelectionMode && !isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'File Explorer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_currentDirectory != null)
                        IconButton(
                          onPressed: _createNewFolder,
                          icon: const Icon(Icons.create_new_folder),
                          tooltip: 'Create new folder',
                          iconSize: 20,
                        ),
                    ],
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
                                    _buildClickablePath(_selectedImage!.path),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final currentImage = _selectedImage;
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                  
                                  // Восстановить позицию в галерее
                                  if (currentImage != null) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _scrollToImageInGallery(currentImage);
                                    });
                                  }
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
                                '${_currentImageIndex + 1} / ${_allGalleryImages.length}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: _currentImageIndex < _allGalleryImages.length - 1 ? _navigateToNextImage : null,
                              icon: const Icon(Icons.arrow_forward_ios),
                              tooltip: 'Next image',
                            ),
                          ],
                        ),
                      ],
                    )
                  : _currentDirectory != null
                      ? Stack(
                          children: [
                            _buildOptimizedGallery(),
                            if (_showPreview && _previewImage != null)
                              _buildImagePreview(),
                          ],
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

class _FolderPickerDialog extends StatefulWidget {
  final Directory currentDirectory;

  const _FolderPickerDialog({required this.currentDirectory});

  @override
  State<_FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<_FolderPickerDialog> {
  late Directory _currentDirectory;
  List<Directory> _directories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentDirectory = widget.currentDirectory;
    _loadDirectories();
  }

  Future<void> _loadDirectories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entities = await _currentDirectory.list().toList();
      final directories = entities
          .whereType<Directory>()
          .where((dir) => !path.basename(dir.path).startsWith('.'))
          .toList();
      
      directories.sort((a, b) => path.basename(a.path)
          .toLowerCase()
          .compareTo(path.basename(b.path).toLowerCase()));

      setState(() {
        _directories = directories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToDirectory(Directory directory) {
    setState(() {
      _currentDirectory = directory;
    });
    _loadDirectories();
  }

  void _navigateToParent() {
    final parent = _currentDirectory.parent;
    if (parent.path != _currentDirectory.path) {
      _navigateToDirectory(parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Folder for Copy'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            // Путь и кнопка "Вверх"
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _currentDirectory.parent.path != _currentDirectory.path 
                        ? _navigateToParent 
                        : null,
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: 'Up',
                  ),
                  Expanded(
                    child: Text(
                      _currentDirectory.path,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Список папок
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _directories.isEmpty
                      ? const Center(
                          child: Text('No available folders'),
                        )
                      : ListView.builder(
                          itemCount: _directories.length,
                          itemBuilder: (context, index) {
                            final directory = _directories[index];
                            final name = path.basename(directory.path);
                            
                            return ListTile(
                              leading: const Icon(Icons.folder, color: Colors.blue),
                              title: Text(name),
                              onTap: () => _navigateToDirectory(directory),
                              dense: true,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_currentDirectory),
          child: const Text('Select This Folder'),
        ),
      ],
    );
  }
}

class _CreateFolderDialog extends StatefulWidget {
  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _controller.text.trim();
    final isValidName = text.isNotEmpty && 
        !text.contains('/') && 
        !text.contains('\\') && 
        !text.contains(':') && 
        !text.contains('*') && 
        !text.contains('?') && 
        !text.contains('"') && 
        !text.contains('<') && 
        !text.contains('>') && 
        !text.contains('|');
    
    setState(() {
      _isValid = isValidName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Folder name',
              hintText: 'Enter new folder name',
              errorText: _controller.text.isNotEmpty && !_isValid 
                  ? 'Invalid characters in folder name' 
                  : null,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              if (_isValid) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Invalid characters: / \\ : * ? " < > |',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
