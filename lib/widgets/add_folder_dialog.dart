import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/storage_provider.dart';

class AddFolderDialog extends StatefulWidget {
  final String? parentId;
  const AddFolderDialog({super.key, this.parentId});

  @override
  State<AddFolderDialog> createState() => _AddFolderDialogState();
}

class _AddFolderDialogState extends State<AddFolderDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createFolder() async {
    final name = _controller.text.trim();
    print("AddFolderDialog: Create button pressed. Name: '$name'");
    if (name.isNotEmpty) {
      try {
        print("AddFolderDialog: Calling StorageProvider.createFolder");
        // Show loading if needed, or just await
        await Provider.of<StorageProvider>(context, listen: false).createFolder(
          name,
          parentId: widget.parentId,
        );
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        print("AddFolderDialog: Error creating folder: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print("AddFolderDialog: Name is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folder name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Folder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1C2E),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Color(0xFF0D1C2E)),
              decoration: InputDecoration(
                hintText: 'Folder Name',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createFolder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1C2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showAddFolderDialog(BuildContext context, {String? parentId}) {
  showDialog(
    context: context,
    builder: (context) => AddFolderDialog(parentId: parentId),
  );
}
