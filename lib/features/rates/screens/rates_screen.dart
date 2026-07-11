import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/rate_model.dart';
import '../services/rates_service.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  late Future<List<RateModel>> ratesFuture;

  @override
  void initState() {
    super.initState();
    ratesFuture = RatesService.getRates();
  }

  Future<void> refreshRates() async {
    setState(() {
      ratesFuture = RatesService.getRates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "International Rates",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(onPressed: refreshRates, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<RateModel>>(
        future: ratesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final rates = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: refreshRates,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: rates.length,
              itemBuilder: (context, index) {
                final r = rates[index];
                return _RateGlassCard(rate: r);
              },
            ),
          );
        },
      ),
    );
  }
}

class _RateGlassCard extends StatefulWidget {
  final RateModel rate;

  const _RateGlassCard({required this.rate});

  @override
  State<_RateGlassCard> createState() => _RateGlassCardState();
}

class _RateGlassCardState extends State<_RateGlassCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.rate;

    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapCancel: () => setState(() => pressed = false),
      onTapUp: (_) => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              margin: EdgeInsets.only(bottom: 14.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(26.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 62.w,
                    height: 62.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromARGB(255, 162, 223, 247),
                          Color(0xFF74E5FF),
                        ],
                      ),
                      border: Border.all(
                        color: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ).withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.25),
                          blurRadius: 14.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        r.countryCode,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.countryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF151515),
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          "Prefix: +${r.prefix}",
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "\$${r.sellRateUsdPerMin.toStringAsFixed(3)}/min",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF25A94F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
