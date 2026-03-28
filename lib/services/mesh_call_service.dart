import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';
import '../models/mesh_message.dart';
import 'mesh_service.dart';

class MeshCallService extends ChangeNotifier {
  final MeshService meshService;
  late StreamSubscription _signalingSub;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  String? _currentCallPeerId;
  String? _currentCallPeerName;
  bool _isIncoming = false;
  bool _isActive = false;

  String? get currentCallPeerId => _currentCallPeerId;
  String? get currentCallPeerName => _currentCallPeerName;
  bool get isIncoming => _isIncoming;
  bool get isActive => _isActive;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  MeshCallService(this.meshService) {
    _signalingSub = meshService.signalingStream.listen(_handleSignaling);
  }

  @override
  void dispose() {
    _signalingSub.cancel();
    _endCallLocally();
    super.dispose();
  }

  void _handleSignaling(MeshMessage msg) async {
    if (msg.receiverId != meshService.userId) return; // ignore if not for us

    final payload = jsonDecode(msg.payload);

    switch (msg.type) {
      case 'call_offer':
        if (_isActive || _isIncoming) {
          // Busy, ignore or send busy
          return;
        }
        _isIncoming = true;
        _currentCallPeerId = msg.senderId;
        _currentCallPeerName = meshService.connectedPeers[msg.senderId] ?? 'Unknown';
        notifyListeners();

        await _createPeerConnection();
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );
        break;
      case 'call_answer':
        if (_currentCallPeerId == msg.senderId && _peerConnection != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(payload['sdp'], payload['type']),
          );
        }
        break;
      case 'ice_candidate':
        if (_currentCallPeerId == msg.senderId && _peerConnection != null) {
          await _peerConnection!.addCandidate(
            RTCIceCandidate(
              payload['candidate'],
              payload['sdpMid'],
              payload['sdpMLineIndex'],
            ),
          );
        }
        break;
      case 'call_end':
        if (_currentCallPeerId == msg.senderId) {
          _endCallLocally();
        }
        break;
    }
  }

  Future<void> startCall(String peerId) async {
    _isIncoming = false;
    _isActive = true;
    _currentCallPeerId = peerId;
    _currentCallPeerName = meshService.connectedPeers[peerId] ?? 'Unknown';
    notifyListeners();

    await _createPeerConnection();

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await meshService.sendToEndpoint(
      peerId,
      MeshMessage(
        id: const Uuid().v4(),
        senderId: meshService.userId,
        receiverId: peerId,
        payload: jsonEncode(offer.toMap()),
        timestamp: DateTime.now(),
        type: 'call_offer',
      ),
    );
  }

  Future<void> acceptCall() async {
    _isIncoming = false;
    _isActive = true;
    notifyListeners();

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await meshService.sendToEndpoint(
      _currentCallPeerId!,
      MeshMessage(
        id: const Uuid().v4(),
        senderId: meshService.userId,
        receiverId: _currentCallPeerId!,
        payload: jsonEncode(answer.toMap()),
        timestamp: DateTime.now(),
        type: 'call_answer',
      ),
    );
  }

  Future<void> endCall() async {
    if (_currentCallPeerId != null) {
      await meshService.sendToEndpoint(
        _currentCallPeerId!,
        MeshMessage(
          id: const Uuid().v4(),
          senderId: meshService.userId,
          receiverId: _currentCallPeerId!,
          payload: '{}',
          timestamp: DateTime.now(),
          type: 'call_end',
        ),
      );
    }
    _endCallLocally();
  }

  void _endCallLocally() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    _peerConnection?.close();
    _peerConnection?.dispose();
    _peerConnection = null;

    _currentCallPeerId = null;
    _currentCallPeerName = null;
    _isIncoming = false;
    _isActive = false;
    notifyListeners();
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        // Since it's P2P offline, we don't strictly need STUN/TURN,
        // local network ICE candidates usually suffice over WiFi direct.
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (_currentCallPeerId != null) {
        meshService.sendToEndpoint(
          _currentCallPeerId!,
          MeshMessage(
            id: const Uuid().v4(),
            senderId: meshService.userId,
            receiverId: _currentCallPeerId!,
            payload: jsonEncode(candidate.toMap()),
            timestamp: DateTime.now(),
            type: 'ice_candidate',
          ),
        );
      }
    };

    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      notifyListeners();
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    notifyListeners();
  }
}
