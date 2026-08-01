import 'package:flutter/material.dart';

import '../../admin_country_pricing/screens/admin_country_pricing_screen.dart';
import '../../admin_rate_import/screens/admin_rate_import_screen.dart';

class AdminRateManagementScreen extends StatelessWidget {
  const AdminRateManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _managementCard(
            context: context,
            icon: Icons.cloud_upload,
            title: 'Provider Rate Import',
            description:
                'Validate and import Telnyx or other provider CSV rate decks.',
            buttonText: 'Open Rate Import',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminRateImportScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          _managementCard(
            context: context,
            icon: Icons.price_change,
            title: 'Country Retail Pricing',
            description:
                'Configure country-wise Auto Markup or fixed Manual Sell Rate.',
            buttonText: 'Open Country Pricing',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminCountryPricingScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _managementCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 25, child: Icon(icon)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(description),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
