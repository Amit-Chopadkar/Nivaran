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
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentBlue.withValues(alpha: 0.1), AppTheme.darkCard],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.accentBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'These contacts will be alerted during emergencies and can track your location.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contacts list
            ...service.emergencyContacts.map((contact) => _buildContactCard(contact, service)),
            const SizedBox(height: 20),

            // Add contact button
            GestureDetector(
              onTap: () => _showAddContactSheet(context, service),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryPurple, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Add Trusted Contact',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Location sharing section
            Text('Location Sharing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _LocationOption(
              title: 'Continuous Tracking',
              subtitle: 'Always share location with primary contact',
              isEnabled: true,
              color: AppTheme.safeGreen,
            ),
            _LocationOption(
              title: 'SOS Auto-Share',
              subtitle: 'Share with all contacts during emergencies',
              isEnabled: true,
              color: AppTheme.dangerRed,
            ),
            _LocationOption(
              title: 'Trip Sharing',
              subtitle: 'Share during active trip sessions',
              isEnabled: true,
              color: AppTheme.accentBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, SafetyService service) {
    return PremiumContactCard(
      name: contact.name,
      subtitle: '${contact.phone} • ${contact.relationship}',
      isPrimary: contact.isPrimary,
      fallbackIcon: contact.isPrimary ? Icons.star_rounded : Icons.person_rounded,
      onCallTap: () {
        // Implement call logic here
      },
      onDeleteTap: () => service.removeEmergencyContact(contact.id),
    );
  }

  void _showAddContactSheet(BuildContext context, SafetyService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Add Trusted Contact', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            
            // Name input
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _nameController,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  prefixIcon: Icon(Icons.person_rounded, color: AppTheme.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Phone input
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _phoneController,
                style: TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Relationship
            Wrap(
              spacing: 8,
              children: ['Family', 'Friend', 'Partner', 'Colleague'].map((rel) {
                final isSelected = rel == _selectedRelationship;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRelationship = rel),
                  child: Chip(
                    label: Text(rel),
                    backgroundColor: isSelected ? AppTheme.primaryPurple.withValues(alpha: 0.2) : AppTheme.darkCard,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryPurple : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isEnabled;
  final Color color;

  const _LocationOption({
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (v) {},
            activeTrackColor: color,
          ),
        ],
      ),
    );
  }
}
