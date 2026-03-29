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
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  String? _currentCallEndpointId;
  String? _currentCallUserId;
  String? _currentCallPeerName;
  bool _isIncoming = false;
  bool _isActive = false;

  final List<RTCIceCandidate> _remoteCandidatesQueue = [];
  bool _isRemoteDescriptionSet = false;

  String? get currentCallEndpointId => _currentCallEndpointId;
  String? get currentCallUserId => _currentCallUserId;
  String? get currentCallPeerName => _currentCallPeerName;
  bool get isIncoming => _isIncoming;
  bool get isActive => _isActive;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  MeshCallService(this.meshService) {
    _signalingSub = meshService.signalingStream.listen(_handleSignaling);
    _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _signalingSub.cancel();
    _endCallLocally();
    super.dispose();
  }

  void _handleSignaling(MeshMessage msg) async {
    if (msg.receiverId != meshService.userId) return; // ignore if not for us

    final payload = jsonDecode(msg.payload);
    final senderUserId = msg.senderId;
    final senderEndpointId = meshService.userIdToEndpoint[senderUserId];
    
    if (senderEndpointId == null) return;

    switch (msg.type) {
      case 'call_offer':
        if (_isActive || _isIncoming) {
          // Busy, ignore or send busy
          return;
        }
        _isIncoming = true;
        _currentCallEndpointId = senderEndpointId;
        _currentCallUserId = senderUserId;
        _currentCallPeerName = meshService.connectedPeers[senderEndpointId] ?? 'Unknown';
        _remoteCandidatesQueue.clear();
        _isRemoteDescriptionSet = false;
        notifyListeners();

        await _createPeerConnection();
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );
        _isRemoteDescriptionSet = true;
        _drainRemoteCandidates();
        break;
      case 'call_answer':
        if (_currentCallUserId == senderUserId && _peerConnection != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(payload['sdp'], payload['type']),
          );
          _isRemoteDescriptionSet = true;
          _drainRemoteCandidates();
        }
        break;
      case 'ice_candidate':
        if (_currentCallUserId == senderUserId && _peerConnection != null) {
          final candidate = RTCIceCandidate(
            payload['candidate'],
            payload['sdpMid'],
            payload['sdpMLineIndex'],
          );
          if (_isRemoteDescriptionSet) {
            await _peerConnection!.addCandidate(candidate);
          } else {
            _remoteCandidatesQueue.add(candidate);
          }
        }
        break;
      case 'call_end':
        if (_currentCallUserId == senderUserId) {
          _endCallLocally();
        }
        break;
    }
  }

  void _drainRemoteCandidates() {
    for (var candidate in _remoteCandidatesQueue) {
      _peerConnection?.addCandidate(candidate);
    }
    _remoteCandidatesQueue.clear();
  }

  Future<void> startCall(String endpointId) async {
    final targetUserId = meshService.endpointToUserId[endpointId];
    if (targetUserId == null) return;

    _isIncoming = false;
    _isActive = true;
    _currentCallEndpointId = endpointId;
    _currentCallUserId = targetUserId;
    _currentCallPeerName = meshService.connectedPeers[endpointId] ?? 'Unknown';
    _remoteCandidatesQueue.clear();
    _isRemoteDescriptionSet = false;
    notifyListeners();

    await _createPeerConnection();

    final offer = await _peerConnection!.createOffer({
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    });
    await _peerConnection!.setLocalDescription(offer);

    await meshService.sendToEndpoint(
      endpointId,
      MeshMessage(
        id: const Uuid().v4(),
        senderId: meshService.userId,
        receiverId: targetUserId,
        payload: jsonEncode(offer.toMap()),
        timestamp: DateTime.now(),
        type: 'call_offer',
      ),
    );
  }

  Future<void> acceptCall() async {
    if (_currentCallEndpointId == null || _currentCallUserId == null) return;

    _isIncoming = false;
    _isActive = true;
    notifyListeners();

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await meshService.sendToEndpoint(
      _currentCallEndpointId!,
      MeshMessage(
        id: const Uuid().v4(),
        senderId: meshService.userId,
        receiverId: _currentCallUserId!,
        payload: jsonEncode(answer.toMap()),
        timestamp: DateTime.now(),
        type: 'call_answer',
      ),
    );
  }

  Future<void> endCall() async {
    if (_currentCallEndpointId != null && _currentCallUserId != null) {
      await meshService.sendToEndpoint(
        _currentCallEndpointId!,
        MeshMessage(
          id: const Uuid().v4(),
          senderId: meshService.userId,
          receiverId: _currentCallUserId!,
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

    _remoteRenderer.srcObject = null;
    _remoteStream = null;

    _currentCallEndpointId = null;
    _currentCallUserId = null;
    _currentCallPeerName = null;
    _isIncoming = false;
    _isActive = false;

    _remoteCandidatesQueue.clear();
    _isRemoteDescriptionSet = false;

    Helper.setSpeakerphoneOn(false);

    notifyListeners();
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        // Since it's P2P offline, we don't strictly need STUN/TURN,
        // local network ICE candidates usually suffice over WiFi direct.
      ],
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (_currentCallEndpointId != null && _currentCallUserId != null) {
        meshService.sendToEndpoint(
          _currentCallEndpointId!,
          MeshMessage(
            id: const Uuid().v4(),
            senderId: meshService.userId,
            receiverId: _currentCallUserId!,
            payload: jsonEncode(candidate.toMap()),
            timestamp: DateTime.now(),
            type: 'ice_candidate',
          ),
        );
      }
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint('[MeshCallService] WebRTC Connection State: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        Helper.setSpeakerphoneOn(true);
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('[MeshCallService] ICE Connection State: $state');
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'audio') {
        _remoteStream = event.streams[0];
        _remoteRenderer.srcObject = _remoteStream;
        Helper.setSpeakerphoneOn(true);
        notifyListeners();
      }
    };

    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      _remoteRenderer.srcObject = stream;
      Helper.setSpeakerphoneOn(true);
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
