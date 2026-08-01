import 'dart:async';

import 'package:flutter/material.dart';

import '../models/admin_country_pricing_model.dart';
import '../services/admin_country_pricing_service.dart';
import '../widgets/country_pricing_edit_dialog.dart';

class AdminCountryPricingScreen extends StatefulWidget {
  const AdminCountryPricingScreen({super.key});

  @override
  State<AdminCountryPricingScreen> createState() =>
      _AdminCountryPricingScreenState();
}

class _AdminCountryPricingScreenState extends State<AdminCountryPricingScreen> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  bool _loading = true;
  bool _saving = false;

  String? _error;

  List<AdminCountryPricingItem> _items = [];

  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    if (_loading && _items.isNotEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await AdminCountryPricingService.listPricing(
        search: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _items = result.items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), _loadPricing);
  }

  List<AdminCountryPricingItem> get _filteredItems {
    switch (_selectedFilter) {
      case 'auto':
        return _items
            .where((item) => item.pricingMode == CountryPricingMode.autoMarkup)
            .toList();

      case 'manual':
        return _items
            .where((item) => item.pricingMode == CountryPricingMode.manualRate)
            .toList();

      case 'active':
        return _items.where((item) => item.isActive).toList();

      case 'disabled':
        return _items.where((item) => !item.isActive).toList();

      default:
        return _items;
    }
  }

  Future<void> _editPricing(AdminCountryPricingItem item) async {
    final result = await showDialog<CountryPricingEditResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CountryPricingEditDialog(item: item),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await AdminCountryPricingService.updatePricing(
        prefix: item.prefix,
        request: result.request,
      );

      if (!mounted) return;

      _showMessage('${item.countryName} pricing updated successfully.');

      await _loadPricing();
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _disableManualOverride(AdminCountryPricingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Disable Manual Rate?'),
          content: Text(
            '${item.countryName} will return to automatic provider pricing.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Return to Auto'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await AdminCountryPricingService.disableManualOverride(
        prefix: item.prefix,
      );

      if (!mounted) return;

      _showMessage('${item.countryName} returned to automatic pricing.');

      await _loadPricing();
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  String _rate(double value) {
    return '\$${value.toStringAsFixed(7)}';
  }

  String _percent(double value) {
    return '${value.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Country Pricing'),
        actions: [
          IconButton(
            onPressed: _loading || _saving ? null : _loadPricing,
            tooltip: 'Refresh pricing',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadPricing,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 14),
                _buildSearchAndFilter(),
                const SizedBox(height: 14),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _buildErrorCard()
                else if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No country pricing records were found.'),
                    ),
                  )
                else
                  ...List.generate(
                    items.length,
                    (index) => _buildPricingCard(index + 1, items[index]),
                  ),
              ],
            ),
          ),

          if (_saving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.price_change, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Country Retail Pricing',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Choose Auto Markup for dynamic provider-cost pricing, or set a fixed Manual Rate for a country prefix.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: 'Search country or prefix',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _loadPricing();
                    },
                    icon: const Icon(Icons.clear),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedFilter,
          decoration: const InputDecoration(
            labelText: 'Filter',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Pricing')),
            DropdownMenuItem(value: 'auto', child: Text('Auto Markup')),
            DropdownMenuItem(value: 'manual', child: Text('Manual Rate')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedFilter = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_error!, style: TextStyle(color: Colors.red.shade900)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadPricing,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(int number, AdminCountryPricingItem item) {
    final manual = item.pricingMode == CountryPricingMode.manualRate;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Text('$number')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.countryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${item.countryCode} • ${item.normalizedPrefix}'),
                    ],
                  ),
                ),
                _statusChip(item.isActive),
              ],
            ),

            const Divider(height: 28),

            _row(
              'Provider',
              item.providerName.isNotEmpty
                  ? item.providerName
                  : item.providerCode.toUpperCase(),
            ),
            _row(
              'Provider Plan',
              item.providerPlanCode.isNotEmpty
                  ? item.providerPlanCode.toUpperCase()
                  : '-',
            ),
            _row('Provider Cost / Min', _rate(item.providerCostUsdPerMin)),
            _row('Pricing Mode', item.pricingMode.displayName),
            _row('Markup', _percent(item.effectiveMarkupPercent)),
            _row('Final Sell Rate / Min', _rate(item.finalSellRateUsdPerMin)),
            _row('Profit / Min', _rate(item.profitUsdPerMin)),
            _row('Profit Margin', _percent(item.profitMarginPercent)),
            _row('Provider Destinations', '${item.destinationRateCount}'),

            if (item.note != null && item.note!.trim().isNotEmpty)
              _row('Admin Note', item.note!),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : () => _editPricing(item),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Pricing'),
                  ),
                ),

                if (manual) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _disableManualOverride(item),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Use Auto'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(bool active) {
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.cancel,
        size: 18,
        color: active ? Colors.green : Colors.red,
      ),
      label: Text(active ? 'Active' : 'Disabled'),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
