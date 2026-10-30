
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_contact_dialog.dart';
import '../models/emergency_contact.dart';
import '../services/firestore_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _service = FirestoreService();

  bool _isAddingContact = false;
  final Set<String> _deletingContacts = {};

  Future<void> _addContact() async {
    if (_isAddingContact) return;

    setState(() {
      _isAddingContact = true;
    });

    try {
      final contact = await showDialog<EmergencyContact>(
        context: context,
        builder: (_) => const AddContactDialog(),
      );

      if (!mounted || contact == null) return;

      await _service.addContact(contact);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact saved.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save contact: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingContact = false;
        });
      }
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);

    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the phone dialler on this device.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final id = contact.id;

    if (id == null || _deletingContacts.contains(id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text(
          'Are you sure you want to delete ${contact.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _deletingContacts.add(id);
    });

    try {
      // Delete from Firestore.
      // watchContacts() automatically updates the UI.
      await _service.deleteContact(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contact.name} deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete contact: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingContacts.remove(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Contacts')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Connect Firebase and sign in to save contacts. Contact management uses your private Firestore account.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add contact'),
      ),
      body: StreamBuilder<List<EmergencyContact>>(
        stream: _service.watchContacts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load contacts: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final contacts = snapshot.data!;

          if (contacts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 54,
                      color: Color(0xFF087F6E),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No contacts yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Add a trusted person who can help in an emergency.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final id = contact.id;
              final isDeleting =
                  id != null && _deletingContacts.contains(id);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFDDF7EF),
                    child: Text(
                      contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFF087F6E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    contact.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${contact.relationship} • ${contact.phone}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Call contact',
                        onPressed: () => _call(contact.phone),
                        icon: const Icon(
                          Icons.call_rounded,
                          color: Color(0xFF087F6E),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete contact',
                        onPressed: isDeleting
                            ? null
                            : () => _deleteContact(contact),
                        icon: isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
