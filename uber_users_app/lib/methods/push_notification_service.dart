import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/global/global_var.dart';

class PushNotificationService {
  // Apps use Firebase project uberclone-6e4a0. The embedded service account
  // below is for an old project (everyone-2de50) and will fail JWT auth until
  // you replace it with a key from uberclone-6e4a0 (Firebase Console →
  // Project settings → Service accounts → Generate new private key).
  static const String _fcmProjectId = "YOUR_FIREBASE_PROJECT_ID";

  static Future<String?> getAccessToken() async {
    try {
      // Replace with your Firebase service account JSON (never commit real keys).
      final serviceAccountJson = {
        "type": "service_account",
        "project_id": "YOUR_FIREBASE_PROJECT_ID",
        "private_key_id": "YOUR_PRIVATE_KEY_ID",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n",
        "client_email":
            "YOUR_SERVICE_ACCOUNT@YOUR_FIREBASE_PROJECT_ID.iam.gserviceaccount.com",
        "client_id": "YOUR_CLIENT_ID",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/YOUR_SERVICE_ACCOUNT",
        "universe_domain": "googleapis.com"
      };
      List<String> scopes = [
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/firebase.database",
        "https://www.googleapis.com/auth/firebase.messaging"
      ];

      http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );

      auth.AccessCredentials credentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client,
      );
      client.close();
      return credentials.accessToken.data;
    } catch (e) {
      print(
          "Failed to obtain FCM access token (push optional; trip still assigned via RTDB): $e");
      return null;
    }
  }

  static Future<void> sendNotificationToSelectedDriver(
      String deviceToken, BuildContext context, String tripID) async {
    try {
      print('device token, $deviceToken');
      final dropOff = Provider.of<AppInfoClass>(context, listen: false)
          .dropOffLocation
          ?.placeName
          ?.toString();
      final pickUp = Provider.of<AppInfoClass>(context, listen: false)
          .pickUpLocation
          ?.placeName
          ?.toString();
      print('pickup address is $pickUp');

      final String? serverKeyTokenKey = await getAccessToken();
      if (serverKeyTokenKey == null) {
        print(
            "Skipping FCM push — invalid/missing service account. Driver still gets trip via newTripStatus.");
        return;
      }

      String endpointFirebaseCloudMessaging =
          "https://fcm.googleapis.com/v1/projects/$_fcmProjectId/messages:send";
      final Map<String, dynamic> message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': "New Trip Request From $userName",
            'body':
                "PickUp Location: $pickUp \nDropOff Location: $dropOff"
          },
          'data': {
            'tripID': tripID,
          }
        }
      };
      final http.Response response = await http.post(
        Uri.parse(endpointFirebaseCloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKeyTokenKey'
        },
        body: jsonEncode(message),
      );
      if (response.statusCode == 200) {
        print("Notification sent successfully. ${response.statusCode}");
      } else {
        print(
            'Failed to send notification, ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print("sendNotificationToSelectedDriver error: $e");
    }
  }
}
