/// NetPhone-specific representation of the Telnyx call lifecycle.
///
/// This model keeps the UI independent from the SDK's internal classes.
/// CallingScreen listens to this state and updates the displayed status,
/// timer, buttons and error messages.
enum TelnyxVoiceStatus {
  idle,
  requestingPermission,
  creatingSession,
  requestingToken,
  connecting,
  registered,
  initiating,
  ringing,
  active,
  reconnecting,
  ending,
  ended,
  failed,
}

/// Immutable state emitted by TelnyxVoiceService.
class TelnyxVoiceState {
  final TelnyxVoiceStatus status;
  final String message;
  final String? errorMessage;
  final String? sdkCallId;
  final bool isMuted;
  final bool isSpeakerEnabled;

  const TelnyxVoiceState({
    required this.status,
    required this.message,
    this.errorMessage,
    this.sdkCallId,
    this.isMuted = false,
    this.isSpeakerEnabled = false,
  });

  const TelnyxVoiceState.idle()
    : status = TelnyxVoiceStatus.idle,
      message = 'Ready',
      errorMessage = null,
      sdkCallId = null,
      isMuted = false,
      isSpeakerEnabled = false;

  bool get isBusy {
    return switch (status) {
      TelnyxVoiceStatus.requestingPermission ||
      TelnyxVoiceStatus.creatingSession ||
      TelnyxVoiceStatus.requestingToken ||
      TelnyxVoiceStatus.connecting ||
      TelnyxVoiceStatus.registered ||
      TelnyxVoiceStatus.initiating ||
      TelnyxVoiceStatus.ringing ||
      TelnyxVoiceStatus.active ||
      TelnyxVoiceStatus.reconnecting ||
      TelnyxVoiceStatus.ending => true,
      _ => false,
    };
  }

  bool get isCallActive => status == TelnyxVoiceStatus.active;

  bool get hasFailed => status == TelnyxVoiceStatus.failed;

  bool get hasEnded => status == TelnyxVoiceStatus.ended;

  TelnyxVoiceState copyWith({
    TelnyxVoiceStatus? status,
    String? message,
    String? errorMessage,
    bool clearError = false,
    String? sdkCallId,
    bool clearSdkCallId = false,
    bool? isMuted,
    bool? isSpeakerEnabled,
  }) {
    return TelnyxVoiceState(
      status: status ?? this.status,
      message: message ?? this.message,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      sdkCallId: clearSdkCallId ? null : sdkCallId ?? this.sdkCallId,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
    );
  }

  @override
  String toString() {
    return 'TelnyxVoiceState('
        'status: $status, '
        'message: $message, '
        'errorMessage: $errorMessage, '
        'sdkCallId: $sdkCallId, '
        'isMuted: $isMuted, '
        'isSpeakerEnabled: $isSpeakerEnabled'
        ')';
  }
}
