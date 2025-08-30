import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RFIDCard {
  final String id;
  final String rfidId;
  final String userId;
  final String userEmail;
  final DateTime linkedAt;
  final DateTime updatedAt;

  RFIDCard({
    required this.id,
    required this.rfidId,
    required this.userId,
    required this.userEmail,
    required this.linkedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rfidId': rfidId,
      'userId': userId,
      'userEmail': userEmail,
      'linkedAt': Timestamp.fromDate(linkedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory RFIDCard.fromMap(Map<String, dynamic> map, String documentId) {
    return RFIDCard(
      id: documentId,
      rfidId: map['rfidId'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      linkedAt: (map['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class RFIDService {
  static final RFIDService _instance = RFIDService._internal();
  factory RFIDService() => _instance;
  RFIDService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔗 Link RFID card to current user (only one card per user)
  Future<void> linkRFIDCard(String rfidId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final formattedRfidId = _formatRFIDId(rfidId);
      
      // Check if user already has an RFID card linked
      final userCardQuery = await _firestore
          .collection('rfid_cards')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (userCardQuery.docs.isNotEmpty) {
        throw Exception('You already have an RFID card linked. Please unlink your current card first.');
      }

      // Check if this RFID card is already linked to another user
      final cardQuery = await _firestore
          .collection('rfid_cards')
          .where('rfidId', isEqualTo: formattedRfidId)
          .get();

      if (cardQuery.docs.isNotEmpty) {
        final existingCard = RFIDCard.fromMap(cardQuery.docs.first.data(), cardQuery.docs.first.id);
        if (existingCard.userId != user.uid) {
          throw Exception('This RFID card is already linked to another user.');
        } else {
          throw Exception('This RFID card is already linked to your account.');
        }
      }

      // Create new RFID card document
      final rfidCard = RFIDCard(
        id: '', // Will be set by Firestore
        rfidId: formattedRfidId,
        userId: user.uid,
        userEmail: user.email ?? '',
        linkedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('rfid_cards').add(rfidCard.toMap());
      
      print('✅ RFID card $formattedRfidId linked to user ${user.email}');
    } catch (e) {
      print('❌ Error linking RFID card: $e');
      rethrow;
    }
  }

  /// 🔓 Unlink current user's RFID card
  Future<void> unlinkCurrentUserRFIDCard() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final userCardQuery = await _firestore
          .collection('rfid_cards')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (userCardQuery.docs.isEmpty) {
        throw Exception('No RFID card is linked to your account.');
      }

      // Delete the RFID card document
      for (final doc in userCardQuery.docs) {
        await doc.reference.delete();
      }

      print('✅ RFID card unlinked from user ${user.email}');
    } catch (e) {
      print('❌ Error unlinking RFID card: $e');
      rethrow;
    }
  }

  /// 📖 Get current user's linked RFID card
  Future<RFIDCard?> getCurrentUserRFIDCard() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userCardQuery = await _firestore
          .collection('rfid_cards')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userCardQuery.docs.isEmpty) return null;

      return RFIDCard.fromMap(
        userCardQuery.docs.first.data(),
        userCardQuery.docs.first.id,
      );
    } catch (e) {
      print('❌ Error getting user RFID card: $e');
      return null;
    }
  }

  /// 🔍 Check if user has an RFID card linked
  Future<bool> hasRFIDCardLinked() async {
    final card = await getCurrentUserRFIDCard();
    return card != null;
  }

  /// 🆔 Find user by RFID card ID
  Future<String?> getUserIdByRFIDCard(String rfidId) async {
    try {
      final formattedRfidId = _formatRFIDId(rfidId);
      
      final cardQuery = await _firestore
          .collection('rfid_cards')
          .where('rfidId', isEqualTo: formattedRfidId)
          .limit(1)
          .get();

      if (cardQuery.docs.isEmpty) return null;

      final rfidCard = RFIDCard.fromMap(cardQuery.docs.first.data(), cardQuery.docs.first.id);
      return rfidCard.userId;
    } catch (e) {
      print('❌ Error finding user by RFID card: $e');
      return null;
    }
  }

  /// 🔄 Update RFID card with new card ID (replace existing)
  Future<void> updateRFIDCard(String newRfidId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    try {
      final formattedRfidId = _formatRFIDId(newRfidId);
      
      // Check if the new RFID card is already linked to another user
      final cardQuery = await _firestore
          .collection('rfid_cards')
          .where('rfidId', isEqualTo: formattedRfidId)
          .get();

      if (cardQuery.docs.isNotEmpty) {
        final existingCard = RFIDCard.fromMap(cardQuery.docs.first.data(), cardQuery.docs.first.id);
        if (existingCard.userId != user.uid) {
          throw Exception('This RFID card is already linked to another user.');
        }
      }

      // Get current user's RFID card
      final userCardQuery = await _firestore
          .collection('rfid_cards')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (userCardQuery.docs.isEmpty) {
        // No existing card, create new one
        await linkRFIDCard(newRfidId);
      } else {
        // Update existing card
        final docRef = userCardQuery.docs.first.reference;
        await docRef.update({
          'rfidId': formattedRfidId,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      print('✅ RFID card updated to $formattedRfidId for user ${user.email}');
    } catch (e) {
      print('❌ Error updating RFID card: $e');
      rethrow;
    }
  }

  /// 🗑️ Delete all RFID data for user (for account deletion)
  Future<void> deleteUserRFIDData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userCardQuery = await _firestore
          .collection('rfid_cards')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in userCardQuery.docs) {
        await doc.reference.delete();
      }

      print('✅ All RFID data deleted for user ${user.email}');
    } catch (e) {
      print('❌ Error deleting user RFID data: $e');
      rethrow;
    }
  }

  /// 🔧 Format RFID ID to consistent format
  String _formatRFIDId(String input) {
    String formatted = input.trim().toUpperCase();
    formatted = formatted.replaceAll(RegExp(r'[^A-F0-9]'), '');
    
    if (!formatted.startsWith('CARD_')) {
      formatted = 'CARD_$formatted';
    }
    
    return formatted;
  }

  /// 📊 Get RFID card statistics (for admin)
  Future<Map<String, dynamic>> getRFIDCardStats() async {
    try {
      final allCardsQuery = await _firestore.collection('rfid_cards').get();
      
      return {
        'totalCards': allCardsQuery.docs.length,
        'recentlyAdded': allCardsQuery.docs
            .where((doc) {
              final card = RFIDCard.fromMap(doc.data(), doc.id);
              return card.linkedAt.isAfter(DateTime.now().subtract(Duration(days: 7)));
            })
            .length,
      };
    } catch (e) {
      print('❌ Error getting RFID stats: $e');
      return {'totalCards': 0, 'recentlyAdded': 0};
    }
  }
}
