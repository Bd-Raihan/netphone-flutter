import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/app_page.dart';
import '../services/app_page_service.dart';

class AppPageScreen extends StatefulWidget {
  final String slug;
  final String fallbackTitle;

  const AppPageScreen({
    super.key,
    required this.slug,
    required this.fallbackTitle,
  });

  @override
  State<AppPageScreen> createState() => _AppPageScreenState();
}

class _AppPageScreenState extends State<AppPageScreen> {
  late Future<AppPage> pageFuture;

  @override
  void initState() {
    super.initState();
    pageFuture = AppPageService.getPage(slug: widget.slug);
  }

  Future<void> refreshPage() async {
    setState(() {
      pageFuture = AppPageService.getPage(slug: widget.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        elevation: 0,
        title: Text(
          widget.fallbackTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: refreshPage, icon: const Icon(Icons.refresh)),
        ],
      ),

      body: FutureBuilder<AppPage>(
        future: pageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
            );
          }

          final page = snapshot.data!;

          return RefreshIndicator(
            onRefresh: refreshPage,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(18.w),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 8.h),

                    Text(
                      'Updated: ${page.updatedAt}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),

                    SizedBox(height: 18.h),

                    Text(
                      page.content,
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
