import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FaxHelpPanel extends StatelessWidget {
  const FaxHelpPanel({super.key});

  Widget _section(BuildContext context, IconData icon, String title, List<String> steps) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 12),
        for (var i = 0; i < steps.length; i++)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('${i + 1}. ${steps[i]}', style: const TextStyle(height: 1.5))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Card(child: ExpansionTile(
    leading: const Icon(Icons.help_outline),
    title: const Text('How to Send & Receive Fax'),
    subtitle: const Text('Quick guide'),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    children: [
      _section(context, Icons.send_outlined, 'Send Fax', const [
        'Choose a PDF, JPG or PNG in Send Fax.',
        'Enter the destination fax number with country code, then tap Send.',
        'Check Fax History for Successful or Failed. Refresh before retrying to avoid sending twice.',
      ]),
      _section(context, Icons.move_to_inbox_outlined, 'Receive Fax', const [
        'Download a NEW cover in Receive Fax. Enter your name in English and share the PDF with your sender.',
        'Ask them to put your QR cover FIRST, followed by the document, and send ONE fax to the number on the cover. If their service adds a cover, keep your QR within the first 3 pages.',
        'A valid cover routes the fax automatically to Fax History. Open it there to view or download the PDF.',
      ]),
      const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text(
        'Keep enough wallet balance: fax fees are deducted automatically. Unused Send prepayment is returned.\n\nUse each cover once, within 30 days. Keep its QR clear and share it only with your sender. Invalid covers need support; unpaid faxes stay locked.\n\nCover pages count toward fax charges. Received documents may be black and white.',
        style: TextStyle(height: 1.5),
      )),
      const Divider(),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.support_agent),
        title: Text('Need help?', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Email our support team.'),
      ),
      const SelectableText('info@netphoneapp.com', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      TextButton.icon(icon: const Icon(Icons.copy), label: const Text('Copy support email'), onPressed: () async {
        await Clipboard.setData(const ClipboardData(text: 'info@netphoneapp.com'));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support email copied.')));
      }),
      const Text('Include your Receive ID, sender number and fax date/time with timezone. Never share your OTP or password.', style: TextStyle(height: 1.5)),
    ],
  ));
}
