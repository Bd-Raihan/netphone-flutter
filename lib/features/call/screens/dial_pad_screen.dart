import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../call/screens/calling_screen.dart';

class DialPadScreen extends StatefulWidget {
  const DialPadScreen({super.key});

  @override
  State<DialPadScreen> createState() => _DialPadScreenState();
}

class _DialPadScreenState extends State<DialPadScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isPasting = false;

  final List<Map<String, String>> dialPad = const [
    {'number': '1', 'letters': ''},
    {'number': '2', 'letters': 'ABC'},
    {'number': '3', 'letters': 'DEF'},
    {'number': '4', 'letters': 'GHI'},
    {'number': '5', 'letters': 'JKL'},
    {'number': '6', 'letters': 'MNO'},
    {'number': '7', 'letters': 'PQRS'},
    {'number': '8', 'letters': 'TUV'},
    {'number': '9', 'letters': 'WXYZ'},
    {'number': '+', 'letters': ''},
    {'number': '0', 'letters': ''},
    {'number': '#', 'letters': ''},
  ];

  String get phoneNumber => _controller.text.trim();

  void _insertAtSelection(String value) {
    final text = _controller.text;
    final selection = _controller.selection;
    final hasValidSelection =
        selection.isValid &&
        selection.start <= text.length &&
        selection.end <= text.length;
    final start = hasValidSelection ? selection.start : text.length;
    final end = hasValidSelection ? selection.end : text.length;

    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, value),
      selection: TextSelection.collapsed(offset: start + value.length),
    );

    setState(() {});
  }

  Future<void> _pasteNumber() async {
    if (_isPasting) {
      return;
    }

    _isPasting = true;

    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);

      if (!mounted) {
        return;
      }

      // Match the characters already allowed by the number field.
      final value = (clipboard?.text ?? '').replaceAll(
        RegExp(r'[^0-9\+\#\-\s\(\)]'),
        '',
      );

      if (value.trim().isEmpty) {
        _showMessage('No phone number to paste');
        return;
      }

      _insertAtSelection(value);
    } on PlatformException {
      if (mounted) {
        _showMessage('Unable to paste. Please try again.');
      }
    } finally {
      _isPasting = false;
    }
  }

  void _addNumber(String value) {
    HapticFeedback.selectionClick();

    // + শুধু নম্বরের শুরুতে একবার যোগ করা যাবে
    if (value == '+') {
      if (_controller.text.contains('+')) {
        return;
      }

      _controller.text = '+${_controller.text}';

      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );

      setState(() {});
      return;
    }

    _insertAtSelection(value);
  }

  void _removeNumber() {
    HapticFeedback.selectionClick();

    if (_controller.text.isEmpty) {
      return;
    }

    final text = _controller.text;
    final selection = _controller.selection;
    final hasValidSelection =
        selection.isValid &&
        selection.start <= text.length &&
        selection.end <= text.length;
    var start = hasValidSelection ? selection.start : text.length;
    final end = hasValidSelection ? selection.end : text.length;

    if (start == end) {
      if (start == 0) {
        return;
      }
      start--;
    }

    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );

    setState(() {});
  }

  void _clearNumber() {
    HapticFeedback.mediumImpact();
    _controller.clear();
    setState(() {});
  }

  bool isValidPhoneNumber(String number) {
    final cleaned = number.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(cleaned);
  }

  void _startCall() {
    final number = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (number.isEmpty) {
      _showMessage('Please enter phone number');
      return;
    }

    if (!number.startsWith('+')) {
      _showMessage('Use country code, example: +880...');
      return;
    }

    if (!isValidPhoneNumber(number)) {
      _showMessage('Invalid or incomplete number');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CallingScreen(phoneNumber: number, contactName: 'Unknown'),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _dialButton(Map<String, String> item) {
    final number = item['number']!;
    final letters = item['letters']!;

    return Center(
      child: SizedBox(
        width: 66.r,
        height: 66.r,
        child: _TransparentDialButton(
          number: number,
          letters: letters,
          onTap: () => _addNumber(number),

          // 0 long press করলেও + যোগ হবে
          onLongPress: () {
            if (number == '0') {
              _addNumber('+');
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 14.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28.h,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 420.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Phone number display
                        Container(
                          height: 74.h,
                          margin: EdgeInsets.symmetric(horizontal: 30.w),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.48),
                                const Color(0xFFDDF7FF).withValues(alpha: 0.24),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              width: 1.5,
                              color: const Color(
                                0xFF79DDF5,
                              ).withValues(alpha: 0.75),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.ltr,
                            readOnly: false,
                            showCursor: true,
                            enableInteractiveSelection: true,
                            keyboardType: TextInputType.none,
                            onChanged: (_) => setState(() {}),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9\+\#\-\s\(\)]'),
                              ),
                            ],
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: const Color(0xFF202124),
                            ),
                            decoration: InputDecoration(
                              hintText: '+ Country code number',
                              suffixIcon: IconButton(
                                tooltip: 'Paste number',
                                onPressed: _pasteNumber,
                                icon: Icon(
                                  Icons.content_paste_outlined,
                                  size: 20.sp,
                                  color: const Color(0xFF202124),
                                ),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Dial buttons
                        // Dial buttons — fixed 4 rows
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 42.w),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _dialButton(dialPad[0]),
                                  _dialButton(dialPad[1]),
                                  _dialButton(dialPad[2]),
                                ],
                              ),

                              SizedBox(height: 12.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _dialButton(dialPad[3]),
                                  _dialButton(dialPad[4]),
                                  _dialButton(dialPad[5]),
                                ],
                              ),

                              SizedBox(height: 12.h),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _dialButton(dialPad[6]),
                                  _dialButton(dialPad[7]),
                                  _dialButton(dialPad[8]),
                                ],
                              ),

                              SizedBox(height: 12.h),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _dialButton(dialPad[9]), // +
                                  _dialButton(dialPad[10]), // 0
                                  _dialButton(dialPad[11]), // #
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 18.h),

                        // Clear, Call, Backspace
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 42.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 48.w,
                                child: phoneNumber.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Clear number',
                                        onPressed: _clearNumber,
                                        icon: Icon(
                                          Icons.close,
                                          size: 27.sp,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : const SizedBox(),
                              ),

                              _CallButton(onTap: _startCall),

                              SizedBox(
                                width: 48.w,
                                child: IconButton(
                                  tooltip: 'Delete number',
                                  onPressed: _removeNumber,
                                  onLongPress: _clearNumber,
                                  icon: Icon(
                                    Icons.backspace_outlined,
                                    size: 26.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TransparentDialButton extends StatefulWidget {
  final String number;
  final String letters;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TransparentDialButton({
    required this.number,
    required this.letters,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_TransparentDialButton> createState() => _TransparentDialButtonState();
}

class _TransparentDialButtonState extends State<_TransparentDialButton> {
  bool pressed = false;

  void _release() {
    if (!mounted) {
      return;
    }

    setState(() {
      pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },

      onTapCancel: _release,

      onTapUp: (_) {
        _release();
        widget.onTap();
      },

      onLongPress: widget.onLongPress,

      child: AnimatedScale(
        scale: pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),

          // কোনো blur বা BoxShadow নেই
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: pressed
                  ? [
                      const Color(0xFFBFEFFF).withValues(alpha: 0.38),
                      const Color.fromARGB(
                        255,
                        222,
                        239,
                        245,
                      ).withValues(alpha: 0.25),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.18),
                      const Color(0xFFBFEFFF).withValues(alpha: 0.16),
                    ],
            ),
            border: Border.all(
              width: pressed ? 2.0 : 1.5,
              color: pressed
                  ? const Color(0xFF29C5F6)
                  : const Color(0xFF72DDF4).withValues(alpha: 0.85),
            ),
          ),

          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.number,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF202124),
                  ),
                ),

                if (widget.letters.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    widget.letters,
                    style: TextStyle(
                      fontSize: 9.sp,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CallButton({required this.onTap});

  @override
  State<_CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<_CallButton> {
  bool pressed = false;

  void _release() {
    if (!mounted) {
      return;
    }

    setState(() {
      pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },

      onTapCancel: _release,

      onTapUp: (_) {
        _release();
        widget.onTap();
      },

      child: AnimatedScale(
        scale: pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),

        child: Container(
          width: 60.r,
          height: 60.r,

          // কোনো blur বা shadow নেই
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF27D96F), Color(0xFF079E45)],
            ),
            border: Border.all(
              width: 1.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),

          child: Icon(Icons.call, color: Colors.white, size: 27.sp),
        ),
      ),
    );
  }
}
