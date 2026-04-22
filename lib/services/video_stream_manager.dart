// ignore_for_file: avoid_print
import 'dart:async';
import 'package:flutter/foundation.dart';

class VideoStreamManager extends ChangeNotifier {
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  bool _isRecordingLocally = false;
  bool get isRecordingLocally => _isRecordingLocally;

  /// Triggered automatically when AlertRouter dictates an active internet connection
  Future<void> startWebRTCStream() async {
    if (_isStreaming) return;
    
    _isStreaming = true;
    notifyListeners();

    print('VIDEO MANAGER: Opening live WebRTC socket to dispatch center...');

  }

  /// Triggered if AlertRouter detects complete offline status
  Future<void> startLocalRecording() async {
    if (_isRecordingLocally || _isStreaming) return;

    _isRecordingLocally = true;
    notifyListeners();

    print('VIDEO MANAGER: Offline. Initializing Camera plugin for local MP4 dump...');

  }

  void stopAll() {
    print('VIDEO MANAGER: Tearing down media resources.');
    _isStreaming = false;
    _isRecordingLocally = false;
    notifyListeners();
  }
}
