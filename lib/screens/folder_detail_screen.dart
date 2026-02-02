import 'package:flutter/material.dart';
import 'package:expense_tracker/models/folder_model.dart';
import 'package:expense_tracker/models/file_model.dart'; // Ensure this is imported
import 'package:expense_tracker/providers/storage_provider.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/widgets/fade_in_slide.dart';
import 'package:expense_tracker/widgets/add_folder_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:expense_tracker/widgets/full_screen_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:expense_tracker/widgets/custom_background.dart';

class FolderDetailScreen extends StatefulWidget {
  final FolderModel folder;
  final List<String> breadcrumbs;

  const FolderDetailScreen({
    super.key,
    required this.folder,
    this.breadcrumbs = const ['My Folder'],
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animationController;
  Stream<List<FolderModel>>? _foldersStream;
  Stream<List<FileModel>>? _filesStream;
  late Animation<double> _animation;
  bool _streamsInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize streams here where Provider context is guaranteed to be ready
    if (!_streamsInitialized) {
      final storage = Provider.of<StorageProvider>(context, listen: false);
      _foldersStream = storage.getSubFoldersStream(widget.folder.id);
      _filesStream = storage.getFilesInFolder(widget.folder.id);
      _streamsInitialized = true;
      print("DEBUG: Streams initialized in didChangeDependencies for folder ${widget.folder.id}");
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isMenuOpen) ...[
            _buildSpeedDialOption(
              assetPath: 'assets/icons/add_folder_v2.png',
              label: 'Folder',
              color: Colors.blueAccent,
              delay: 0.1,
              onTap: () {
                _toggleMenu();
                showAddFolderDialog(context, parentId: widget.folder.id);
              },
            ),
            const SizedBox(height: 12),
            _buildSpeedDialOption(
              assetPath: 'assets/icons/image_icon.png',
              label: 'Image',
              color: Colors.purpleAccent,
              delay: 0.05,
              onTap: () {
                _toggleMenu();
                _pickAndUpload(context, FileType.image);
              },
            ),
            const SizedBox(height: 12),
            _buildSpeedDialOption(
              assetPath: 'assets/icons/video_icon.png',
              label: 'Video',
              color: Colors.redAccent,
              delay: 0.02,
              onTap: () {
                _toggleMenu();
                _pickAndUpload(context, FileType.video);
              },
            ),
            const SizedBox(height: 12),
            _buildSpeedDialOption(
              assetPath: 'assets/icons/doc_icon_v2.png',
              label: 'Doc',
              color: Colors.orangeAccent,
              delay: 0.0,
              onTap: () {
                _toggleMenu();
                _pickAndUpload(context, FileType.doc); // Using FileModel's FileType
              },
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            onPressed: _toggleMenu,
            backgroundColor: const Color(0xFF0D1C2E),
            shape: const CircleBorder(),
            child: AnimatedRotation(
              turns: _isMenuOpen ? 0.125 : 0, // 45 degrees rotation
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header & Breadcrumbs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                    ),
                    const Icon(Icons.search, size: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...widget.breadcrumbs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final crumb = entry.value;
                        
                        return GestureDetector(
                          onTap: () {
                             final popCount = widget.breadcrumbs.length - index;
                             int count = 0;
                             Navigator.popUntil(context, (_) => count++ >= popCount);
                          },
                          child: Row(
                            children: [
                              Text(
                                crumb,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(Icons.chevron_right, color: Colors.black, size: 20),
                              ),
                            ],
                          ),
                        );
                      }),
                      Text(
                        widget.folder.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1C2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Folders Section
              _buildSectionHeader(context, 'Folders'),
              const SizedBox(height: 16),
              SizedBox(
                height: 155,
                child: _foldersStream == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<FolderModel>>(
                  stream: _foldersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                  if (snapshot.hasError) {
                    print("----------------------------------------------------------------");
                    print("FIRESTORE FILES ERROR (Click the link below to create index):");
                    print(snapshot.error);
                    print("----------------------------------------------------------------");
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.build_circle_outlined, color: Colors.orange, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Database Setup Required',
                              style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Check your terminal/console for a link to create the required index.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                    final subfolders = snapshot.data ?? [];

                    if (subfolders.isEmpty) {
                       return Center(
                        child: Text('No folders', style: TextStyle(color: Colors.grey[400])),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: subfolders.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                         final subfolder = subfolders[index];
                        return FadeInSlide(
                          delay: 0.05 * (index + 1), // Faster stagger
                          child: _buildFolderCard(
                            folder: subfolder,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Files Section
              _buildSectionHeader(context, 'Files'),
              const SizedBox(height: 16),
              
              _filesStream == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<FileModel>>(
                stream: _filesStream,
                builder: (context, snapshot) {
                  print("DEBUG [${widget.folder.id}]: ConnectionState=${snapshot.connectionState}, HasData=${snapshot.hasData}, Data=${snapshot.data?.length ?? 'null'}");
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    print("ERROR [${widget.folder.id}]: ${snapshot.error}");
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  
                  final files = snapshot.data ?? [];
                  print("FolderDetailScreen [${widget.folder.id}]: Stream received ${files.length} files");

                  if (files.isEmpty) {
                    print("FolderDetailScreen [${widget.folder.id}]: Files list is empty, showing placeholder");
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('No files in this folder', style: TextStyle(color: Colors.grey[400])),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: files.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return FadeInSlide(
                        delay: 0.05 * (index + 1),
                        child: _buildFileRow(files[index]),
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildSpeedDialOption({
    required String assetPath,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required double delay,
  }) {
    // Glassmorphism Button
    return FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: _animation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Label tag (optional, glass card)
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(8),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.08),
                     blurRadius: 8,
                   )
                 ]
               ),
               child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D1C2E))),
             ),
             const SizedBox(width: 12),
            
            // The Button
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Image.asset(assetPath),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, FileType type) async { // Using FileModel's FileType
    File? file;
    final picker = ImagePicker();

    try {
      if (type == FileType.image) {
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) file = File(picked.path);
      } else if (type == FileType.video) {
        final picked = await picker.pickVideo(source: ImageSource.gallery);
        if (picked != null) file = File(picked.path);
      } else {
        // Use aliased fp.FileType.any for generic picker or custom if needed
        final result = await fp.FilePicker.platform.pickFiles();
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
        }
      }

      if (file != null) {
        if (!mounted) return;
        _showGlassSnackBar(context, 'Uploading...', isError: false);
        
        await Provider.of<StorageProvider>(context, listen: false).uploadFile(
          file, 
          widget.folder.id, 
          type
        );
        
        if (!mounted) return;
        _showGlassSnackBar(context, 'Upload successful!', isError: false);
      }
    } catch (e) {
      if (!mounted) return;
      _showGlassSnackBar(context, 'Upload failed: $e', isError: true);
    }
  }

  void _showGlassSnackBar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isError ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline, 
                    color: isError ? Colors.redAccent : Colors.tealAccent, 
                    size: 24
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message, 
                      style: const TextStyle(color: Color(0xFF0D1C2E), fontWeight: FontWeight.w600),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero, // Important for custom content
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1C2E),
            ),
          ),
          Icon(Icons.more_horiz, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildFileRow(FileModel file) {
    // Determine icon and color based on file.type
    String asset = 'assets/icons/doc_icon_v2.png';
    if (file.type == FileType.video) asset = 'assets/icons/video_icon.png';
    if (file.type == FileType.image) asset = 'assets/icons/image_icon.png';

    Widget iconWidget;
    if (file.type == FileType.image && file.url != null && file.url!.isNotEmpty) {
      final heroTag = 'folder_${file.id}';
      iconWidget = GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImage(
                imageUrl: file.url!,
                heroTag: heroTag,
              ),
            ),
          );
        },
        child: Hero(
          tag: heroTag,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(file.url!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    } else {
      iconWidget = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(asset, width: 24, height: 24),
      );
    }

    return Slidable(
      key: ValueKey(file.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) => _confirmDeleteFile(file),
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFFFE4A49),
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                       color: Color(0xFF0D1C2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${file.size} • ${file.createdAt.day}/${file.createdAt.month}/${file.createdAt.year}",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteFile(FileModel file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.lightBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.red.withOpacity(0.2),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Delete File',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to delete "${file.name}"? This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        _showGlassSnackBar(context, 'Deleting...', isError: false);
        await Provider.of<StorageProvider>(context, listen: false).deleteFile(file);
        if (mounted) {
          _showGlassSnackBar(context, 'File deleted successfully', isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showGlassSnackBar(context, 'Delete failed: $e', isError: true);
        }
      }
    }
  }

  Widget _buildFolderCard({
    required FolderModel folder,
  }) {
    // Parse color string to Color object
    Color folderColor;
    try {
      folderColor = Color(int.parse(folder.color));
    } catch (e) {
      folderColor = const Color(0xFF90CAF9); // Default
    }

    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => FolderDetailScreen(
                 folder: folder,
                 breadcrumbs: [...widget.breadcrumbs, widget.folder.name],
               )),
            );
          },
          child: Container(
            width: 160,
            height: 135,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    folder.iconAsset.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(folder.iconAsset, width: 65, height: 65, fit: BoxFit.cover),
                          )
                        : Icon(Icons.folder, color: folderColor, size: 65),
                    Icon(Icons.more_horiz, color: Colors.grey[400], size: 20),
                  ],
                ),
                const Spacer(),
                Text(
                  folder.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0D1C2E),
                  ),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${folder.itemCount} files',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                    Text(
                      folder.totalSize,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF0D1C2E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
