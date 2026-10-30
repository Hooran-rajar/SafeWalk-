
import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({super.key});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add emergency contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Contact name',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Enter a name.'
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _relationController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Enter relationship.'
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                ),
                validator: (value) =>
                    value == null || value.trim().length < 5
                        ? 'Enter a valid number.'
                        : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }

            final contact = EmergencyContact(
              name: _nameController.text.trim(),
              relationship: _relationController.text.trim(),
              phone: _phoneController.text.trim(),
            );

            Navigator.of(context).pop<EmergencyContact>(contact);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
