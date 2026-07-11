/// =======================================================
/// contacts_screen.dart
/// কাজ:
/// - Mobile Contacts Read
/// - Search Contact
/// - Contact Number Show
/// - Call Navigation
/// =======================================================

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'contact_details_screen.dart';
import '../../call/utils/phone_validator.dart';

///import 'package:share_plus/share_plus.dart';
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  /// =========================
  /// Contact Lists
  /// =========================
  List<Contact> contacts = [];

  List<Contact> filteredContacts = [];

  bool isLoading = true;

  /// =========================
  /// Init
  /// =========================
  @override
  void initState() {
    super.initState();

    loadContacts();
  }

  /// =========================
  /// Load Contacts
  /// =========================
  Future<void> loadContacts() async {
    /// Permission Request
    final permission = await FlutterContacts.requestPermission(readonly: true);

    if (permission) {
      final contactList = await FlutterContacts.getContacts(
        withProperties: true,
      );

      setState(() {
        contacts = contactList;

        filteredContacts = contactList;

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// =========================
  /// Search Contact
  /// =========================
  void searchContact(String value) {
    final results = contacts.where((contact) {
      return contact.displayName.toLowerCase().contains(value.toLowerCase());
    }).toList();

    setState(() {
      filteredContacts = results;
    });
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 60, 255),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// =========================
                /// Search Box
                /// =========================
                Padding(
                  padding: EdgeInsets.all(16.w),

                  child: TextField(
                    onChanged: searchContact,

                    decoration: InputDecoration(
                      hintText: "Search Contact",

                      prefixIcon: const Icon(Icons.search),

                      filled: true,
                      hintStyle: TextStyle(color: Colors.white70),
                      // ignore: deprecated_member_use
                      fillColor: Colors.white.withOpacity(0.15),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                /// =========================
                /// Contact List
                /// =========================
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredContacts.length,

                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];

                      /// Contact Number
                      final phone = contact.phones.isNotEmpty
                          ? contact.phones.first.number
                          : "No Number";

                      final cleanedPhone = normalizePhoneNumber(phone);

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24.r,
                          backgroundColor: Colors.lightBlue.shade100,
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName[0]
                                : "?",

                            style: TextStyle(
                              fontSize: 18.sp,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),

                        title: Text(
                          contact.displayName,

                          style: TextStyle(fontSize: 16.sp),
                        ),

                        subtitle: Text(
                          phone,

                          style: TextStyle(fontSize: 13.sp),
                        ),

                        onTap: () {
                          if (contact.phones.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No phone number found'),
                              ),
                            );
                            return;
                          }

                          final phoneNumbers = contact.phones
                              .map(
                                (phone) => normalizePhoneNumber(phone.number),
                              )
                              .where((number) => number.trim().isNotEmpty)
                              .toSet()
                              .toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContactDetailsScreen(
                                contactName: contact.displayName,
                                phoneNumbers: phoneNumbers,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
