import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../call/screens/calling_screen.dart';

class DialPadScreen extends StatefulWidget {
  const DialPadScreen({super.key});

  @override
  State<DialPadScreen> createState() => _DialPadScreenState();
}

class _DialPadScreenState extends State<DialPadScreen> {
  String phoneNumber = "";

  final List<Map<String, String>> dialPad = [
    {"number": "1", "letters": ""},
    {"number": "2", "letters": "ABC"},
    {"number": "3", "letters": "DEF"},
    {"number": "4", "letters": "GHI"},
    {"number": "5", "letters": "JKL"},
    {"number": "6", "letters": "MNO"},
    {"number": "7", "letters": "PQRS"},
    {"number": "8", "letters": "TUV"},
    {"number": "9", "letters": "WXYZ"},
    {"number": "*", "letters": ""},
    {"number": "0", "letters": "+"},
    {"number": "#", "letters": ""},
  ];

  void addNumber(String value) {
    setState(() {
      phoneNumber += value;
    });
  }

  void removeNumber() {
    if (phoneNumber.isNotEmpty) {
      setState(() {
        phoneNumber = phoneNumber.substring(0, phoneNumber.length - 1);
      });
    }
  }

  /// function to validate phone number based on country code and length
  bool isValidPhoneNumber(String number) {
    /// Bangladesh
    if (number.startsWith("+880") && number.length >= 14) {
      return true;
    }

    /// Kuwait
    if (number.startsWith("+965") && number.length >= 12) {
      return true;
    }

    /// India
    if (number.startsWith("+91") && number.length >= 13) {
      return true;
    }

    /// Pakistan
    if (number.startsWith("+92") && number.length >= 13) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 60, 255),
        elevation: 0,

        centerTitle: true,
      ),

      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15.h),

            /// =====================================
            /// Number Display
            /// =====================================
            Container(
              width: double.infinity,

              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),

              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),

                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6.r)],
              ),

              child: Text(
                phoneNumber.isEmpty ? "Enter Number" : phoneNumber,

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: const Color.fromARGB(221, 121, 121, 121),
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),

            SizedBox(height: 10.h),

            /// =====================================
            /// Dial Pad
            /// =====================================
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),

                padding: EdgeInsets.symmetric(horizontal: 55.w),

                itemCount: dialPad.length,

                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,

                  crossAxisSpacing: 8.w,

                  mainAxisSpacing: 10.h,

                  childAspectRatio: 1,
                ),

                itemBuilder: (context, index) {
                  final item = dialPad[index];

                  return GestureDetector(
                    onTap: () {
                      addNumber(item["number"]!);
                    },

                    onLongPress: () {
                      if (item["number"] == "0") {
                        addNumber("+");
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Text(
                          item["number"]!,

                          style: TextStyle(
                            color: const Color.fromARGB(255, 44, 44, 44),
                            fontSize: 35.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        Text(
                          item["letters"]!,

                          style: TextStyle(
                            color: const Color.fromARGB(255, 61, 61, 61),
                            fontSize: 14.sp,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            /// =====================================
            /// Bottom Buttons
            /// =====================================
            Padding(
              padding: EdgeInsets.only(bottom: 32.h, left: 40.w, right: 40.w),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  SizedBox(width: 20.w),

                  /// Call Button
                  GestureDetector(
                    onTap: () {
                      /// =========================
                      /// Empty Number
                      /// =========================

                      if (phoneNumber.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please Enter Phone Number"),
                          ),
                        );

                        return;
                      }

                      /// =========================
                      /// Country Code Required
                      /// =========================

                      if (!phoneNumber.startsWith("+")) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Country Code Invalid")),
                        );

                        return;
                      }

                      /// =========================
                      /// Full Validation
                      /// =========================

                      if (!isValidPhoneNumber(phoneNumber)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Invalid or Incomplete Number"),
                          ),
                        );

                        return;
                      }

                      /// =========================
                      /// Go To Calling Screen
                      /// =========================

                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => CallingScreen(
                            phoneNumber: phoneNumber,
                            contactName: "Unknown",
                          ),
                        ),
                      );
                    },

                    child: Container(
                      width: 72.w,
                      height: 72.w,

                      decoration: const BoxDecoration(
                        color: Color(0xFF19B35A),
                        shape: BoxShape.circle,
                      ),

                      child: Icon(Icons.call, color: Colors.white, size: 34.sp),
                    ),
                  ),

                  /// Delete Button
                  GestureDetector(
                    onTap: removeNumber,

                    child: Icon(
                      Icons.backspace_outlined,
                      color: const Color.fromARGB(255, 169, 169, 169),
                      size: 34.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
