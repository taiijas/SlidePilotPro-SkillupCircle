import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/control_transport.dart';
import '../../../core/services/receiver_websocket_transport.dart';
import '../../settings/providers/settings_provider.dart';

class GestureEngine {
  final Function(String gestureName)? onGestureChange;
  final Function(String warning)? onConnectionWarning;

  GestureEngine({this.onGestureChange, this.onConnectionWarning});

  // Track active pointer IDs and their positions
  final Map<int, Offset> _activePointers = {};
  
  // Touch session tracking
  DateTime? _gestureStartTime;
  Offset? _initialCentroid;
  Offset? _lastCentroid;
  int _maxPointerCount = 0;
  bool _hasMoved = false;
  bool _longPressTriggered = false;

  // Timers
  Timer? _longPressTimer;
  Timer? _clearGestureTimer;

  // Double tap and drag hold
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  bool _isDragHolding = false;

  // Scroll and Pinch states
  double _initialPinchDistance = 0.0;
  double _pinchBaselineScale = 1.0;
  bool _isScrollMode = false;
  bool _isPinchMode = false;
  double _accumulatedScrollX = 0.0;
  double _accumulatedScrollY = 0.0;

  // Swipes
  bool _isSwipeMode = false;
  Offset? _initialSwipeCentroid;

  // Current active gesture visual state
  String _currentGesture = "";

  void _setGesture(String name) {
    if (_currentGesture != name) {
      _currentGesture = name;
      onGestureChange?.call(name);
    }
  }

  void _tempShowGesture(String name) {
    _setGesture(name);
    _clearGestureTimer?.cancel();
    _clearGestureTimer = Timer(const Duration(milliseconds: 1500), () {
      _setGesture("");
    });
  }

  void _triggerHaptic(SettingsProvider settings) {
    if (settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  bool _checkConnected(ControlTransport transport) {
    final connected = transport.isConnected;
    if (!connected) {
      onConnectionWarning?.call("Host disconnected. Action ignored.");
    }
    return connected;
  }

  Offset _calculateCentroid() {
    if (_activePointers.isEmpty) return Offset.zero;
    double sumX = 0;
    double sumY = 0;
    for (var pos in _activePointers.values) {
      sumX += pos.dx;
      sumY += pos.dy;
    }
    return Offset(sumX / _activePointers.length, sumY / _activePointers.length);
  }

  void handlePointerEvent(PointerEvent event, ControlTransport transport, SettingsProvider settings) {
    if (event is PointerDownEvent) {
      _handlePointerDown(event, transport, settings);
    } else if (event is PointerMoveEvent) {
      _handlePointerMove(event, transport, settings);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _handlePointerUp(event, transport, settings);
    }
  }

  void _handlePointerDown(PointerDownEvent event, ControlTransport transport, SettingsProvider settings) {
    _activePointers[event.pointer] = event.position;
    
    // Start of gesture session
    if (_activePointers.length == 1) {
      _gestureStartTime = DateTime.now();
      _maxPointerCount = 1;
      _hasMoved = false;
      _longPressTriggered = false;
      _initialCentroid = event.position;
      _lastCentroid = event.position;

      // Double-tap & Hold drag check (Trackpad Mode)
      if (settings.gestureMode == 'trackpad') {
        final now = DateTime.now();
        if (_lastTapTime != null && _lastTapPosition != null) {
          final diffMs = now.difference(_lastTapTime!).inMilliseconds;
          final dist = (event.position - _lastTapPosition!).distance;
          
          if (diffMs <= settings.tapTimeout && dist <= 25.0) {
            if (_checkConnected(transport)) {
              _isDragHolding = true;
              _triggerHaptic(settings);
              transport.sendMouseButton(0, true); // Left click down
              _tempShowGesture("Double Tap & Drag");
            }
          }
        }

        // Start long press timer if not dragging
        if (!_isDragHolding) {
          _longPressTimer?.cancel();
          _longPressTimer = Timer(Duration(milliseconds: settings.longPressDuration), () {
            if (_activePointers.length == 1 && _maxPointerCount == 1 && !_hasMoved && !_longPressTriggered) {
              if (_checkConnected(transport)) {
                _longPressTriggered = true;
                _triggerHaptic(settings);
                _sendRightClick(transport);
                _tempShowGesture("Long Press (Right Click)");
              }
            }
          });
        }
      }
    } else {
      // Cancel long press timer since we have multiple fingers
      _longPressTimer?.cancel();
      _maxPointerCount = max(_maxPointerCount, _activePointers.length);

      final centroid = _calculateCentroid();
      _lastCentroid = centroid;

      if (_activePointers.length == 2) {
        final posList = _activePointers.values.toList();
        _initialPinchDistance = (posList[0] - posList[1]).distance;
        _pinchBaselineScale = 1.0;
        _isScrollMode = false;
        _isPinchMode = false;
        _accumulatedScrollX = 0;
        _accumulatedScrollY = 0;
      }

      if (_activePointers.length >= 3) {
        _isSwipeMode = false;
        _initialSwipeCentroid = centroid;
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event, ControlTransport transport, SettingsProvider settings) {
    _activePointers[event.pointer] = event.position;
    final centroid = _calculateCentroid();

    if (_initialCentroid != null) {
      final totalMove = (centroid - _initialCentroid!).distance;
      if (totalMove > 8.0) {
        _hasMoved = true;
        _longPressTimer?.cancel(); // Cancel long press since pointer moved significantly
      }
    }

    final delta = _lastCentroid != null ? (centroid - _lastCentroid!) : Offset.zero;
    _lastCentroid = centroid;

    if (_maxPointerCount == 1) {
      if (settings.gestureMode == 'trackpad') {
        if (_checkConnected(transport)) {
          // Send mouse move
          final double dx = delta.dx * settings.pointerSensitivity;
          final double dy = delta.dy * settings.pointerSensitivity;
          if (dx != 0 || dy != 0) {
            transport.sendMouseMove(
              dx.round().clamp(-127, 127),
              dy.round().clamp(-127, 127),
            );
          }
        }
      }
    } else if (_activePointers.length == 2) {
      final posList = _activePointers.values.toList();
      final currentDistance = (posList[0] - posList[1]).distance;
      final scale = _initialPinchDistance > 0.0 ? (currentDistance / _initialPinchDistance) : 1.0;

      // Mode locking check
      if (!_isScrollMode && !_isPinchMode) {
        final scaleDiff = (scale - 1.0).abs();
        final double distMoved = _initialCentroid != null ? (centroid - _initialCentroid!).distance : 0.0;

        if (scaleDiff >= 0.12 * settings.pinchSensitivity) {
          _isPinchMode = true;
          _pinchBaselineScale = scale;
        } else if (distMoved >= 10.0 * settings.gestureSensitivity) {
          _isScrollMode = true;
        }
      }

      if (_isScrollMode) {
        if (_checkConnected(transport)) {
          // Scroll vertical
          _accumulatedScrollY += delta.dy * settings.scrollSensitivity;
          if (_accumulatedScrollY.abs() >= 1.5) {
            final int scrollVal = _accumulatedScrollY.round();
            transport.sendMouseScroll(scrollVal.clamp(-127, 127));
            _accumulatedScrollY -= scrollVal;
            _tempShowGesture("Two-finger Scroll");
          }

          // Scroll horizontal
          _accumulatedScrollX += delta.dx * settings.scrollSensitivity;
          final thresholdX = 40.0 / settings.gestureSensitivity;
          if (_accumulatedScrollX.abs() >= thresholdX) {
            _triggerHaptic(settings);
            if (_accumulatedScrollX > 0) {
              // Scroll right (swipe fingers right) -> Go Left/Back
              _sendBackForwardShortcut(transport, settings, isBack: true);
              _tempShowGesture("Scroll Left (Back)");
            } else {
              // Scroll left (swipe fingers left) -> Go Right/Forward
              _sendBackForwardShortcut(transport, settings, isBack: false);
              _tempShowGesture("Scroll Right (Forward)");
            }
            _accumulatedScrollX = 0;
          }
        }
      } else if (_isPinchMode) {
        if (_checkConnected(transport)) {
          final scaleRatio = scale / _pinchBaselineScale;
          const double pinchOutThreshold = 1.15;
          const double pinchInThreshold = 0.85;

          if (scaleRatio >= pinchOutThreshold) {
            _pinchBaselineScale = scale;
            _triggerHaptic(settings);
            _sendZoomShortcut(transport, settings, isZoomIn: true);
            _tempShowGesture("Pinch Out (Zoom In)");
          } else if (scaleRatio <= pinchInThreshold) {
            _pinchBaselineScale = scale;
            _triggerHaptic(settings);
            _sendZoomShortcut(transport, settings, isZoomIn: false);
            _tempShowGesture("Pinch In (Zoom Out)");
          }
        }
      }
    } else if (_activePointers.length >= 3) {
      if (_initialSwipeCentroid != null && !_isSwipeMode) {
        final swipeDisplacement = centroid - _initialSwipeCentroid!;
        final swipeThreshold = settings.swipeThreshold;

        if (swipeDisplacement.dx.abs() >= swipeThreshold || swipeDisplacement.dy.abs() >= swipeThreshold) {
          _isSwipeMode = true;
          _triggerHaptic(settings);

          String direction;
          if (swipeDisplacement.dx.abs() > swipeDisplacement.dy.abs()) {
            direction = swipeDisplacement.dx > 0 ? "right" : "left";
          } else {
            direction = swipeDisplacement.dy > 0 ? "down" : "up";
          }

          if (settings.gestureMode == 'trackpad') {
            if (_maxPointerCount == 3) {
              _sendThreeFingerSwipe(transport, settings, direction);
              _tempShowGesture("Three-finger Swipe ${direction.toUpperCase()}");
            } else if (_maxPointerCount == 4) {
              _sendFourFingerSwipe(transport, settings, direction);
              _tempShowGesture("Four-finger Swipe ${direction.toUpperCase()}");
            }
          } else if (settings.gestureMode == 'presentation') {
            // Presentation Swipe Mode
            if (direction == "left") {
              _sendNextSlide(transport, settings);
              _tempShowGesture("Presentation Swipe Left (Next)");
            } else if (direction == "right") {
              _sendPrevSlide(transport, settings);
              _tempShowGesture("Presentation Swipe Right (Prev)");
            }
          }
        }
      }
    }
    
    // Presentation Gesture Mode: support 1-finger swipe
    if (settings.gestureMode == 'presentation' && _maxPointerCount == 1 && _initialCentroid != null && !_isSwipeMode) {
      final double swipeDisplacementX = centroid.dx - _initialCentroid!.dx;
      if (swipeDisplacementX.abs() >= settings.swipeThreshold) {
        _isSwipeMode = true;
        _triggerHaptic(settings);
        if (swipeDisplacementX < 0) {
          _sendNextSlide(transport, settings);
          _tempShowGesture("Swipe Left (Next Slide)");
        } else {
          _sendPrevSlide(transport, settings);
          _tempShowGesture("Swipe Right (Prev Slide)");
        }
      }
    }
  }

  void _handlePointerUp(PointerEvent event, ControlTransport transport, SettingsProvider settings) {
    _activePointers.remove(event.pointer);
    
    if (_activePointers.isEmpty) {
      _longPressTimer?.cancel();
      
      final sessionEndTime = DateTime.now();
      
      if (_isDragHolding) {
        _isDragHolding = false;
        if (_checkConnected(transport)) {
          transport.sendMouseButton(0, false); // Left click up
          _triggerHaptic(settings);
        }
      } else if (!_hasMoved && !_longPressTriggered) {
        if (_gestureStartTime != null) {
          final sessionDurationMs = sessionEndTime.difference(_gestureStartTime!).inMilliseconds;
          if (sessionDurationMs <= settings.tapTimeout) {
            _handleTap(transport, settings, event.position);
          }
        }
      }

      // Reset touch stats
      _maxPointerCount = 0;
      _isScrollMode = false;
      _isPinchMode = false;
      _isSwipeMode = false;
    }
  }

  void _handleTap(ControlTransport transport, SettingsProvider settings, Offset position) {
    if (settings.gestureMode == 'trackpad') {
      if (_maxPointerCount == 1) {
        // One-finger tap: left click
        if (_checkConnected(transport)) {
          _triggerHaptic(settings);
          transport.sendLeftClick();
          _tempShowGesture("Tap (Left Click)");
        }
        _lastTapTime = DateTime.now();
        _lastTapPosition = position;
      } else if (_maxPointerCount == 2) {
        // Two-finger tap: right click
        if (_checkConnected(transport)) {
          _triggerHaptic(settings);
          _sendRightClick(transport);
          _tempShowGesture("Two-finger Tap (Right Click)");
        }
      } else if (_maxPointerCount == 3) {
        // Three-finger tap: configurable action
        if (_checkConnected(transport)) {
          _triggerHaptic(settings);
          _executeConfigurableAction(transport, settings, settings.threeFingerTapAction, 
              settings.threeFingerTapCustomModifier, settings.threeFingerTapCustomKey);
          _tempShowGesture("Three-finger Tap");
        }
      } else if (_maxPointerCount == 4) {
        // Four-finger tap: configurable action
        if (_checkConnected(transport)) {
          _triggerHaptic(settings);
          _executeConfigurableAction(transport, settings, settings.fourFingerTapAction, 
              settings.fourFingerTapCustomModifier, settings.fourFingerTapCustomKey);
          _tempShowGesture("Four-finger Tap");
        }
      }
    } else if (settings.gestureMode == 'presentation') {
      if (_maxPointerCount == 1) {
        // Double tap: start slideshow
        final now = DateTime.now();
        if (_lastTapTime != null && _lastTapPosition != null) {
          final diffMs = now.difference(_lastTapTime!).inMilliseconds;
          final dist = (position - _lastTapPosition!).distance;
          if (diffMs <= settings.tapTimeout && dist <= 25.0) {
            if (_checkConnected(transport)) {
              _triggerHaptic(settings);
              _sendStartSlideshow(transport, settings);
              _tempShowGesture("Double Tap (Start Show)");
            }
          }
        }
        _lastTapTime = now;
        _lastTapPosition = position;
      } else if (_maxPointerCount == 2) {
        // Two-finger tap: black screen
        if (_checkConnected(transport)) {
          _triggerHaptic(settings);
          transport.sendKeyboardShortcut("", "b");
          _tempShowGesture("Two-finger Tap (Black Screen)");
        }
      } else if (_maxPointerCount == 3) {
        // Three-finger tap: white screen
        if (_checkConnected(transport)) {
          _triggerHaptic(settings);
          transport.sendKeyboardShortcut("", "w");
          _tempShowGesture("Three-finger Tap (White Screen)");
        }
      }
    }
  }

  // Right click helper
  void _sendRightClick(ControlTransport transport) async {
    await transport.sendMouseButton(1, true);
    await Future.delayed(const Duration(milliseconds: 30));
    await transport.sendMouseButton(1, false);
  }

  // Profile-specific zoom helper
  void _sendZoomShortcut(ControlTransport transport, SettingsProvider settings, {required bool isZoomIn}) {
    final action = isZoomIn ? "pinch_out" : "pinch_in";
    final profile = settings.platformProfile.toLowerCase();
    
    if (transport is ReceiverWebSocketTransport) {
      transport.sendGesture(action, profile);
    } else {
      final key = isZoomIn ? "plus" : "minus";
      final isMac = _isMacProfile(settings);
      final mod = isMac ? "meta" : "ctrl";
      transport.sendKeyboardShortcut(mod, key);
    }
  }

  // Scroll horizontal back/forward navigation
  void _sendBackForwardShortcut(ControlTransport transport, SettingsProvider settings, {required bool isBack}) {
    final isMac = _isMacProfile(settings);
    if (isMac) {
      transport.sendKeyboardShortcut("meta", isBack ? "left_arrow" : "right_arrow");
    } else {
      transport.sendKeyboardShortcut("alt", isBack ? "left_arrow" : "right_arrow");
    }
  }

  // Configurable action runner
  void _executeConfigurableAction(ControlTransport transport, SettingsProvider settings, String action, String customMod, String customKey) {
    switch (action) {
      case 'middle_click':
        transport.sendMouseButton(2, true);
        Future.delayed(const Duration(milliseconds: 30), () {
          transport.sendMouseButton(2, false);
        });
        break;
      case 'left_click':
        transport.sendLeftClick();
        break;
      case 'right_click':
        _sendRightClick(transport);
        break;
      case 'space':
        transport.sendKeyboardShortcut("", "space");
        break;
      case 'enter':
        transport.sendKeyboardShortcut("", "enter");
        break;
      case 'custom':
        if (customKey.isNotEmpty) {
          transport.sendKeyboardShortcut(customMod, customKey);
        }
        break;
      case 'none':
      default:
        break;
    }
  }

  bool _isMacProfile(SettingsProvider settings) {
    final prof = settings.platformProfile.toLowerCase();
    return prof == 'macos' || prof == 'keynote' || (prof == 'powerpoint' && settings.presentationProfile.contains('mac')) || (prof == 'google_slides' && settings.presentationProfile.contains('mac'));
  }

  void _sendThreeFingerSwipe(ControlTransport transport, SettingsProvider settings, String direction) {
    transport.sendGesture('three_finger_swipe_$direction', settings.platformProfile.toLowerCase());
  }

  void _sendFourFingerSwipe(ControlTransport transport, SettingsProvider settings, String direction) {
    transport.sendGesture('four_finger_swipe_$direction', settings.platformProfile.toLowerCase());
  }

  // Presentation Mode Next/Prev Slide
  void _sendNextSlide(ControlTransport transport, SettingsProvider settings) {
    transport.sendKeyboardShortcut("", "right_arrow");
  }

  void _sendPrevSlide(ControlTransport transport, SettingsProvider settings) {
    transport.sendKeyboardShortcut("", "left_arrow");
  }

  void _sendStartSlideshow(ControlTransport transport, SettingsProvider settings) {
    final prof = settings.platformProfile.toLowerCase();
    if (prof == 'keynote') {
      transport.sendKeyboardShortcut("meta+alt", "p");
    } else if (prof == 'powerpoint') {
      if (settings.presentationProfile.contains('mac')) {
        transport.sendKeyboardShortcut("meta+shift", "enter");
      } else {
        transport.sendKeyboardShortcut("", "f5");
      }
    } else if (prof == 'google_slides') {
      if (settings.presentationProfile.contains('mac')) {
        transport.sendKeyboardShortcut("meta", "enter");
      } else {
        transport.sendKeyboardShortcut("ctrl", "f5");
      }
    } else if (prof == 'macos') {
      transport.sendKeyboardShortcut("meta+shift", "enter");
    } else {
      transport.sendKeyboardShortcut("", "f5");
    }
  }
}
