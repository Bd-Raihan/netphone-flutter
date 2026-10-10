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

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

          final query = _searchQuery.trim().toLowerCase();

          final filteredRates = rates.where((rate) {
            if (query.isEmpty) {
              return true;
            }

            final countryName = rate.countryName.toLowerCase();

            final countryCode = rate.countryCode.toLowerCase();

            final prefix = rate.prefix.toLowerCase();

            final normalizedQuery = query.replaceAll('+', '');

            return countryName.contains(query) ||
                countryCode.contains(query) ||
                prefix.contains(normalizedQuery);
          }).toList();

          return RefreshIndicator(
            onRefresh: refreshRates,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                /// =========================================
                /// Search Box
                /// =========================================
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search country, code or prefix',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();

                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFE8EEF7),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                /// =========================================
                /// Search Result Count
                /// =========================================
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      '${filteredRates.length} result(s)',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                /// =========================================
                /// Empty Search Result
                /// =========================================
                if (filteredRates.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 60.h),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 50.sp,
                          color: Colors.black38,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No country found',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredRates.map((rate) => _RateCard(rate: rate)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RateCard extends StatefulWidget {
  final RateModel rate;

  const _RateCard({required this.rate});

  @override
  State<_RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<_RateCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.rate;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          pressed = true;
        });
      },
      onTapCancel: () {
        setState(() {
          pressed = false;
        });
      },
      onTapUp: (_) {
        setState(() {
          pressed = false;
        });
      },
      child: AnimatedScale(
        scale: pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFD6DCE6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            children: [
              /// =================================
              /// Country Code
              /// =================================
              Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F6BDE),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text(
                    r.countryCode,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 14.w),

              /// =================================
              /// Country + Prefix
              /// =================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.countryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF171717),
                      ),
                    ),

                    SizedBox(height: 5.h),

                    Text(
                      'Prefix: +${r.prefix}',
                      style: TextStyle(fontSize: 13.sp, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 10.w),

              /// =================================
              /// Per-Minute Rate
              /// =================================
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE8FF),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '\$${r.sellRateUsdPerMin.toStringAsFixed(3)}/min',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF174FAF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
