import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../call/screens/calling_screen.dart';
import '../data/recent_calls_data.dart';

class RecentsScreen extends StatelessWidget {
  const RecentsScreen({super.key});

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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CallingScreen(
                          phoneNumber: call["number"],
                          contactName: call["name"],
                        ),
                      ),
                    );
                  },

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
                                      "${call["timeAgo"]} • ${call["duration"]}",

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
                                "${call["date"]} • ${call["callTime"]}",

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
