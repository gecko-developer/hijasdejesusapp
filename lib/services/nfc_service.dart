import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NFCService {
  static bool _isAvailable = false;
  static bool get isAvailable => _isAvailable;

  // Initialize NFC
  static Future<bool> initialize() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      _isAvailable = availability == NFCAvailability.available;
      return _isAvailable;
    } catch (e) {
      print('❌ NFC initialization failed: $e');
      return false;
    }
  }

  // Start NFC session to read RFID card
  static Future<String?> scanRFIDCard() async {
    if (!_isAvailable) {
      throw Exception('NFC is not available on this device');
    }

    try {
      // Start NFC polling
      final tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Tap your RFID card to the phone",
      );

      if (tag.id.isNotEmpty) {
        // Format the UID according to your specification
        final formattedUID = _formatRFIDCard(tag.id);
        return formattedUID;
      }

      return null;
    } catch (e) {
      print('❌ NFC scanning failed: $e');
      rethrow;
    } finally {
      // Always finish the NFC session
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print('❌ Error finishing NFC session: $e');
      }
    }
  }

  // Format RFID card according to specification
  static String _formatRFIDCard(String uid) {
    // Example: F692D605 -> CARD_F692D605
    String formattedUID = uid.trim();
    formattedUID = formattedUID.toUpperCase();
    formattedUID = formattedUID.replaceAll(":", "");
    formattedUID = formattedUID.replaceAll(" ", "");
    formattedUID = formattedUID.replaceAll("-", "");
    
    if (!formattedUID.startsWith('CARD_')) {
      formattedUID = "CARD_$formattedUID";
    }
    
    return formattedUID;
  }

  // Stop NFC session
  static Future<void> stopSession() async {
    try {
      await FlutterNfcKit.finish();
    } catch (e) {
      print('❌ Error stopping NFC session: $e');
    }
  }

  // Dispose NFC resources
  static void dispose() {
    try {
      FlutterNfcKit.finish();
    } catch (e) {
      print('❌ Error disposing NFC: $e');
    }
  }
}
