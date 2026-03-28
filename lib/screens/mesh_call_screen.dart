import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_call_service.dart';
import '../theme/app_theme.dart';

class MeshCallScreen extends StatelessWidget {
  const MeshCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final callService = context.watch<MeshCallService>();

    if (callService.currentCallPeerId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Call ended", style: TextStyle(color: Colors.white))));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
              child: const Icon(Icons.person, size: 60, color: AppTheme.primaryPurple),
            ),
            const SizedBox(height: 24),
            Text(
              callService.currentCallPeerName ?? 'Unknown User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              callService.isIncoming
                  ? 'Incoming Call...'
                  : (callService.isActive ? 'In Mesh Call' : 'Calling...'),
              style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (callService.isIncoming)
                  _buildCallButton(
                    icon: Icons.call,
                    color: AppTheme.safeGreen,
                    onPressed: () => callService.acceptCall(),
                  ),
                _buildCallButton(
                  icon: Icons.call_end,
                  color: AppTheme.dangerRed,
                  onPressed: () => callService.endCall(),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
