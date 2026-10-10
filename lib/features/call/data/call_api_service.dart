import 'dart:convert';

import 'package:http/http.dart' as http;

/// Backend REST API service for NetPhone calling.
///
/// Responsibilities:
/// 1. Create a validated and priced call session.
/// 2. Request a short-lived Telnyx WebRTC JWT.
/// 3. End the backend call session.
/// 4. Read the latest backend call status.
/// This service does not control microphone or WebRTC audio.
/// TelnyxVoiceService will handle the real-time call media.
class CallApiService {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _statusTimeout = Duration(seconds: 20);

  static String _normalizeBaseUrl(String baseUrl) {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');

    if (normalized.isEmpty) {
      throw const FormatException('Backend base URL is missing');
    }

    return normalized;
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.trim();

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw FormatException(
        'Backend returned invalid JSON '
        '(HTTP ${response.statusCode})',
      );
    }

    if (decoded is! Map) {
      throw const FormatException('Backend returned an invalid JSON response');
    }

    return Map<String, dynamic>.from(decoded);
  }

  static String _readErrorMessage(Map<String, dynamic> data, String fallback) {
    final message = data['message']?.toString().trim();

    if (message != null && message.isNotEmpty) {
      return message;
    }

    final reason = data['reason']?.toString().trim();

    if (reason != null && reason.isNotEmpty) {
      return reason;
    }

    final error = data['error']?.toString().trim();

    if (error != null && error.isNotEmpty) {
      return error;
    }

    return fallback;
  }

  static void _validateAccessToken(String token) {
    if (token.trim().isEmpty) {
      throw Exception('Login token not found. Please login again.');
    }
  }

  static void _validateSuccessfulResponse({
    required http.Response response,
    required Map<String, dynamic> data,
    required String fallbackMessage,
  }) {
    final successfulStatus =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!successfulStatus || data['ok'] != true) {
      throw Exception(
        _readErrorMessage(data, '$fallbackMessage (${response.statusCode})'),
      );
    }
  }

  /// Creates a backend call session.
  ///
  /// The backend performs:
  /// - destination validation;
  /// - provider routing;
  /// - rate calculation;
  /// - wallet validation;
  /// - call session creation.
  ///
  /// The backend does not create the actual Telnyx PSTN media call.
  static Future<Map<String, dynamic>> startCall({
    required String token,
    required String phoneNumber,
    required String baseUrl,
  }) async {
    _validateAccessToken(token);

    final destination = phoneNumber.trim();

    if (destination.isEmpty) {
      throw const FormatException('Destination phone number is required');
    }

    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);

    final response = await http
        .post(
          Uri.parse('$normalizedBaseUrl/api/calls/start'),
          headers: <String, String>{
            'Authorization': 'Bearer ${token.trim()}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'to_phone_e164': destination,
            'meta': <String, dynamic>{
              'client': 'flutter',
              'media_engine': 'telnyx_webrtc',
            },
          }),
        )
        .timeout(_defaultTimeout);

    final data = _decodeResponse(response);

    _validateSuccessfulResponse(
      response: response,
      data: data,
      fallbackMessage: 'Call session creation failed',
    );

    final session = data['session'];

    if (session is! Map || session['id'] == null) {
      throw const FormatException(
        'Call session was missing from backend response',
      );
    }

    final webrtc = data['webrtc'];

    if (webrtc is! Map) {
      throw const FormatException(
        'WebRTC call information was missing from backend response',
      );
    }

    final clientState = webrtc['client_state']?.toString().trim();

    if (clientState == null || clientState.isEmpty) {
      throw const FormatException(
        'WebRTC client state was missing from backend response',
      );
    }

    return data;
  }

  /// Requests a short-lived Telnyx WebRTC JWT from the backend.
  ///
  /// The Telnyx API key and telephony credential remain on the server.
  /// Flutter receives only the temporary WebRTC token.
  static Future<Map<String, dynamic>> getWebrtcToken({
    required String token,
    required String baseUrl,
  }) async {
    _validateAccessToken(token);

    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);

    final response = await http
        .post(
          Uri.parse('$normalizedBaseUrl/api/calls/webrtc-token'),
          headers: <String, String>{
            'Authorization': 'Bearer ${token.trim()}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
        .timeout(_defaultTimeout);

    final data = _decodeResponse(response);

    _validateSuccessfulResponse(
      response: response,
      data: data,
      fallbackMessage: 'WebRTC token request failed',
    );

    final webrtcToken = data['token']?.toString().trim();

    if (webrtcToken == null || webrtcToken.isEmpty) {
      throw const FormatException(
        'Backend did not return a Telnyx WebRTC token',
      );
    }

    final callerIdNumber = data['caller_id_number']?.toString().trim();

    if (callerIdNumber == null || callerIdNumber.isEmpty) {
      throw const FormatException('Backend did not return a caller ID number');
    }

    return data;
  }

  /// Ends or reconciles the backend call session.
  ///
  /// The primary WebRTC hangup will be performed by TelnyxVoiceService.
  /// This request finalizes the NetPhone backend session and billing.
  static Future<Map<String, dynamic>> endCall({
    required String token,
    required int sessionId,
    required String baseUrl,
  }) async {
    _validateAccessToken(token);

    if (sessionId <= 0) {
      throw const FormatException('Valid call session ID is required');
    }

    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);

    final response = await http
        .post(
          Uri.parse('$normalizedBaseUrl/api/calls/$sessionId/end'),
          headers: <String, String>{
            'Authorization': 'Bearer ${token.trim()}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
        .timeout(_defaultTimeout);

    final data = _decodeResponse(response);

    _validateSuccessfulResponse(
      response: response,
      data: data,
      fallbackMessage: 'Call end failed',
    );

    return data;
  }

  /// Retrieves the latest backend call session status.
  static Future<Map<String, dynamic>> getCallStatus({
    required String token,
    required int sessionId,
    required String baseUrl,
  }) async {
    _validateAccessToken(token);

    if (sessionId <= 0) {
      throw const FormatException('Valid call session ID is required');
    }

    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);

    final response = await http
        .get(
          Uri.parse('$normalizedBaseUrl/api/calls/$sessionId/status'),
          headers: <String, String>{
            'Authorization': 'Bearer ${token.trim()}',
            'Accept': 'application/json',
          },
        )
        .timeout(_statusTimeout);

    final data = _decodeResponse(response);

    _validateSuccessfulResponse(
      response: response,
      data: data,
      fallbackMessage: 'Call status request failed',
    );

    return data;
  }
}
