import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/safety_service.dart';
import '../models/safety_models.dart';
import '../widgets/premium_contact_card.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRelationship = 'Family';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SafetyService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Trusted Contacts', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simplified Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F7FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppTheme.primaryPurple, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Trusted contacts are alerted during emergencies and can view your live location.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Circle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                TextButton.icon(
                  onPressed: () => _showAddContactSheet(context, service),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryPurple,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contacts list
            if (service.emergencyContacts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No contacts added yet', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              )
            else
              ...service.emergencyContacts.map((contact) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumContactCard(
                  name: contact.name,
                  subtitle: '${contact.phone} • ${contact.relationship}',
                  isPrimary: contact.isPrimary,
                  fallbackIcon: contact.isPrimary ? Icons.star_rounded : Icons.person_rounded,
                  onCallTap: () {},
                  onDeleteTap: () => service.removeEmergencyContact(contact.id),
                ),
              )),
            
            const SizedBox(height: 32),

            // ── Simplified Location Sharing Section ──
            Text(
              'Location Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage how your location is shared.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // ── Toggles ──
            _SimpleToggle(
              title: 'Continuous Tracking',
              subtitle: 'Send primary contact updates every 10 min',
              isEnabled: service.continuousTrackingEnabled,
              hasContacts: service.emergencyContacts.isNotEmpty,
              onChanged: (v) => service.toggleContinuousTracking(v),
            ),
            _SimpleToggle(
              title: 'SOS Auto-Share',
              subtitle: 'Share location with everyone when SOS is triggered',
              isEnabled: service.sosAutoShareEnabled,
              hasContacts: service.emergencyContacts.isNotEmpty,
              onChanged: (v) => service.toggleSOSAutoShare(v),
            ),
            _SimpleToggle(
              title: 'Trip Sharing',
              subtitle: 'Automatically notify circle when starting a trip',
              isEnabled: service.tripSharingEnabled,
              hasContacts: service.emergencyContacts.isNotEmpty,
              onChanged: (v) => service.toggleTripSharing(v),
            ),

            const SizedBox(height: 32),

            // ── Integrated Share Button ──
            if (service.emergencyContacts.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await service.sendLocationLinkToAll(label: '📍 My current location');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Location shared with all contacts'),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Share Live Location Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showAddContactSheet(BuildContext context, SafetyService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Contact',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 24),

            // Simple inputs
            _buildField('Full Name', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildField('Phone Number', _phoneController, Icons.phone_android_outlined, type: TextInputType.phone),
            const SizedBox(height: 24),

            Text('Relationship', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['Family', 'Friend', 'Partner', 'Work'].map((rel) {
                final isSelected = rel == _selectedRelationship;
                return ChoiceChip(
                  label: Text(rel),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedRelationship = rel);
                  },
                  selectedColor: AppTheme.primaryPurple.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryPurple : Colors.black54,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(color: isSelected ? AppTheme.primaryPurple : Colors.grey[300]!),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                    service.addEmergencyContact(EmergencyContact(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      phone: _phoneController.text,
                      relationship: _selectedRelationship,
                    ));
                    _nameController.clear();
                    _phoneController.clear();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Contact',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
        labelStyle: TextStyle(color: Colors.grey[600]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryPurple),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}

class _SimpleToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isEnabled;
  final bool hasContacts;
  final ValueChanged<bool> onChanged;

  const _SimpleToggle({
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    required this.hasContacts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: hasContacts ? Colors.black87 : Colors.grey[400],
          ),
        ),
        subtitle: Text(
          hasContacts ? subtitle : 'Add a contact to enable',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        value: isEnabled && hasContacts,
        onChanged: hasContacts ? onChanged : null,
        activeColor: AppTheme.primaryPurple,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
