// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

class Algorithms {
  static const signedcurve25519 = 'signed_curve25519';
  static const curve25591 = 'curve25519';
  static const ed25519 = 'ed25519';
  static const olmv1 = 'm.olm.v1.curve25519-aes-sha2';
  static const megolmv1 = 'm.megolm.v1.aes-sha2';
}

class Keys {
  static fingerprint({String deviceId}) => '${Algorithms.ed25519}:$deviceId';
  static identity({String deviceId}) => '${Algorithms.curve25591}:$deviceId';
}

abstract class Encryption {
  /**
   * Fetch Encryption Keys
   * 
   * https://matrix.org/docs/spec/client_server/latest#id460
   * 
   * Returns the current devices and identity keys for the given users.
   */
  static Future<dynamic> fetchKeys({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    int timeout = 10 * 1000, // 10 seconds
    String lastSince,
    Map<String, dynamic> users = const {},
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/keys/query';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      "timeout": timeout,
      'device_keys': users,
      'token': lastSince,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /**
   * Fetch Room Keys
   * 
   * https://matrix.org/docs/spec/client_server/latest#id460
   * 
   * Returns the current devices and identity keys for the given users.
   */
  static Future<dynamic> fetchRoomKeys({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    int timeout = 10 * 1000, // 10 seconds
    String lastSince,
    Map<String, dynamic> users = const {},
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/unstable/room_keys/version';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /**
   * 
   * Fetch Key Changes
   * 
   * https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-keys-changes
   * 
   * Gets a list of users who have updated their device identity keys since a previous sync token.
   * 
   * The server should include in the results any users who:
   *   - currently share a room with the calling user (ie, both users have membership state join); and
   *   - added new device identity keys or removed an existing device with identity keys, between from and to.
   * 
   */
  static Future<dynamic> fetchKeyChanges({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String from,
    String to,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/keys/changes';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /**
   * Claim Keys
   * 
   * https://matrix.org/docs/spec/client_server/latest#post-matrix-client-r0-keys-claim
   * 
   * Claims one-time keys for use in pre-key messages.
   * 
   */
  static Future<dynamic> claimKeys({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    Map oneTimeKeys,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/keys/claim';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      'one_time_keys': oneTimeKeys,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  static Future<dynamic> uploadKeys({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    Map data,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/keys/upload';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(data),
    );

    return await json.decode(response.body);
  }
}
