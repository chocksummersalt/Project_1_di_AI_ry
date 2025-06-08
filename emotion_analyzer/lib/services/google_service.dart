import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.readonly',
    ],
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<String?> getAccessToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        return auth.accessToken;
      }
      return null;
    } catch (e) {
      print('Error getting access token: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listTakeoutFiles() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final response = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files?q=mimeType=\'application/zip\' and name contains \'takeout\''),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['files']);
      } else {
        throw Exception('Failed to list takeout files: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error listing takeout files: $e');
    }
  }
} 