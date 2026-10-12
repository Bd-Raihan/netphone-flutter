import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telnyx_webrtc/model/connection_status.dart';
import 'package:telnyx_webrtc/telnyx_webrtc.dart';
import 'package:telnyx_webrtc/utils/logging/log_level.dart';

import '../models/telnyx_voice_state.dart';

/// Production Telnyx WebRTC call controller for NetPhone.
///
/// Responsibilities:
/// - request microphone permission;
/// - authenticate with a short-lived Telnyx JWT;
/// - wait until the SDK is registered and ready;
/// - create one outbound WebRTC call;
/// - expose call lifecycle to the Flutter UI;
/// - mute/unmute microphone;
/// - enable/disable speaker;
/// - send DTMF;
/// - end the active call;
/// - dispose all streams and SDK resources.
///
/// This class does not create Backend call sessions.
/// CallingScreen creates the Backend session first and then passes the
/// destination, caller ID and client state to this service.
class TelnyxVoiceService {
  TelnyxVoiceService();

  final TelnyxClient _client = TelnyxClient();

  final StreamController<TelnyxVoiceState> _stateController =
      StreamController<TelnyxVoiceState>.broadcast();

  TelnyxVoiceState _state = const TelnyxVoiceState.idle();

  Call? _activeCall;

  Completer<void>? _registrationCompleter;

  bool _isDisposed = false;
  bool _isConnecting = false;
  bool _isRegistered = false;
  bool _isEnding = false;

  Stream<TelnyxVoiceState> get states => _stateController.stream;

  TelnyxVoiceState get currentState => _state;

  bool get isRegistered => _isRegistered;

  bool get hasActiveCall => _activeCall != null;

  void _emit(TelnyxVoiceState nextState) {
    if (_isDisposed) {
      return;
    }

    _state = nextState;

    if (!_stateController.isClosed) {
      _stateController.add(nextState);
    }

    debugPrint('📞 TELNYX VOICE STATE => $nextState');
  }

  void _emitFailure(Object error, {String? fallbackMessage}) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    _emit(
      _state.copyWith(
        status: TelnyxVoiceStatus.failed,
        message: 'Call failed',
        errorMessage: message.isEmpty
            ? fallbackMessage ?? 'Unknown Telnyx WebRTC error'
            : message,
      ),
    );
  }

  /// Requests the Android/iOS microphone permission.
  Future<void> ensureMicrophonePermission() async {
    _emit(
      _state.copyWith(
        status: TelnyxVoiceStatus.requestingPermission,
        message: 'Requesting microphone permission',
        clearError: true,
      ),
    );

    final status = await Permission.microphone.request();

    if (!status.isGranted) {
      throw Exception(
        status.isPermanentlyDenied
            ? 'Microphone permission is permanently denied. '
                  'Open app settings and allow microphone access.'
            : 'Microphone permission is required to make calls.',
      );
    }
  }

  /// Authenticates the Telnyx SDK using the short-lived JWT generated
  /// by the NetPhone Backend.
  ///
  /// This method waits until Telnyx reports that the client is registered
  /// and ready before returning.
  Future<void> connectWithToken({
    required String sipToken,
    required String callerIdName,
    required String callerIdNumber,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isDisposed) {
      throw StateError('TelnyxVoiceService has been disposed');
    }

    final token = sipToken.trim();
    final callerName = callerIdName.trim();
    final callerNumber = callerIdNumber.trim();

    if (token.isEmpty) {
      throw const FormatException('Telnyx WebRTC token is missing');
    }

    if (callerName.isEmpty) {
      throw const FormatException('Caller ID name is missing');
    }

    if (callerNumber.isEmpty) {
      throw const FormatException('Caller ID number is missing');
    }

    if (_isRegistered) {
      return;
    }

    if (_isConnecting && _registrationCompleter != null) {
      return _registrationCompleter!.future.timeout(timeout);
    }

    _isConnecting = true;
    _registrationCompleter = Completer<void>();

    _emit(
      _state.copyWith(
        status: TelnyxVoiceStatus.connecting,
        message: 'Connecting to Telnyx',
        clearError: true,
      ),
    );

    _client.onConnectionStateChanged = (ConnectionStatus status) {
      debugPrint('🔌 TELNYX CONNECTION STATUS => $status');

      switch (status) {
        case ConnectionStatus.connected:
          _emit(
            _state.copyWith(
              status: TelnyxVoiceStatus.connecting,
              message: 'Connected, registering',
              clearError: true,
            ),
          );
          break;

        case ConnectionStatus.clientReady:
          _isRegistered = true;
          _isConnecting = false;

          _emit(
            _state.copyWith(
              status: TelnyxVoiceStatus.registered,
              message: 'Telnyx client ready',
              clearError: true,
            ),
          );

          if (_registrationCompleter?.isCompleted == false) {
            _registrationCompleter!.complete();
          }
          break;

        case ConnectionStatus.reconnecting:
          _isRegistered = false;

          _emit(
            _state.copyWith(
              status: TelnyxVoiceStatus.reconnecting,
              message: 'Reconnecting to Telnyx',
            ),
          );
          break;

        case ConnectionStatus.disconnected:
          _isRegistered = false;
          _isConnecting = false;

          if (_registrationCompleter?.isCompleted == false) {
            _registrationCompleter!.completeError(
              Exception('Telnyx disconnected before registration completed'),
            );
          }

          if (!_isEnding &&
              _state.status != TelnyxVoiceStatus.ended &&
              _state.status != TelnyxVoiceStatus.failed) {
            _emit(
              _state.copyWith(
                status: TelnyxVoiceStatus.failed,
                message: 'Telnyx disconnected',
                errorMessage: 'Unable to connect to Telnyx voice service',
              ),
            );
          }
          break;
      }
    };

    _client.onSocketErrorReceived = (TelnyxSocketError error) {
      debugPrint('❌ TELNYX SOCKET ERROR => $error');

      _isConnecting = false;

      if (_registrationCompleter?.isCompleted == false) {
        _registrationCompleter!.completeError(Exception(error.toString()));
      }

      _emitFailure(error, fallbackMessage: 'Telnyx socket connection failed');
    };

    _client.onSocketMessageReceived = (TelnyxMessage message) {
      final method = message.socketMethod.trim().toUpperCase();

      debugPrint(
        '📨 TELNYX SOCKET MESSAGE => '
        '$method | ${message.message}',
      );

      if (method.contains('CLIENT_READY') || method.contains('CLIENTREADY')) {
        _isRegistered = true;
        _isConnecting = false;

        _emit(
          _state.copyWith(
            status: TelnyxVoiceStatus.registered,
            message: 'Telnyx client ready',
            clearError: true,
          ),
        );

        if (_registrationCompleter?.isCompleted == false) {
          _registrationCompleter!.complete();
        }

        return;
      }

      if (method.contains('RINGING')) {
        _emit(
          _state.copyWith(
            status: TelnyxVoiceStatus.ringing,
            message: 'Ringing',
            sdkCallId: _activeCall?.callId,
            clearError: true,
          ),
        );

        return;
      }

      if (method.contains('ANSWER')) {
        final activeCall = _activeCall;

        if (activeCall != null) {
          try {
            // Answer হওয়ার পর default audio output earpiece-এ দিন।
            // Speaker button চাপলে পরে loudspeaker চালু হবে।
            activeCall.enableSpeakerPhone(false);
          } catch (error, stackTrace) {
            debugPrint('⚠️ TELNYX AUDIO ROUTE ERROR => $error');
            debugPrintStack(stackTrace: stackTrace);
          }
        }

        _emit(
          _state.copyWith(
            status: TelnyxVoiceStatus.active,
            message: 'Connected',
            sdkCallId: activeCall?.callId,
            isSpeakerEnabled: false,
            clearError: true,
          ),
        );

        return;
      }

      if (method.contains('BYE')) {
        _isEnding = false;

        _emit(
          _state.copyWith(
            status: TelnyxVoiceStatus.ended,
            message: 'Call ended',
            clearSdkCallId: true,
          ),
        );

        _activeCall = null;
      }
    };

    final config = TokenConfig(
      sipToken: token,
      sipCallerIDName: callerName,
      sipCallerIDNumber: callerNumber,
      autoReconnect: true,
      logLevel: LogLevel.info,
      debug: true,
      ringbackPath: 'assets/audio/ringback.mp3',
    );

    try {
      _client.connectWithToken(config);

      await _registrationCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          _isConnecting = false;

          throw TimeoutException(
            'Telnyx registration timed out after '
            '${timeout.inSeconds} seconds',
          );
        },
      );
    } catch (error) {
      _isConnecting = false;
      _emitFailure(
        error,
        fallbackMessage: 'Unable to register Telnyx WebRTC client',
      );
      rethrow;
    }
  }

  /// Starts a real outbound WebRTC-to-PSTN call.
  ///
  /// [clientState] must be the value returned by
  /// POST /api/calls/start so Telnyx webhooks can correlate this provider
  /// call with the NetPhone call_sessions row.
  /// Starts a real outbound WebRTC-to-PSTN call.
  ///
  /// The Telnyx client must already be registered through [connectWithToken].
  /// The destination must be a valid E.164 phone number.
  Future<void> startOutboundCall({
    required String callerIdName,
    required String callerIdNumber,
    required String destinationNumber,
    required String clientState,
  }) async {
    if (_isDisposed) {
      throw StateError('TelnyxVoiceService has been disposed');
    }

    if (!_isRegistered) {
      throw StateError('Telnyx client is not registered');
    }

    if (_activeCall != null) {
      throw StateError('Another Telnyx call is already active');
    }

    final callerName = callerIdName.trim();
    final callerNumber = callerIdNumber.trim();
    final destination = destinationNumber.trim();
    final normalizedClientState = clientState.trim();

    if (callerName.isEmpty) {
      throw const FormatException('Caller ID name is missing');
    }

    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(callerNumber)) {
      throw FormatException('Invalid caller ID number: $callerNumber');
    }

    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(destination)) {
      throw FormatException('Invalid destination number: $destination');
    }

    if (normalizedClientState.isEmpty) {
      throw const FormatException('WebRTC client state is missing');
    }

    _emit(
      _state.copyWith(
        status: TelnyxVoiceStatus.initiating,
        message: 'Calling',
        clearError: true,
      ),
    );

    try {
      debugPrint('📞 TELNYX OUTBOUND INVITE => {');
      debugPrint('  callerName: $callerName');
      debugPrint('  callerNumber: $callerNumber');
      debugPrint('  destination: $destination');
      debugPrint('  clientState: $normalizedClientState');
      debugPrint('  trickleIce: false');
      debugPrint('}');

      final call = _client.newInvite(
        callerName,
        callerNumber,
        destination,
        normalizedClientState,
        debug: true,
        useTrickleIce: false,
        mutedMicOnStart: false,
      );

      _activeCall = call;

      _emit(
        _state.copyWith(
          status: TelnyxVoiceStatus.initiating,
          message: 'Calling',
          sdkCallId: call.callId,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      _activeCall = null;

      debugPrint('❌ TELNYX OUTBOUND INVITE ERROR => $error');
      debugPrintStack(stackTrace: stackTrace);

      _emitFailure(error, fallbackMessage: 'Unable to start Telnyx call');

      rethrow;
    }
  }

  Future<void> setMuted(bool muted) async {
    final call = _activeCall;

    if (call == null) {
      throw StateError('No active Telnyx call');
    }

    if (_state.isMuted != muted) {
      call.onMuteUnmutePressed();
    }

    _emit(
      _state.copyWith(
        isMuted: muted,
        message: muted ? 'Microphone muted' : 'Microphone unmuted',
      ),
    );
  }

  Future<void> setSpeakerEnabled(bool enabled) async {
    final call = _activeCall;

    if (call == null) {
      throw StateError('No active Telnyx call');
    }

    call.enableSpeakerPhone(enabled);

    _emit(
      _state.copyWith(
        isSpeakerEnabled: enabled,
        message: enabled ? 'Speaker enabled' : 'Speaker disabled',
      ),
    );
  }

  Future<void> sendDtmf(String tone) async {
    if (_isDisposed) {
      throw StateError('Call is no longer available');
    }

    final call = _activeCall;

    if (call == null) {
      throw StateError('No active Telnyx call');
    }

    if (_isEnding || !_state.isCallActive) {
      throw StateError('Wait until the call is connected to use the keypad');
    }

    if (!_client.isConnected()) {
      throw StateError('Voice connection is unavailable. Please try again');
    }

    const validTones = <String>{
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '*',
      '#',
    };

    final normalizedTone = tone.trim();

    if (!validTones.contains(normalizedTone)) {
      throw const FormatException('Invalid DTMF tone');
    }

    // The SDK dispatches the key; it does not confirm IVR delivery.
    call.dtmf(normalizedTone);
  }

  Future<void> endCall() async {
    if (_isEnding) {
      return;
    }

    final call = _activeCall;

    if (call == null) {
      _emit(
        _state.copyWith(
          status: TelnyxVoiceStatus.ended,
          message: 'Call ended',
          clearSdkCallId: true,
        ),
      );
      return;
    }

    _isEnding = true;

    _emit(
      _state.copyWith(status: TelnyxVoiceStatus.ending, message: 'Ending call'),
    );

    try {
      call.endCall();
    } catch (error) {
      debugPrint('⚠️ TELNYX END CALL ERROR => $error');

      _emitFailure(error, fallbackMessage: 'Unable to end Telnyx call');

      rethrow;
    } finally {
      _isEnding = false;
    }
  }

  /// Disconnects only after the current call has ended.
  Future<void> disconnect() async {
    try {
      _activeCall = null;
      _isRegistered = false;
      _isConnecting = false;

      if (_client.isConnected()) {
        _client.disconnect();
      }
    } catch (error) {
      debugPrint('⚠️ TELNYX DISCONNECT ERROR => $error');
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    try {
      if (_activeCall != null) {
        try {
          _activeCall!.endCall();
        } catch (error) {
          debugPrint('⚠️ TELNYX DISPOSE HANGUP ERROR => $error');
        }
      }

      if (_client.isConnected()) {
        _client.disconnect();
      }
    } finally {
      _activeCall = null;

      if (!_stateController.isClosed) {
        await _stateController.close();
      }
    }
  }
}
