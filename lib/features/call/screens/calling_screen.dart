import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../recents/data/recent_calls_data.dart';
import '../../wallet/data/wallet_data.dart';
import '../data/country_rates.dart';
import '../../call/utils/phone_validator.dart';
import '../../wallet/data/wallet_api_service.dart';

///import 'package:share_plus/share_plus.dart';
class CallingScreen extends StatefulWidget {
  final String phoneNumber;
  final String contactName;

  const CallingScreen({
    super.key,
    required this.phoneNumber,
    required this.contactName,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  /// =========================================
  /// Button States
  /// =========================================

  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isBluetoothOn = false;
  bool isRecording = false;
  bool showKeypad = false;

  /// =========================================
  /// Timer
  /// =========================================
  Timer? timer;
  int seconds = 0;
  double callCost = 0.0;
  bool firstMinuteCharged = false;
  late CountryRate currentCountryRate;

  /// Wallet & Billing
  int? callSessionId;

  @override
  void initState() {
    super.initState();
    currentCountryRate = getCountryRate(widget.phoneNumber);
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        seconds++;
      });

      /// ==========================
      /// TELECOM BILLING LOGIC
      /// ==========================

      int chargedMinutes = 0;

      if (seconds > 3) {
        chargedMinutes = ((seconds - 1) ~/ 60) + 1;
      }

      double totalCost = chargedMinutes * currentCountryRate.ratePerMinute;

      callCost = totalCost;

      /// =========================
      /// Insufficient Balance
      /// =========================
      if (currentBalance <= 0) {
        timer.cancel();

        showDialog(
          context: context,
          barrierDismissible: false,

          builder: (_) => AlertDialog(
            title: const Text("Insufficient Balance"),

            content: const Text("Your wallet balance is finished."),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.pop(context);
                },

                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    });
  }

  String formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;

    int remainingSeconds = totalSeconds % 60;

    String min = minutes.toString().padLeft(2, '0');

    String sec = remainingSeconds.toString().padLeft(2, '0');

    return "$min:$sec";
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),

            child: Column(
              children: [
                SizedBox(height: 15.h),

                /// =====================================
                /// Avatar Animation
                /// =====================================
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.95, end: 1.05),

                  duration: const Duration(seconds: 1),

                  curve: Curves.easeInOut,

                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,

                      child: Container(
                        width: 90.w,
                        height: 90.w,

                        decoration: BoxDecoration(
                          color: const Color.fromARGB(26, 161, 207, 250),
                          shape: BoxShape.circle,
                        ),

                        child: Icon(
                          Icons.person,
                          color: const Color.fromARGB(179, 252, 253, 255),
                          size: 35.sp,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 15.h),

                /// =====================================
                /// Ringing
                /// =====================================
                Text(
                  "Ringing",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10.h),

                /// =====================================
                /// Name
                /// =====================================
                Text(
                  widget.contactName,

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10.h),

                /// =====================================
                /// Number
                /// =====================================
                Text(
                  widget.phoneNumber,

                  style: TextStyle(color: Colors.white70, fontSize: 22.sp),
                ),

                SizedBox(height: 10.h),

                /// =====================================
                /// Timer
                /// =====================================
                Text(
                  formatTime(seconds),

                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 102, 255),
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10.h),

                /// =====================================
                /// Country
                /// =====================================
                Text(
                  currentCountryRate.countryName,

                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),

                SizedBox(height: 10.h),

                /// =====================================
                /// Rate
                /// =====================================
                Text(
                  "Per-minute rate: ${currentCountryRate.ratePerMinute.toStringAsFixed(3)} د.ك",

                  style: TextStyle(color: Colors.white, fontSize: 15.sp),
                ),

                SizedBox(height: 10.h),

                /// =====================================
                /// Minutes
                /// =====================================
                Text(
                  "Remaining Minutes: ${(currentBalance / 0.004).floor()}",
                  style: TextStyle(color: Colors.white, fontSize: 15.sp),
                ),

                SizedBox(height: 25.h),

                /// =====================================
                /// Buttons Row 1
                /// =====================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                  children: [
                    buildCallButton(
                      icon: isMuted ? Icons.mic_off : Icons.mic,
                      label: "Mute",

                      isActive: isMuted,

                      onTap: () {
                        setState(() {
                          isMuted = !isMuted;
                        });
                      },
                    ),

                    buildCallButton(
                      icon: Icons.fiber_manual_record,
                      label: "Rec",

                      isActive: isRecording,

                      onTap: () {
                        setState(() {
                          isRecording = !isRecording;
                        });
                      },
                    ),
                    buildCallButton(
                      icon: isSpeakerOn ? Icons.volume_up : Icons.hearing,

                      label: "Speaker",

                      isActive: isSpeakerOn,

                      onTap: () {
                        setState(() {
                          isSpeakerOn = !isSpeakerOn;
                        });
                      },
                    ),
                  ],
                ),

                SizedBox(height: 15.h),

                /// =====================================
                /// Buttons Row 2
                /// =====================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                  children: [
                    /// End Button
                    GestureDetector(
                      onTap: () async {
                        if (!isValidPhoneNumber(widget.phoneNumber)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Invalid Country Code or Number"),
                            ),
                          );

                          return;
                        }

                        timer?.cancel();

                        /// ==========================
                        /// TELECOM BILLING LOGIC
                        /// ==========================

                        int chargedMinutes = 0;
                        if (seconds > 3) {
                          chargedMinutes = ((seconds - 1) ~/ 60) + 1;
                        }

                        callCost =
                            chargedMinutes * currentCountryRate.ratePerMinute;

                        /// =========================
                        /// Save Recent Call
                        /// =========================

                        if (seconds > 0) {
                          recentCalls.insert(0, {
                            "name": widget.contactName,
                            "number": widget.phoneNumber,
                            "timeAgo": "Just now",
                            "duration": formatTime(seconds),
                            "date": "Today",
                            "callTime": TimeOfDay.now().format(context),
                            "type": "outgoing",
                          });

                          await saveRecentCalls();
                        }

                        /// =========================
                        /// Show Call Summary Popup
                        /// =========================
                        await deductWalletBalance(callCost);
                        currentBalance = await fetchWalletBalance();
                        setState(() {});

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.black,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),

                              title: const Text(
                                "Call Summary",
                                style: TextStyle(color: Colors.white),
                              ),

                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    "Duration: ${formatTime(seconds)}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  Text(
                                    "Call Cost: ${callCost.toStringAsFixed(3)} KWD",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  Text(
                                    "Remaining Balance: ${currentBalance.toStringAsFixed(3)} KWD",

                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),

                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },

                                  child: const Text(
                                    "OK",
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },

                      child: Column(
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.w,

                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),

                            child: Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),

                          SizedBox(height: 10.h),

                          Text(
                            "End",

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// =========================================
  /// Reusable Button
  /// =========================================

  Widget buildCallButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),

            width: 62.w,
            height: 62.w,

            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.white,

              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,

              color: isActive ? Colors.white : Colors.black,

              size: 20.sp,
            ),
          ),

          SizedBox(height: 10.h),

          Text(
            label,

            style: TextStyle(color: Colors.white, fontSize: 16.sp),
          ),
        ],
      ),
    );
  }
}
