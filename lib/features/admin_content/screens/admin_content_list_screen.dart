import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/admin_content_page_model.dart';
import '../services/admin_content_service.dart';
import 'admin_content_edit_screen.dart';

class AdminContentListScreen extends StatefulWidget {
  const AdminContentListScreen({super.key});

  @override
  State<AdminContentListScreen> createState() => _AdminContentListScreenState();
}

class _AdminContentListScreenState extends State<AdminContentListScreen> {
  late Future<List<AdminContentPageModel>> _pagesFuture;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  void _loadPages() {
    _pagesFuture = AdminContentService.getAllPages();
  }

  Future<void> _refreshPages() async {
    setState(() {
      _loadPages();
    });

    await _pagesFuture;
  }

  Future<void> _openCreateScreen() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminContentEditScreen()),
    );

    if (changed == true && mounted) {
      await _refreshPages();
    }
  }

  Future<void> _openEditScreen(AdminContentPageModel page) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminContentEditScreen(page: page)),
    );

    if (changed == true && mounted) {
      await _refreshPages();
    }
  }

  Future<void> _confirmDelete(AdminContentPageModel page) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Page'),
          content: Text(
            'Are you sure you want to delete "${page.title}"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      _showLoadingDialog();

      await AdminContentService.deletePage(page.id);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Page deleted successfully')),
      );

      await _refreshPages();
    } catch (error) {
      if (!mounted) return;

      Navigator.pop(context);

      _showErrorMessage(error);
    }
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _showErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Color _languageColor(String language) {
    switch (language.toLowerCase()) {
      case 'bn':
        return const Color(0xFF00897B);
      case 'ar':
        return const Color(0xFF8E24AA);
      default:
        return const Color(0xFF1565C0);
    }
  }

  String _languageLabel(String language) {
    switch (language.toLowerCase()) {
      case 'bn':
        return 'বাংলা';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Content Management',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshPages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1145F5),
        foregroundColor: Colors.white,
        onPressed: _openCreateScreen,
        icon: const Icon(Icons.add),
        label: const Text('New Page'),
      ),

      body: FutureBuilder<List<AdminContentPageModel>>(
        future: _pagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error.toString().replaceFirst(
              'Exception: ',
              '',
            );

            return _ErrorState(message: message, onRetry: _refreshPages);
          }

          final pages = snapshot.data ?? [];

          if (pages.isEmpty) {
            return _EmptyState(onCreate: _openCreateScreen);
          }

          return RefreshIndicator(
            onRefresh: _refreshPages,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: const Color(0xFFE1E6EF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18.r),
                      onTap: () => _openEditScreen(page),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46.w,
                              height: 46.w,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1145F5,
                                ).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: const Icon(
                                Icons.article_outlined,
                                color: Color(0xFF1145F5),
                              ),
                            ),

                            SizedBox(width: 14.w),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    page.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),

                                  SizedBox(height: 5.h),

                                  Text(
                                    page.slug,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),

                                  SizedBox(height: 10.h),

                                  Wrap(
                                    spacing: 8.w,
                                    runSpacing: 6.h,
                                    children: [
                                      _StatusChip(
                                        label: _languageLabel(page.language),
                                        color: _languageColor(page.language),
                                      ),
                                      _StatusChip(
                                        label: page.isActive
                                            ? 'Active'
                                            : 'Inactive',
                                        color: page.isActive
                                            ? const Color(0xFF1B9C55)
                                            : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            PopupMenuButton<String>(
                              tooltip: 'Options',
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openEditScreen(page);
                                }

                                if (value == 'delete') {
                                  _confirmDelete(page);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 10),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 54.sp),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: Colors.black87),
            ),
            SizedBox(height: 18.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, color: Colors.grey, size: 58.sp),
            SizedBox(height: 16.h),
            Text(
              'No content pages found',
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              'Create your first dynamic app page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13.sp),
            ),
            SizedBox(height: 18.h),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Page'),
            ),
          ],
        ),
      ),
    );
  }
}
