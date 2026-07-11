import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/admin_content_page_model.dart';
import '../services/admin_content_service.dart';

class AdminContentEditScreen extends StatefulWidget {
  final AdminContentPageModel? page;

  const AdminContentEditScreen({super.key, this.page});

  @override
  State<AdminContentEditScreen> createState() => _AdminContentEditScreenState();
}

class _AdminContentEditScreenState extends State<AdminContentEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _slugController;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  String _selectedLanguage = 'en';
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.page != null;

  @override
  void initState() {
    super.initState();

    final page = widget.page;

    _slugController = TextEditingController(text: page?.slug ?? '');

    _titleController = TextEditingController(text: page?.title ?? '');

    _contentController = TextEditingController(text: page?.content ?? '');

    _selectedLanguage = page?.language.toLowerCase() ?? 'en';
    _isActive = page?.isActive ?? true;
  }

  @override
  void dispose() {
    _slugController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _savePage() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await AdminContentService.updatePage(
          id: widget.page!.id,
          slug: _slugController.text,
          title: _titleController.text,
          content: _contentController.text,
          language: _selectedLanguage,
          isActive: _isActive,
        );
      } else {
        await AdminContentService.createPage(
          slug: _slugController.text,
          title: _titleController.text,
          content: _contentController.text,
          language: _selectedLanguage,
          isActive: _isActive,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Page updated successfully'
                : 'Page created successfully',
          ),
          backgroundColor: const Color(0xFF168B4B),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '').trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateSlug(String? value) {
    final slug = value?.trim() ?? '';

    if (slug.isEmpty) {
      return 'Slug is required';
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(slug)) {
      return 'Use lowercase letters, numbers and underscore only';
    }

    return null;
  }

  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';

    if (title.isEmpty) {
      return 'Title is required';
    }

    if (title.length < 2) {
      return 'Title is too short';
    }

    return null;
  }

  String? _validateContent(String? value) {
    final content = value?.trim() ?? '';

    if (content.isEmpty) {
      return 'Content is required';
    }

    if (content.length < 5) {
      return 'Content is too short';
    }

    return null;
  }

  String _languageName(String code) {
    switch (code) {
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
          _isEditing ? 'Edit Content Page' : 'Create Content Page',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 120.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Page Information'),

                SizedBox(height: 10.h),

                _fieldContainer(
                  child: TextFormField(
                    controller: _slugController,
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: _validateSlug,
                    decoration: const InputDecoration(
                      labelText: 'Slug',
                      hintText: 'example: privacy_policy',
                      prefixIcon: Icon(Icons.link),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                _fieldContainer(
                  child: TextFormField(
                    controller: _titleController,
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.next,
                    validator: _validateTitle,
                    decoration: const InputDecoration(
                      labelText: 'Page Title',
                      hintText: 'Example: Privacy Policy',
                      prefixIcon: Icon(Icons.title),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                _fieldContainer(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      prefixIcon: Icon(Icons.language),
                      border: InputBorder.none,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedLanguage = value;
                            });
                          },
                  ),
                ),

                SizedBox(height: 12.h),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE0E5ED)),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      _isActive ? Icons.visibility : Icons.visibility_off,
                      color: _isActive ? const Color(0xFF168B4B) : Colors.grey,
                    ),
                    title: const Text(
                      'Page Status',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'Active — users can view this page'
                          : 'Inactive — page will be hidden',
                    ),
                    value: _isActive,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                  ),
                ),

                SizedBox(height: 24.h),

                _sectionTitle('Page Content'),

                SizedBox(height: 10.h),

                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: const Color(0xFFE0E5ED)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _contentController,
                    enabled: !_isSaving,
                    minLines: 12,
                    maxLines: 30,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    validator: _validateContent,
                    decoration: InputDecoration(
                      hintText:
                          'Write the complete ${_languageName(_selectedLanguage)} page content here...',
                      border: InputBorder.none,
                      alignLabelWithHint: true,
                    ),
                    style: TextStyle(
                      fontSize: 15.sp,
                      height: 1.55,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),

                SizedBox(height: 26.h),

                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _savePage,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1145F5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    icon: _isSaving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isEditing
                                ? Icons.save_outlined
                                : Icons.add_circle_outline,
                          ),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : _isEditing
                          ? 'Save Changes'
                          : 'Create Page',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  Widget _fieldContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE0E5ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: child,
    );
  }
}
