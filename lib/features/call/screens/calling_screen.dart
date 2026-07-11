import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../recents/data/recent_calls_data.dart';
import '../../wallet/data/wallet_data.dart';
import '../data/country_rates.dart';
import '../../call/utils/phone_validator.dart';

import '../data/call_api_service.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';

import 'package:flutter/services.dart';

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
  double currentRateUsd = 0;
  bool firstMinuteCharged = false;
  late CountryRate currentCountryRate;

  static const MethodChannel _voiceChannel = MethodChannel(
    'netphone_twilio_voice',
  );

  /// Wallet & Billing
  int? callSessionId;

  Future<void> startBackendCall() async {
    try {
      final token = await StorageService.getToken();

      final sessionResult = await CallApiService.startCall(
        token: token ?? "",
        phoneNumber: widget.phoneNumber,
        baseUrl: AppConfig.baseUrl,
      );

      // print("📞 SESSION RESULT => $sessionResult");
      final rawSessionId = sessionResult["session"]["id"];

      final sessionData = sessionResult["session"];

      final pricePerMinCentsRaw = sessionData["price_per_min_cents"] ?? 0;

      final pricePerMinCents = pricePerMinCentsRaw is int
          ? pricePerMinCentsRaw
          : int.tryParse(pricePerMinCentsRaw.toString()) ?? 0;

      currentRateUsd = pricePerMinCents / 100.0;

      callSessionId = rawSessionId is int
          ? rawSessionId
          : int.parse(rawSessionId.toString());

      final voiceTokenResult = await CallApiService.getVoiceToken(
        token: token ?? "",
        baseUrl: AppConfig.baseUrl,
      );

      await _voiceChannel.invokeMethod('startCall', {
        'accessToken': voiceTokenResult["token"],
        'to': widget.phoneNumber,
        'sessionId': callSessionId.toString(),
      });

      setState(() {});
      startCallStatusPolling();
    } catch (e, s) {
      print("❌ CALLING SCREEN ERROR => $e");
      print("❌ STACK => $s");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Call failed: $e")));
      }
    }
  }

  Timer? statusTimer;
  bool hasAnswered = false;
  bool showTimer = false;

  void startCallStatusPolling() {
    statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (callSessionId == null) return;

      final token = await StorageService.getToken();
      final result = await CallApiService.getCallStatus(
        token: token ?? "",
        sessionId: callSessionId!,
        baseUrl: AppConfig.baseUrl,
      );

      final call = result["call"];
      final callStatus = call["status"];
      final providerStatus = call["provider_status"];
      final durationSec = call["duration_sec"];

      print(
        "📞 STATUS => provider=$providerStatus, status=$callStatus, duration=$durationSec",
      );

      if (!hasAnswered &&
          (providerStatus == "in-progress" || providerStatus == "answered")) {
        hasAnswered = true;
        showTimer = true;
        startTimer();
        setState(() {});
      }

      if (providerStatus == "completed" || callStatus == "charged") {
        statusTimer?.cancel();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    currentCountryRate = getCountryRate(widget.phoneNumber);

    startBackendCall();
  }

  void startTimer() {
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        seconds++;
      });
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
    statusTimer?.cancel();
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
                        width: 60.w,
                        height: 60.w,

                        decoration: BoxDecoration(
                          color: const Color.fromARGB(26, 161, 207, 250),
                          shape: BoxShape.circle,
                        ),

                        child: Icon(
                          Icons.person,
                          color: const Color.fromARGB(179, 252, 253, 255),
                          size: 20.sp,
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
                if (showTimer) ...[
                  Text(
                    formatTime(seconds),
                    style: TextStyle(
                      color: const Color.fromARGB(255, 0, 102, 255),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],

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
                  "Per-minute rate: \$${currentRateUsd.toStringAsFixed(2)}/min",

                  style: TextStyle(color: Colors.white, fontSize: 15.sp),
                ),

                SizedBox(height: 10.h),

                /// =====================================
                /// Minutes
                /// =====================================
                Text(
                  "Remaining Balance: \$${currentBalance.toStringAsFixed(2)} USD",
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

                      onTap: () async {
                        setState(() {
                          isMuted = !isMuted;
                        });

                        await _voiceChannel.invokeMethod('setMute', {
                          'enabled': isMuted,
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

                      onTap: () async {
                        setState(() {
                          isSpeakerOn = !isSpeakerOn;
                        });

                        await _voiceChannel.invokeMethod('setSpeaker', {
                          'enabled': isSpeakerOn,
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

                        statusTimer?.cancel();

                        try {
                          await _voiceChannel.invokeMethod('endCall');
                        } catch (e) {
                          print("❌ Native endCall failed => $e");
                        }

                        final token = await StorageService.getToken();

                        if (callSessionId != null) {
                          final endResult = await CallApiService.endCall(
                            token: token ?? "",
                            sessionId: callSessionId!,
                            baseUrl: AppConfig.baseUrl,
                          );
                          //print("📞 END RESULT => $endResult");
                          await Future.delayed(const Duration(seconds: 2));

                          // এখন নতুন করে Backend থেকে Final Status আনো
                          final finalStatus =
                              await CallApiService.getCallStatus(
                                token: token ?? "",
                                sessionId: callSessionId!,
                                baseUrl: AppConfig.baseUrl,
                              );

                          print("📞 END RESULT => $endResult");

                          final callData =
                              finalStatus["call"] ??
                              finalStatus["session"] ??
                              finalStatus;

                          final chargedCentsRaw =
                              callData["charged_amount_cents"] ??
                              endResult["charged_amount_cents"] ??
                              0;

                          final chargedCents = chargedCentsRaw is int
                              ? chargedCentsRaw
                              : int.tryParse(chargedCentsRaw.toString()) ?? 0;

                          callCost = chargedCents.abs() / 100.0;

                          final wallet = endResult["wallet"];
                          if (wallet != null &&
                              wallet["balance_cents"] != null) {
                            final balanceRaw = wallet["balance_cents"];
                            final balanceCents = balanceRaw is int
                                ? balanceRaw
                                : int.tryParse(balanceRaw.toString()) ?? 0;

                            currentBalance = balanceCents / 100.0;
                          }
                        }

                        /// Save Recent Call
                        if (seconds > 0) {
                          recentCalls.insert(0, {
                            "name": widget.contactName,
                            "number": widget.phoneNumber,
                            "timeAgo": "Just now",
                            "duration": formatTime(seconds),
                            "cost": "\$${callCost.toStringAsFixed(2)}",
                            "date": "Today",
                            "callTime": TimeOfDay.now().format(context),
                            "type": "outgoing",
                          });

                          await saveRecentCalls();
                        }

                        /// =========================
                        /// Show Call Summary Popup
                        /// =========================

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
                                    "Call Cost: \$${callCost.toStringAsFixed(2)} USD",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),

                                  SizedBox(height: 10),

                                  Text(
                                    "Remaining Balance: \$${currentBalance.toStringAsFixed(2)} USD",
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),

                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pop(context, true);
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
