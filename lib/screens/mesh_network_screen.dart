import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/mesh_service.dart';
import '../theme/app_theme.dart';
import 'mesh_chat_screen.dart';

class MeshNetworkScreen extends StatefulWidget {
  const MeshNetworkScreen({super.key});

  @override
  State<MeshNetworkScreen> createState() => _MeshNetworkScreenState();
}

class _MeshNetworkScreenState extends State<MeshNetworkScreen> {
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startMesh();
  }

  Future<void> _startMesh() async {
    // Request all permissions needed for Nearby Connections (BLE + WiFi Direct)
    final statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
      Permission.microphone,
    ].request();

    debugPrint('[Mesh] Permission statuses: $statuses');

    // Check location service is on (required by Nearby Connections on Android)
    if (!await Permission.location.serviceStatus.isEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on Location to use Mesh Networking!'),
            backgroundColor: AppTheme.dangerRed,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isScanning = true);
    final mesh = context.read<MeshService>();
    await mesh.init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshService>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Offline Mesh', 
            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: Icon(
              mesh.isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
              color: mesh.isAdmin ? AppTheme.accentBlue : AppTheme.textMuted,
            ),
            onPressed: () {
              mesh.toggleAdmin();
            },
          ),
          IconButton(
            icon: Icon(
              _isScanning ? Icons.sensors_rounded : Icons.sensors_off_rounded,
              color: _isScanning ? AppTheme.safeGreen : AppTheme.dangerRed,
            ),
            onPressed: () async {
              if (_isScanning) {
                await mesh.stopAll();
                setState(() => _isScanning = false);
              } else {
                await _startMesh();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(mesh),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MeshChatScreen(
                peerId: 'broadcast',
                peerName: 'Group Broadcast',
              ),
            ),
          );
        },
        backgroundColor: AppTheme.primaryPurple,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody(MeshService mesh) {
    if (mesh.nearbyEndpoints.isEmpty && mesh.connectedPeers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                _isScanning ? Icons.bluetooth_searching_rounded : Icons.sensors_off_rounded, 
                size: 48, 
                color: _isScanning ? AppTheme.primaryPurple : AppTheme.textMuted
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isScanning ? 'Searching for nearby devices...' : 'Mesh networking is inactive.',
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isScanning ? 'Sharing secure safety packets' : 'Enable scanning to join network',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final allPeersId = {...mesh.nearbyEndpoints.keys, ...mesh.connectedPeers.keys}.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: allPeersId.length,
      itemBuilder: (context, index) {
        final id = allPeersId[index];
        final name = mesh.connectedPeers[id] ?? mesh.nearbyEndpoints[id] ?? 'Secure Node';
        final isConnected = mesh.connectedPeers.containsKey(id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isConnected 
                ? AppTheme.safeGreen.withValues(alpha: 0.2) 
                : Colors.black.withValues(alpha: 0.05)
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Icon(Icons.person_rounded, 
                      color: isConnected ? AppTheme.primaryPurple : Color(0xFF94A3B8)),
                ),
                if (isConnected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.safeGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(name, 
                style: const TextStyle(
                  color: Color(0xFF1E293B), 
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                )),
            subtitle: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isConnected ? AppTheme.safeGreen : Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(isConnected ? 'Connected' : 'Available', 
                    style: TextStyle(
                      color: isConnected ? AppTheme.safeGreen : AppTheme.textMuted, 
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    )),
              ],
            ),
            trailing: isConnected 
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, 
                      color: AppTheme.primaryPurple, size: 20),
                ) 
              : Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            onTap: () {
              if (isConnected) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) {
                      // Use peer's userId from handshake, fallback to endpointId
                      final peerUserId = mesh.endpointToUserId[id] ?? id;
                      return MeshChatScreen(peerId: peerUserId, peerName: name);
                    },
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Waiting for connection...'),
                    backgroundColor: AppTheme.darkCard,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
