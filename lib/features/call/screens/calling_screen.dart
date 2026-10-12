import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../recents/data/recent_calls_data.dart';
import '../../wallet/data/wallet_data.dart';
import '../data/country_rates.dart';
import '../../call/utils/phone_validator.dart';

import '../data/call_api_service.dart';
import '../models/telnyx_voice_state.dart';
import '../services/telnyx_voice_service.dart';
import '../../../services/native_call_service.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final TelnyxVoiceService _voiceService = TelnyxVoiceService();

  StreamSubscription<TelnyxVoiceState>? _voiceStateSubscription;

  String callStatusText = 'Calling';

  bool _isEndingCall = false;
  bool _summaryShown = false;
  bool _isDtmfKeypadOpen = false;
  BuildContext? _dtmfSheetContext;
  String _dtmfDigits = '';

  /// =========================================
  /// Button States
  /// =========================================

  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isBluetoothOn = false;

  /// =========================================
  /// Timer
  /// =========================================
  Timer? timer;
  int seconds = 0;
  double callCost = 0.0;
  double currentRateUsd = 0;
  bool firstMinuteCharged = false;
  late CountryRate currentCountryRate;

  /// Wallet & Billing
  int? callSessionId;

  Timer? statusTimer;
  bool hasAnswered = false;
  bool showTimer = false;

  void listenToTelnyxVoiceState() {
    _voiceStateSubscription?.cancel();

    _voiceStateSubscription = _voiceService.states.listen(
      (TelnyxVoiceState voiceState) {
        if (!mounted) {
          return;
        }

        String nextStatusText = callStatusText;

        switch (voiceState.status) {
          case TelnyxVoiceStatus.idle:
          case TelnyxVoiceStatus.requestingPermission:
          case TelnyxVoiceStatus.creatingSession:
          case TelnyxVoiceStatus.requestingToken:
          case TelnyxVoiceStatus.connecting:
          case TelnyxVoiceStatus.registered:
          case TelnyxVoiceStatus.initiating:
            nextStatusText = 'Calling';
            break;

          case TelnyxVoiceStatus.ringing:
            nextStatusText = 'Ringing';
            break;

          case TelnyxVoiceStatus.active:
            // Call receive হওয়ার পর status text লুকানো হবে।
            // নিচে শুধু call timer চলবে।
            nextStatusText = '';

            if (!hasAnswered) {
              hasAnswered = true;
              showTimer = true;
              startTimer();
            }
            break;

          case TelnyxVoiceStatus.reconnecting:
            nextStatusText = 'Calling';
            break;

          case TelnyxVoiceStatus.ending:
          case TelnyxVoiceStatus.ended:
            nextStatusText = 'Call ended';
            break;

          case TelnyxVoiceStatus.failed:
            nextStatusText = 'Call failed';
            break;
        }

        setState(() {
          callStatusText = nextStatusText;
          isMuted = voiceState.isMuted;
          isSpeakerOn = voiceState.isSpeakerEnabled;
        });

        if (voiceState.status == TelnyxVoiceStatus.failed) {
          final errorMessage = voiceState.errorMessage ?? 'Telnyx call failed';

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));

          Future<void>.microtask(endCurrentCall);
        }

        if (voiceState.status == TelnyxVoiceStatus.ended) {
          Future<void>.microtask(endCurrentCall);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('❌ TELNYX STATE LISTENER ERROR => $error');
        debugPrintStack(stackTrace: stackTrace);

        if (!mounted) {
          return;
        }

        setState(() {
          callStatusText = 'Call failed';
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Telnyx call failed: $error')));
      },
    );
  }

  Future<void> startBackendCall() async {
    try {
      if (!mounted) {
        return;
      }

      setState(() {
        callStatusText = 'Calling';
      });

      final token = await StorageService.getToken();

      if (token == null || token.trim().isEmpty) {
        throw Exception('Login token not found. Please login again.');
      }

      final sessionResult = await CallApiService.startCall(
        token: token,
        phoneNumber: widget.phoneNumber,
        baseUrl: AppConfig.baseUrl,
      );

      final sessionRaw = sessionResult['session'];

      if (sessionRaw is! Map) {
        throw const FormatException(
          'Backend response does not contain a valid call session.',
        );
      }

      final sessionData = Map<String, dynamic>.from(sessionRaw);

      final sessionIdRaw = sessionData['id'];

      final parsedSessionId = sessionIdRaw is int
          ? sessionIdRaw
          : int.tryParse(sessionIdRaw?.toString() ?? '');

      if (parsedSessionId == null || parsedSessionId <= 0) {
        throw const FormatException(
          'Backend returned an invalid call session ID.',
        );
      }

      final webrtcRaw = sessionResult['webrtc'];

      if (webrtcRaw is! Map) {
        throw const FormatException(
          'Backend response does not contain WebRTC call information.',
        );
      }

      final webrtcData = Map<String, dynamic>.from(webrtcRaw);

      final clientState = webrtcData['client_state']?.toString().trim();

      if (clientState == null || clientState.isEmpty) {
        throw const FormatException(
          'Backend did not return WebRTC client state.',
        );
      }

      final sellRateRaw = sessionData['sell_rate_usd_per_min'];
      final pricePerMinCentsRaw = sessionData['price_per_min_cents'];

      final sellRateUsd = double.tryParse(sellRateRaw?.toString() ?? '');

      final pricePerMinCents = int.tryParse(
        pricePerMinCentsRaw?.toString() ?? '',
      );

      if (!mounted) {
        return;
      }

      double? rateToSave;

      if (sellRateUsd != null && sellRateUsd > 0) {
        rateToSave = sellRateUsd;
      } else if (pricePerMinCents != null && pricePerMinCents > 0) {
        rateToSave = pricePerMinCents / 100.0;
      }

      if (rateToSave != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setDouble('last_call_sell_rate_usd_per_min', rateToSave);

        await prefs.setString(
          'last_call_country_name',
          currentCountryRate.countryName,
        );
      }

      setState(() {
        callSessionId = parsedSessionId;
        callStatusText = 'Calling';

        if (sellRateUsd != null && sellRateUsd > 0) {
          currentRateUsd = sellRateUsd;
        } else if (pricePerMinCents != null && pricePerMinCents > 0) {
          currentRateUsd = pricePerMinCents / 100.0;
        }
      });

      startCallStatusPolling();

      final tokenResult = await CallApiService.getWebrtcToken(
        token: token,
        baseUrl: AppConfig.baseUrl,
      );

      final sipToken = tokenResult['token']?.toString().trim();
      final callerIdName = tokenResult['caller_id_name']?.toString().trim();
      final callerIdNumber = tokenResult['caller_id_number']?.toString().trim();

      if (sipToken == null || sipToken.isEmpty) {
        throw const FormatException(
          'Backend did not return a Telnyx WebRTC token.',
        );
      }

      if (callerIdNumber == null || callerIdNumber.isEmpty) {
        throw const FormatException(
          'Backend did not return a caller ID number.',
        );
      }

      final safeCallerIdName = callerIdName == null || callerIdName.isEmpty
          ? 'NetPhone'
          : callerIdName;

      await _voiceService.ensureMicrophonePermission();
      await NativeCallService.start(); // <-- নতুন লাইন
      await _voiceService.connectWithToken(
        sipToken: sipToken,
        callerIdName: safeCallerIdName,
        callerIdNumber: callerIdNumber,
      );

      await _voiceService.startOutboundCall(
        callerIdName: safeCallerIdName,
        callerIdNumber: callerIdNumber,
        destinationNumber: widget.phoneNumber,
        clientState: clientState,
      );
    } catch (error, stackTrace) {
      await NativeCallService.stop();
      debugPrint('❌ START TELNYX CALL ERROR => $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        callStatusText = 'Call failed';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Call failed: $error')));

      await endCurrentCall();
    }
  }

  void startCallStatusPolling() {
    statusTimer?.cancel();

    statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || callSessionId == null) return;

      try {
        final token = await StorageService.getToken();

        final result = await CallApiService.getCallStatus(
          token: token ?? '',
          sessionId: callSessionId!,
          baseUrl: AppConfig.baseUrl,
        );

        final callRaw = result['call'];

        if (callRaw is! Map) {
          debugPrint('Invalid call status response: $result');
          return;
        }

        final call = Map<String, dynamic>.from(callRaw);
        final callStatus = call['status']?.toString() ?? '';
        final providerStatus = call['provider_status']?.toString() ?? '';

        if (!mounted) return;

        if (!hasAnswered &&
            (providerStatus == 'in-progress' || providerStatus == 'answered')) {
          hasAnswered = true;
          showTimer = true;
          startTimer();
          setState(() {});
        }

        if (providerStatus == 'completed' || callStatus == 'charged') {
          statusTimer?.cancel();
        }
      } catch (error, stackTrace) {
        debugPrint('Call status polling failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    currentCountryRate = getCountryRate(widget.phoneNumber);

    listenToTelnyxVoiceState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        startBackendCall();
      }
    });
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

  /// =========================================
  /// Call Finalization
  /// =========================================
  String _formatRate(double rate) {
    if (rate <= 0) return "0.0000";

    return rate
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  double? _readFiniteDouble(Map<String, dynamic> source, String key) {
    final parsed = double.tryParse(source[key]?.toString() ?? '');

    if (parsed == null || !parsed.isFinite) {
      return null;
    }

    return parsed;
  }

  int? _readInteger(Map<String, dynamic> source, String key) {
    return int.tryParse(source[key]?.toString() ?? '');
  }

  /// Call charge-এর জন্য 4 decimal দেখাবে।
  /// Example:
  /// 0.0503 => 0.0503
  /// 0.0070 => 0.0070
  String _formatCallAmount(double amount) {
    if (!amount.isFinite || amount <= 0) {
      return '0.0000';
    }

    return amount.abs().toStringAsFixed(4);
  }

  // ============================================================
  // 🇧🇩 ACTIVE CALL DTMF KEYPAD
  //
  // কাজ:
  // - Hotel / Bank / IVR call-এর সময় 0-9, *, # পাঠানো
  // - প্রতিটি key সরাসরি Telnyx active call-এ DTMF পাঠাবে
  // - Calling / Billing / Wallet logic পরিবর্তন করে না
  // ============================================================

  Future<void> _showDtmfKeypad() async {
    if (!mounted || _isDtmfKeypadOpen || _isEndingCall || _summaryShown) {
      return;
    }

    if (!_voiceService.hasActiveCall ||
        !_voiceService.currentState.isCallActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait until the call is connected to use the keypad.'),
        ),
      );

      return;
    }

    const tones = <String>[
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '*',
      '0',
      '#',
    ];

    String feedback = 'Tap a number to choose a menu option.';
    bool feedbackIsError = false;
    int pressSequence = 0;
    _isDtmfKeypadOpen = true;

    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          _dtmfSheetContext = sheetContext;

          return StatefulBuilder(
            builder: (keypadContext, setKeypadState) {
              return SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
                    decoration: const BoxDecoration(
                      color: Color(0xFF17181C),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        Text(
                          'Keypad',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 12.h),

                        Text(
                          'Pressed keys',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12.sp,
                          ),
                        ),

                        SizedBox(height: 6.h),

                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Text(
                              _dtmfDigits.isEmpty
                                  ? 'No keys pressed'
                                  : _dtmfDigits,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: _dtmfDigits.isEmpty
                                    ? Colors.white38
                                    : Colors.white,
                                fontSize: _dtmfDigits.isEmpty ? 14.sp : 24.sp,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 8.h),

                        Text(
                          feedback,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: feedbackIsError
                                ? Colors.redAccent
                                : Colors.white54,
                            fontSize: 12.sp,
                          ),
                        ),

                        SizedBox(height: 20.h),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tones.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 18,
                                childAspectRatio: 1.35,
                              ),
                          itemBuilder: (context, index) {
                            final tone = tones[index];

                            return Material(
                              color: const Color(0xFF292B31),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () async {
                                  if (!mounted ||
                                      _isEndingCall ||
                                      _summaryShown) {
                                    return;
                                  }

                                  final thisPress = ++pressSequence;
                                  HapticFeedback.selectionClick();

                                  setKeypadState(() {
                                    _dtmfDigits += tone;
                                    feedback =
                                        'Pressed $tone. Listen for the menu response.';
                                    feedbackIsError = false;
                                  });

                                  try {
                                    await _voiceService.sendDtmf(tone);
                                  } catch (error) {
                                    if (!mounted ||
                                        !keypadContext.mounted ||
                                        thisPress != pressSequence) {
                                      return;
                                    }

                                    setKeypadState(() {
                                      feedback = 'Unable to send $tone: $error';
                                      feedbackIsError = true;
                                    });
                                  }
                                },
                                child: Center(
                                  child: Text(
                                    tone,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 14.h),

                        TextButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      _dtmfSheetContext = null;
      _isDtmfKeypadOpen = false;
    }
  }

  Future<void> endCurrentCall() async {
    if (_isEndingCall || _summaryShown) {
      return;
    }

    // Close only this keypad before opening the call summary.
    final keypadContext = _dtmfSheetContext;
    if (keypadContext != null &&
        keypadContext.mounted &&
        ModalRoute.of(keypadContext)?.isCurrent == true) {
      Navigator.of(keypadContext).pop();
    }

    final callTimeText = TimeOfDay.now().format(context);

    _isEndingCall = true;

    timer?.cancel();
    statusTimer?.cancel();

    if (mounted) {
      setState(() {
        callStatusText = 'Ending';
      });
    }

    try {
      try {
        await _voiceService.endCall();
        await NativeCallService.stop();
      } catch (error, stackTrace) {
        debugPrint('⚠️ TELNYX END ERROR => $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      final token = await StorageService.getToken();

      Map<String, dynamic> endResult = <String, dynamic>{};
      Map<String, dynamic> finalStatus = <String, dynamic>{};

      if (callSessionId != null && token != null && token.trim().isNotEmpty) {
        try {
          endResult = await CallApiService.endCall(
            token: token,
            sessionId: callSessionId!,
            baseUrl: AppConfig.baseUrl,
          );

          await Future<void>.delayed(const Duration(seconds: 2));

          finalStatus = await CallApiService.getCallStatus(
            token: token,
            sessionId: callSessionId!,
            baseUrl: AppConfig.baseUrl,
          );
        } catch (error, stackTrace) {
          debugPrint('⚠️ BACKEND CALL FINALIZATION ERROR => $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      final dynamic callDataRaw =
          finalStatus['call'] ?? finalStatus['session'] ?? finalStatus;

      final callData = callDataRaw is Map
          ? Map<String, dynamic>.from(callDataRaw)
          : <String, dynamic>{};

      /// Exact decimal USD first.
      final chargedUsd =
          _readFiniteDouble(callData, 'charged_amount_usd') ??
          _readFiniteDouble(endResult, 'charged_amount_usd');

      /// Exact micro-USD second.
      final chargedMicroUsd =
          _readInteger(callData, 'charged_amount_microusd') ??
          _readInteger(endResult, 'charged_amount_microusd');

      /// Legacy cents final fallback.
      final chargedCents =
          _readInteger(callData, 'charged_amount_cents') ??
          _readInteger(endResult, 'charged_amount_cents') ??
          0;

      if (chargedUsd != null) {
        callCost = chargedUsd.abs();
      } else if (chargedMicroUsd != null) {
        callCost = chargedMicroUsd.abs() / 1000000.0;
      } else {
        callCost = chargedCents.abs() / 100.0;
      }

      final walletRaw = endResult['wallet'];

      if (walletRaw is Map) {
        final wallet = Map<String, dynamic>.from(walletRaw);

        final balanceUsd = _readFiniteDouble(wallet, 'balance_usd');

        final balanceMicroUsd = _readInteger(wallet, 'balance_microusd');

        final balanceCents = _readInteger(wallet, 'balance_cents');

        if (balanceUsd != null) {
          currentBalance = balanceUsd;
        } else if (balanceMicroUsd != null) {
          currentBalance = balanceMicroUsd / 1000000.0;
        } else if (balanceCents != null) {
          currentBalance = balanceCents / 100.0;
        }
      }

      if (seconds > 0) {
        recentCalls.insert(0, {
          'name': widget.contactName,
          'number': widget.phoneNumber,
          'timeAgo': 'Just now',
          'duration': formatTime(seconds),
          'cost': '\$${_formatCallAmount(callCost)}',
          'date': 'Today',
          'callTime': callTimeText,
          'type': 'outgoing',
        });

        await saveRecentCalls();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        callStatusText = 'Call ended';
      });

      _summaryShown = true;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Call Summary',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration: ${formatTime(seconds)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Text(
                  'Call Cost: \$${_formatCallAmount(callCost)} USD',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Text(
                  'Remaining Balance: '
                  '\$${currentBalance.toStringAsFixed(2)} USD',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      _isEndingCall = false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    statusTimer?.cancel();

    _voiceStateSubscription?.cancel();

    unawaited(_voiceService.dispose());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 20.h,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                      if (callStatusText.isNotEmpty) ...[
                        Text(
                          callStatusText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],

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
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 22.sp,
                        ),
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

                      /// =====================================
                      /// Country
                      /// =====================================
                      Text(
                        currentCountryRate.countryName,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.sp,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      /// =====================================
                      /// Rate
                      /// =====================================
                      Text(
                        "Per-minute rate: \$${_formatRate(currentRateUsd)}/min",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 15.sp),
                      ),

                      SizedBox(height: 10.h),

                      /// =====================================
                      /// Remaining Balance
                      /// =====================================
                      Text(
                        "Remaining Balance: \$${currentBalance.toStringAsFixed(2)} USD",
                        textAlign: TextAlign.center,
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
                              final nextMutedState = !isMuted;

                              try {
                                await _voiceService.setMuted(nextMutedState);

                                if (!mounted) {
                                  return;
                                }

                                setState(() {
                                  isMuted = nextMutedState;
                                });
                              } catch (error) {
                                if (!mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Mute failed: $error'),
                                  ),
                                );
                              }
                            },
                          ),

                          buildCallButton(
                            icon: Icons.dialpad,
                            label: "Keypad",
                            isActive: false,
                            onTap: () {
                              _showDtmfKeypad();
                            },
                          ),

                          buildCallButton(
                            icon: isSpeakerOn ? Icons.volume_up : Icons.hearing,
                            label: "Speaker",
                            isActive: isSpeakerOn,
                            onTap: () async {
                              final nextSpeakerState = !isSpeakerOn;

                              try {
                                await _voiceService.setSpeakerEnabled(
                                  nextSpeakerState,
                                );

                                if (!mounted) {
                                  return;
                                }

                                setState(() {
                                  isSpeakerOn = nextSpeakerState;
                                });
                              } catch (error) {
                                if (!mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Speaker failed: $error'),
                                  ),
                                );
                              }
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
                          GestureDetector(
                            onTap: () async {
                              if (!isValidPhoneNumber(widget.phoneNumber)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Invalid Country Code or Number',
                                    ),
                                  ),
                                );
                                return;
                              }

                              await endCurrentCall();
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
            );
          },
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
