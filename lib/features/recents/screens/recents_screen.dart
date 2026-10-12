import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../call/screens/calling_screen.dart';
import '../data/recent_calls_data.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  bool _isCallConfirmationOpen = false;

  Future<void> _confirmCall(Map<String, dynamic> call) async {
    if (_isCallConfirmationOpen || !mounted) {
      return;
    }

    final number = (call["number"] ?? '').toString();
    final name = (call["name"] ?? 'Unknown').toString();

    if (number.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    _isCallConfirmationOpen = true;

    try {
      final shouldCall = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1B1B1B),
          scrollable: true,
          title: const Text(
            'Call this number?',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white)),
              SizedBox(height: 8.h),
              Text(
                number,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.call),
              label: const Text('Call'),
            ),
          ],
        ),
      );

      if (!mounted || shouldCall != true) {
        return;
      }

      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CallingScreen(phoneNumber: number, contactName: name),
        ),
      );
    } finally {
      _isCallConfirmationOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 68, 255),
        elevation: 0,

        centerTitle: true,
      ),

      body: recentCalls.isEmpty
          ? Center(
              child: Text(
                "No Recent Calls",
                style: TextStyle(color: Colors.white54, fontSize: 16.sp),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 30.h),

              itemCount: recentCalls.length,

              itemBuilder: (context, index) {
                final call = recentCalls[index];

                IconData callIcon;
                Color callColor;

                switch (call["type"]) {
                  case "incoming":
                    callIcon = Icons.call_received;
                    callColor = Colors.green;
                    break;

                  case "missed":
                    callIcon = Icons.call_missed;
                    callColor = Colors.red;
                    break;

                  default:
                    callIcon = Icons.call_made;
                    callColor = Colors.blue;
                }

                return InkWell(
                  onTap: () => _confirmCall(call),

                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 4.h,
                    ),

                    padding: EdgeInsets.all(20.w),

                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(18.r),
                    ),

                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28.r,
                          backgroundColor: Colors.white12,

                          child: Text(
                            call["name"][0],

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(width: 14.w),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                call["name"],

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),

                                overflow: TextOverflow.ellipsis,
                              ),

                              SizedBox(height: 4.h),

                              Text(
                                call["number"],

                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13.sp,
                                ),
                              ),

                              SizedBox(height: 6.h),

                              Row(
                                children: [
                                  Icon(callIcon, color: callColor, size: 16.sp),

                                  SizedBox(width: 6.w),

                                  Expanded(
                                    child: Text(
                                      "${call["timeAgo"]} • ${call["duration"]} • ${call["cost"] ?? "\$0.00"} • ${call["country"]} ",

                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12.sp,
                                      ),

                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 4.h),

                              Text(
                                "${call["date"]} • ${call["callTime"]} • ${call["callType"]}",

                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Icon(Icons.call, color: Colors.green, size: 24.sp),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
