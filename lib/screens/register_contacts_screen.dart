import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class RegisterContactsScreen extends StatefulWidget {
  const RegisterContactsScreen({super.key});

  @override
  State<RegisterContactsScreen> createState() => _RegisterContactsScreenState();
}

class _RegisterContactsScreenState extends State<RegisterContactsScreen> {
  final List<Map<String, String>> _contacts = [];
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  bool _isSaving = false;

  void _addContact() {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      setState(() {
        _contacts.add({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'relation': _relationController.text,
        });
        _nameController.clear();
        _phoneController.clear();
        _relationController.clear();
      });
    }
  }

  Future<void> _completeSignup() async {
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one trusted contact')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = context.read<UserService>().profile;

    if (user != null) {
      int saved = 0;
      int failed = 0;
      for (var contact in _contacts) {
        final error = await SupabaseService.syncContact(
          userEmail: user.email,
          name: contact['name']!,
          phone: contact['phone']!,
          relation: contact['relation']!,
        );
        if (error == null) {
          saved++;
        } else {
          failed++;
        }
      }

      if (failed > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$saved contacts saved. $failed failed to sync to cloud.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User session not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1A), Color(0xFF1A0A2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Trusted Contacts',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Who should be notified in an emergency?',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 30),
                
                // Add Contact Form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _buildMiniField('Name', _nameController, Icons.person),
                      const SizedBox(height: 12),
                      _buildMiniField('Phone', _phoneController, Icons.phone),
                      const SizedBox(height: 12),
                      _buildMiniField('Relation', _relationController, Icons.family_restroom),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addContact,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Contact'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryPurple,
                            side: BorderSide(color: AppTheme.primaryPurple),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                Text('Added Contacts (${_contacts.length})', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final c = _contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
                          child: Text(c['name']![0], style: TextStyle(color: AppTheme.primaryPurple)),
                        ),
                        title: Text(c['name']!, style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${c['relation']} • ${c['phone']}', style: TextStyle(color: AppTheme.textMuted)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => setState(() => _contacts.removeAt(index)),
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _completeSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Complete Sign Up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
