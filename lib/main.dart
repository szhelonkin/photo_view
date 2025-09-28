import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

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

      setState(() {
        _currentDirectory = directory;
        _entities = entities;
        _isLoading = false;
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

  void _onEntityTap(FileSystemEntity entity) {
    if (entity is Directory) {
      _loadDirectory(entity);
    }
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

                            return ListTile(
                              leading: Icon(
                                isDirectory
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                                color: isDirectory
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: isDirectory
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                              onTap: () => _onEntityTap(entity),
                              dense: true,
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
              child: Center(
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
                      'Select a directory from the file explorer to browse photos',
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
