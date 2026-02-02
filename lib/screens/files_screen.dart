import 'package:flutter/material.dart';
import 'package:expense_tracker/widgets/fade_in_slide.dart';
import 'package:flutter/cupertino.dart';
import 'package:expense_tracker/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/widgets/storage_chart_painter.dart';
import 'package:expense_tracker/screens/folder_detail_screen.dart';
import 'package:expense_tracker/widgets/scale_button.dart';
import 'package:expense_tracker/screens/edit_profile_screen.dart';
import 'package:expense_tracker/widgets/add_folder_dialog.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/storage_provider.dart';
import 'package:expense_tracker/models/folder_model.dart';
import 'package:expense_tracker/models/file_model.dart';
import 'package:expense_tracker/widgets/full_screen_image.dart';
import 'package:expense_tracker/widgets/custom_background.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser;
    final displayName = user?.displayName ?? 'User';

    return CustomBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show gradient
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddFolderDialog(context),
        backgroundColor: const Color(0xFF0D1C2E), // Dark Blue
        shape: const CircleBorder(),
        child: Image.asset(
          'assets/icons/add_folder_v2.png',
          color: Colors.white,
          width: 32,
          height: 32,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String currentDisplayName = displayName; // Default from Auth
                    String? photoUrl = user?.photoURL;

                    if (snapshot.hasData && snapshot.data?.data() != null) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      currentDisplayName = data['displayName'] ?? currentDisplayName;
                      photoUrl = data['photoUrl'] ?? photoUrl;
                    }

                    return Row(
                      children: [
                        ScaleButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                            );
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? const Icon(Icons.person, color: Colors.blue)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $currentDisplayName',
                                style: const TextStyle(
                                  color: Color(0xFF0D1C2E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Your storage almost full.',
                                style: TextStyle(
                                  color: Color(0xFF0D1C2E),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search file..',
                      hintStyle: TextStyle(color: Colors.grey),
                      icon: Icon(Icons.search, color: Colors.grey),
                      // Align icon to the right if needed, but standard is left
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Storage Dashboard Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeInSlide(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1C2E), // Dark Blue
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        // Circular Progress
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            children: [
                              Center(
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CustomPaint(
                                    size: const Size(100, 100),
                                    painter: StorageChartPainter(
                                      videoValue: 0.5, // 50%
                                      imageValue: 0.25, // 25%
                                      docValue: 0.1, // 10%
                                      videoColor: const Color(0xFF024DAA),
                                      imageColor: const Color(0xFF0275FF),
                                      docColor: const Color(0xFFABD1FF),
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const Center(
                                child: Text(
                                  '85%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Legend
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendItem(
                                label: 'Videos',
                                iconAsset: 'assets/icons/video_icon.png',
                                color: const Color(0xFF024DAA),
                                percentage: 0.7,
                              ),
                              const SizedBox(height: 12),
                              _buildLegendItem(
                                label: 'Pictures',
                                iconAsset: 'assets/icons/image_icon.png',
                                color: const Color(0xFF0275FF),
                                percentage: 0.5,
                              ),
                              const SizedBox(height: 12),
                              _buildLegendItem(
                                label: 'Document',
                                iconAsset: 'assets/icons/doc_icon_v2.png',
                                color: const Color(0xFFABD1FF),
                                percentage: 0.3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // My Folders
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Folders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1C2E),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'sync') {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Syncing folder stats...')),
                           );
                           try {
                             await Provider.of<StorageProvider>(context, listen: false).syncFolderStats();
                              ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Done!')),
                             );
                           } catch(e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                           }
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                           const PopupMenuItem<String>(
                            value: 'sync',
                            child: Row(
                              children: [
                                Icon(Icons.sync, size: 20, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Sync Folder Stats'),
                              ],
                            ),
                          ),
                        ];
                      },
                      child: Icon(Icons.more_horiz, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Horizontal Folder List
              SizedBox(
                height: 155,
                child: Consumer<StorageProvider>(
                  builder: (context, storage, child) {
                    return StreamBuilder<List<FolderModel>>(
                      stream: storage.userFoldersStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (snapshot.hasError) {
                          // allow the user to see the link in the debug console
                          print("----------------------------------------------------------------");
                          print("FIRESTORE ERROR (Click the link below to create index):");
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

                        final folders = snapshot.data ?? [];
                        
                        if (folders.isEmpty) {
                          return Center(
                            child: Text(
                              'No folders yet', 
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemCount: folders.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            return FadeInSlide(
                              delay: 0.1 * (index + 1),
                              child: _buildFolderCard(
                                folder: folder,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Recent Files
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Files',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                         color: Color(0xFF0D1C2E),
                      ),
                    ),
                    Icon(Icons.more_horiz, color: Colors.grey[400]),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Recent Files List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Consumer<StorageProvider>(
                  builder: (context, storage, child) {
                    return StreamBuilder<List<FileModel>>(
                      stream: storage.recentFilesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                        }

                        if (snapshot.hasError) {
                          print("RECENT FILES ERROR: ${snapshot.error}");
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Error loading recent files.\nCheck console for details.', 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red[300]),
                              ),
                            ),
                          );
                        }
                         
                        final files = snapshot.data ?? [];

                        if (files.isEmpty) {
                           return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('No recent files', style: TextStyle(color: Colors.grey[400])),
                            ),
                          );
                        }

                        return Column(
                          children: files.asMap().entries.map((entry) {
                            final index = entry.key;
                            final file = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FadeInSlide(
                                delay: 0.1 * (index + 1),
                                child: _buildRecentFileRow(
                                  file: file,
                                ),
                              ),
                            );
                          }).toList()
                           ..add(const Padding(padding: EdgeInsets.only(bottom: 80))), // Bottom padding
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildLegendItem({
    required String label,
    IconData? icon,
    String? iconAsset,
    required Color color,
    required double percentage,
  }) {
    return Row(
      children: [
        iconAsset != null
            ? Image.asset(iconAsset, width: 16, height: 16)
            : Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
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
              MaterialPageRoute(builder: (context) => FolderDetailScreen(folder: folder)),
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
                   ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(folder.iconAsset, width: 65, height: 65, fit: BoxFit.cover),
                      ),
                    
                    Icon(Icons.more_horiz, color: Colors.grey[400], size: 24),
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
      }
    );
  }

  Widget _buildRecentFileRow({
    required FileModel file,
  }) {
    // Determine icon and color based on file.type
    String asset = file.iconAsset ?? 'assets/icons/doc_icon_v2.png';
    Color bgColor = const Color(0xFFE3F2FD);

    if (file.type == FileType.video) {
      asset = 'assets/icons/video_icon.png';
    } else if (file.type == FileType.image) {
      asset = 'assets/icons/image_icon.png';
    }

    Widget iconWidget;
    if (file.type == FileType.image && file.url != null && file.url!.isNotEmpty) {
      final heroTag = 'recent_${file.id}';
      iconWidget = Builder(
        builder: (context) {
          return GestureDetector(
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
        }
      );
    } else {
      iconWidget = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(asset, width: 24, height: 24),
      );
    }
    
    // ... rest of the row building

    return Row(
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
        Icon(Icons.more_horiz, color: Colors.grey[400]),
      ],
    );
  }
}
