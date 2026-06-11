import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../call/screens/calling_screen.dart';
import '../../call/utils/phone_validator.dart';

class ContactDetailsScreen extends StatelessWidget {
  final String contactName;
  final String phoneNumber;

  const ContactDetailsScreen({
    super.key,
    required this.contactName,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 60, 255),
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),

        title: Text(
          phoneNumber,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,

            child: Column(
              children: [
                SizedBox(height: 50.h),

                CircleAvatar(
                  radius: 50.r,
                  backgroundColor: Colors.grey.shade300,

                  child: Text(
                    contactName.isNotEmpty ? contactName[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 40.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                Text(
                  contactName,
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 20.h),

                GestureDetector(
                  onTap: () {
                    if (!isValidPhoneNumber(phoneNumber)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Invalid Country Code or Number"),
                        ),
                      );

                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CallingScreen(
                          phoneNumber: phoneNumber,
                          contactName: contactName,
                        ),
                      ),
                    );
                  },

                  child: Container(
                    width: 60.w,
                    height: 60.w,

                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8.r,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Icon(Icons.call, color: Colors.white, size: 38.sp),
                  ),
                ),

                SizedBox(height: 40.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              phoneNumber,
                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 18.h),

                            Text("Kuwait", style: TextStyle(fontSize: 18.sp)),
                          ],
                        ),
                      ),

                      SizedBox(width: 15.w),

                      Text("0.014 د.ك/min", style: TextStyle(fontSize: 16.sp)),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
