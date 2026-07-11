import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../call/screens/calling_screen.dart';
import '../../call/utils/phone_validator.dart';

class ContactDetailsScreen extends StatefulWidget {
  final String contactName;
  final List<String> phoneNumbers;

  const ContactDetailsScreen({
    super.key,
    required this.contactName,
    required this.phoneNumbers,
  });

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  String? _selectedPhone;
  bool _isCallButtonPressed = false;

  @override
  void initState() {
    super.initState();

    if (widget.phoneNumbers.isNotEmpty) {
      _selectedPhone = widget.phoneNumbers.first;
    }
  }

  String get _displayName {
    final name = widget.contactName.trim();

    if (name.isEmpty) {
      return 'Unknown Contact';
    }

    return name;
  }

  String get _contactInitial {
    final name = widget.contactName.trim();

    if (name.isEmpty) {
      return '?';
    }

    return name.characters.first.toUpperCase();
  }

  void _startCall() {
    final selectedPhone = _selectedPhone;

    if (selectedPhone == null || selectedPhone.trim().isEmpty) {
      _showMessage('Please select a phone number');
      return;
    }

    final cleanedPhone = normalizePhoneNumber(selectedPhone);

    if (!isValidPhoneNumber(cleanedPhone)) {
      _showMessage('Invalid country code or phone number');
      return;
    }

    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CallingScreen(phoneNumber: cleanedPhone, contactName: _displayName),
      ),
    );
  }

  Future<void> _copyPhoneNumber(String number) async {
    await Clipboard.setData(ClipboardData(text: number));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Contact Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22.w, 30.h, 22.w, 40.h),
          child: Column(
            children: [
              Container(
                width: 112.r,
                height: 112.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4C7DFF), Color(0xFF1145F5)],
                  ),
                  border: Border.all(width: 4, color: Colors.white),
                ),
                child: Center(
                  child: Text(
                    _contactInitial,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 22.h),

              Text(
                _displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF161B22),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 26.h),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select phone number',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),

              SizedBox(height: 12.h),

              if (widget.phoneNumbers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: const Color(0xFFE1E7EF)),
                  ),
                  child: const Text(
                    'No phone number found',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...widget.phoneNumbers.map(
                  (number) => _PhoneNumberCard(
                    phoneNumber: number,
                    isSelected: _selectedPhone == number,
                    onTap: () {
                      setState(() {
                        _selectedPhone = number;
                      });
                    },
                    onLongPress: () {
                      _copyPhoneNumber(number);
                    },
                  ),
                ),

              SizedBox(height: 26.h),

              GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _isCallButtonPressed = true;
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _isCallButtonPressed = false;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _isCallButtonPressed = false;
                  });

                  _startCall();
                },
                child: AnimatedScale(
                  scale: _isCallButtonPressed ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 110),
                  curve: Curves.easeOut,
                  child: Container(
                    width: 76.r,
                    height: 76.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF31D875), Color(0xFF079B45)],
                      ),
                      border: Border.all(width: 3, color: Colors.white),
                    ),
                    child: Icon(
                      Icons.call_rounded,
                      color: Colors.white,
                      size: 36.sp,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              Text(
                'Call selected number',
                style: TextStyle(
                  color: const Color(0xFF168B4B),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneNumberCard extends StatelessWidget {
  final String phoneNumber;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhoneNumberCard({
    required this.phoneNumber,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          width: isSelected ? 2 : 1,
          color: isSelected ? const Color(0xFF1145F5) : const Color(0xFFE1E7EF),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
            child: Row(
              children: [
                Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1145F5).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: const Color(0xFF1145F5),
                    size: 22.sp,
                  ),
                ),

                SizedBox(width: 14.w),

                Expanded(
                  child: Text(
                    phoneNumber,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),

                Radio<String>(
                  value: phoneNumber,
                  groupValue: isSelected ? phoneNumber : null,
                  onChanged: (_) {
                    onTap();
                  },
                  activeColor: const Color(0xFF1145F5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
