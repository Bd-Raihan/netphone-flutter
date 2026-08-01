import 'package:flutter/material.dart';

import '../models/admin_country_pricing_model.dart';

class CountryPricingEditResult {
  final CountryPricingUpdateRequest request;

  const CountryPricingEditResult({required this.request});
}

class CountryPricingEditDialog extends StatefulWidget {
  final AdminCountryPricingItem item;

  const CountryPricingEditDialog({super.key, required this.item});

  @override
  State<CountryPricingEditDialog> createState() =>
      _CountryPricingEditDialogState();
}

class _CountryPricingEditDialogState extends State<CountryPricingEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late CountryPricingMode _selectedMode;

  late TextEditingController _markupController;
  late TextEditingController _manualRateController;
  late TextEditingController _noteController;

  late bool _isActive;

  @override
  void initState() {
    super.initState();

    _selectedMode = widget.item.pricingMode;
    _isActive = widget.item.isActive;

    _markupController = TextEditingController(
      text: widget.item.effectiveMarkupPercent.toStringAsFixed(2),
    );

    final initialManualRate =
        widget.item.manualSellRateUsdPerMin ??
        widget.item.finalSellRateUsdPerMin;

    _manualRateController = TextEditingController(
      text: initialManualRate > 0 ? initialManualRate.toStringAsFixed(7) : '',
    );

    _noteController = TextEditingController(text: widget.item.note ?? '');

    _markupController.addListener(_refreshPreview);
    _manualRateController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _markupController.removeListener(_refreshPreview);
    _manualRateController.removeListener(_refreshPreview);

    _markupController.dispose();
    _manualRateController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  double get _providerCost => widget.item.providerCostUsdPerMin;

  double get _markupPercent =>
      double.tryParse(_markupController.text.trim()) ?? 0;

  double get _manualRate =>
      double.tryParse(_manualRateController.text.trim()) ?? 0;

  double get _previewFinalRate {
    if (_selectedMode == CountryPricingMode.manualRate) {
      return _manualRate;
    }

    final rate = _providerCost * (1 + (_markupPercent / 100));

    final minimumRate = _providerCost + widget.item.minProfitUsdPerMin;

    return rate > minimumRate ? rate : minimumRate;
  }

  double get _previewProfit {
    return _previewFinalRate - _providerCost;
  }

  double get _previewMarkup {
    if (_providerCost <= 0 || _previewFinalRate <= 0) {
      return 0;
    }

    return ((_previewFinalRate - _providerCost) / _providerCost) * 100;
  }

  double get _previewMargin {
    if (_previewFinalRate <= 0) {
      return 0;
    }

    return ((_previewFinalRate - _providerCost) / _previewFinalRate) * 100;
  }

  String _money(double value) {
    return '\$${value.toStringAsFixed(7)}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final note = _noteController.text.trim();

    final CountryPricingUpdateRequest request;

    if (_selectedMode == CountryPricingMode.autoMarkup) {
      request = CountryPricingUpdateRequest.autoMarkup(
        markupPercent: _markupPercent,
        countryCode: widget.item.countryCode,
        isActive: _isActive,
        note: note,
      );
    } else {
      request = CountryPricingUpdateRequest.manualRate(
        manualSellRateUsdPerMin: _manualRate,
        countryCode: widget.item.countryCode,
        isActive: _isActive,
        note: note,
      );
    }

    Navigator.pop(context, CountryPricingEditResult(request: request));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.item.countryName} Pricing'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _infoRow('Country', widget.item.countryName),
                _infoRow('Prefix', widget.item.normalizedPrefix),
                _infoRow(
                  'Provider',
                  widget.item.providerName.isNotEmpty
                      ? widget.item.providerName
                      : widget.item.providerCode.toUpperCase(),
                ),
                _infoRow('Provider Cost / Min', _money(_providerCost)),

                const SizedBox(height: 18),

                DropdownButtonFormField<CountryPricingMode>(
                  value: _selectedMode,
                  decoration: const InputDecoration(
                    labelText: 'Pricing Mode',
                    border: OutlineInputBorder(),
                  ),
                  items: CountryPricingMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedMode = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                if (_selectedMode == CountryPricingMode.autoMarkup)
                  TextFormField(
                    controller: _markupController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Markup %',
                      hintText: 'Example: 90',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');

                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid non-negative markup';
                      }

                      if (parsed > 1000) {
                        return 'Markup cannot exceed 1000%';
                      }

                      return null;
                    },
                  ),

                if (_selectedMode == CountryPricingMode.manualRate)
                  TextFormField(
                    controller: _manualRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Manual Sell Rate USD / Min',
                      hintText: 'Example: 0.0251300',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');

                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid positive rate';
                      }

                      if (parsed <= _providerCost) {
                        return 'Manual rate must be greater than provider cost';
                      }

                      return null;
                    },
                  ),

                const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Pricing'),
                  subtitle: Text(
                    _isActive
                        ? 'New calls can use this pricing'
                        : 'This pricing will be disabled',
                  ),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Admin Note',
                    hintText: 'Optional reason or pricing note',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Pricing Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(height: 22),
                      _infoRow('Provider Cost', _money(_providerCost)),
                      _infoRow('Final Sell Rate', _money(_previewFinalRate)),
                      _infoRow('Profit / Min', _money(_previewProfit)),
                      _infoRow(
                        'Effective Markup',
                        '${_previewMarkup.toStringAsFixed(2)}%',
                      ),
                      _infoRow(
                        'Profit Margin',
                        '${_previewMargin.toStringAsFixed(2)}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save),
          label: const Text('Save Pricing'),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
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
