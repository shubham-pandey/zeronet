import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

enum AnomalyType { speedDrop, impact, freeFall, manual, none }

class SpeedReading {
  final double speedKmh;
  final DateTime timestamp;
  SpeedReading(this.speedKmh, this.timestamp);
}

class GForceReading {
  final double gForce;
  final DateTime timestamp;
  GForceReading(this.gForce, this.timestamp);
}

class DetectionEngine extends ChangeNotifier {
  // Speed Buffer (Rolling 3 seconds)
  final ListQueue<SpeedReading> _speedBuffer = ListQueue<SpeedReading>();
  
  // G-Force Buffer (Rolling 1.5 seconds)
  final ListQueue<GForceReading> _gForceBuffer = ListQueue<GForceReading>();

  // Thresholds
  static const double impactThresholdG = 2.5;
  static const double freefallThresholdG = 0.2;
  static const int freefallDurationMs = 1000;
  static const double speedHighThresholdKmh = 30.0;
  static const double speedLowThresholdKmh = 5.0;
  static const int speedDecelWindowMs = 3000; // 3 seconds

  // Incident State
  AnomalyType _currentAnomaly = AnomalyType.none;
  AnomalyType get currentAnomaly => _currentAnomaly;

  bool _isTimerActive = false;
  bool get isTimerActive => _isTimerActive;

  int _countdownRemaining = 0;
  int get countdownRemaining => _countdownRemaining;

  Timer? _countdownTimer;

  // Incident confirmed callback to trigger the Alert Router
  final Function(AnomalyType) onIncidentConfirmed;

  DetectionEngine({required this.onIncidentConfirmed});

  /// Analyze incoming GPS speed
  void addSpeedReading(double speedMps) {
    if (_isTimerActive) return; // Pause evaluation if an anomaly is already ticking

    final now = DateTime.now();
    final speedKmh = speedMps * 3.6;
    _speedBuffer.addLast(SpeedReading(speedKmh, now));

    // Trim readings older than our 3 second window
    while (_speedBuffer.isNotEmpty &&
        now.difference(_speedBuffer.first.timestamp).inMilliseconds > speedDecelWindowMs) {
      _speedBuffer.removeFirst();
    }

    _evaluateSpeedAnomaly(speedKmh);
  }

  /// Analyze incoming Accelerometer magnitude
  void addGForceReading(double gForce) {
    if (_isTimerActive) return; // Pause evaluation if an anomaly is already ticking

    final now = DateTime.now();
    _gForceBuffer.addLast(GForceReading(gForce, now));

    // Trim readings older than our free fall duration window (1.5s for safety buffer)
    while (_gForceBuffer.isNotEmpty &&
        now.difference(_gForceBuffer.first.timestamp).inMilliseconds > freefallDurationMs + 500) {
      _gForceBuffer.removeFirst();
    }

    _evaluateGForceAnomaly(gForce, now);
  }

  void _evaluateSpeedAnomaly(double currentSpeedKmh) {
    // If we are currently going very slow, check if we were recently going very fast
    if (currentSpeedKmh <= speedLowThresholdKmh) {
      bool wasGoingFast = false;
      for (final reading in _speedBuffer) {
        if (reading.speedKmh >= speedHighThresholdKmh) {
          wasGoingFast = true;
          break;
        }
      }

      if (wasGoingFast) {
        _triggerAnomaly(AnomalyType.speedDrop);
      }
    }
  }

  void _evaluateGForceAnomaly(double currentGForce, DateTime now) {
    // 1. Instant Impact Verification
    if (currentGForce >= impactThresholdG) {
      _triggerAnomaly(AnomalyType.impact);
      return;
    }

    // 2. Free-fall verification (Must be continuously below 0.2G for >1000ms)
    if (currentGForce <= freefallThresholdG) {
      bool isContinuousFreeFall = true;
      DateTime? earliestFreeFallTime;

      // Scan our buffer backwards to see how long it has been in free fall
      for (final reading in _gForceBuffer) {
        if (reading.gForce <= freefallThresholdG) {
          if (earliestFreeFallTime == null || reading.timestamp.isBefore(earliestFreeFallTime)) {
            earliestFreeFallTime = reading.timestamp;
          }
        } else {
          // A reading above 0.2G ruins the continuity
          // Since it's a queue, we just reset our continuous logic for older items
          isContinuousFreeFall = false;
          break; // Optimization: Actually since it's FIFO, older items are at the front. 
                 // If we find a non-freefall, the continuous tail is broken.
        }
      }

      if (isContinuousFreeFall && earliestFreeFallTime != null) {
        if (now.difference(earliestFreeFallTime).inMilliseconds >= freefallDurationMs) {
          _triggerAnomaly(AnomalyType.freeFall);
        }
      }
    }
  }

  void triggerManualSOS() {
    _triggerAnomaly(AnomalyType.manual);
  }

  void _triggerAnomaly(AnomalyType type) {
    if (_isTimerActive) return;
    
    _currentAnomaly = type;
    _isTimerActive = true;
    _countdownRemaining = 15; // 15 second chance to cancel
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownRemaining > 0) {
        _countdownRemaining -= 1;
        notifyListeners();
      } else {
        timer.cancel();
        _isTimerActive = false;
        onIncidentConfirmed(_currentAnomaly);
      }
    });
  }

  /// Cancels an active anomaly countdown before it automatically confirms
  void cancelIncident() {
    _countdownTimer?.cancel();
    _isTimerActive = false;
    _currentAnomaly = AnomalyType.none;
    _countdownRemaining = 0;
    
    // Clear buffers so it doesn't instantly re-trigger
    _speedBuffer.clear();
    _gForceBuffer.clear();
    
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
