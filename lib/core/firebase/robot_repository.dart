import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_initializer.dart';

class PairedRobot {
  final String robotId; // serial number (primary key)
  final String name;
  final String model;
  final String firmware;
  final String attachment;
  final String pairingToken;
  final DateTime pairedAt;
  final DateTime lastSeenAt;
  final bool isOnline;

  PairedRobot({
    required this.robotId,
    required this.name,
    required this.model,
    required this.firmware,
    required this.attachment,
    required this.pairingToken,
    required this.pairedAt,
    required this.lastSeenAt,
    this.isOnline = false,
  });

  Map<String, dynamic> toMap() => {
        'robotId': robotId,
        'name': name,
        'model': model,
        'firmware': firmware,
        'attachment': attachment,
        'pairingToken': pairingToken,
        'pairedAt': Timestamp.fromDate(pairedAt),
        'lastSeenAt': Timestamp.fromDate(lastSeenAt),
        'isOnline': isOnline,
      };

  factory PairedRobot.fromMap(Map<String, dynamic> m) => PairedRobot(
        robotId: m['robotId'] as String,
        name: m['name'] as String? ?? '',
        model: m['model'] as String? ?? '',
        firmware: m['firmware'] as String? ?? '',
        attachment: m['attachment'] as String? ?? '',
        pairingToken: m['pairingToken'] as String? ?? '',
        pairedAt: (m['pairedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastSeenAt: (m['lastSeenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isOnline: m['isOnline'] as bool? ?? false,
      );
}

class RobotRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _robots(String uid) =>
      _db.collection('users').doc(uid).collection('robots');

  Future<void> upsertRobot(String uid, PairedRobot robot) async {
    if (!FirebaseInitializer.isInitialized) return;
    await _robots(uid).doc(robot.robotId).set(
          robot.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<List<PairedRobot>> getUserRobots(String uid) async {
    if (!FirebaseInitializer.isInitialized) return const [];
    final snap = await _robots(uid).orderBy('pairedAt', descending: true).get();
    return snap.docs.map((d) => PairedRobot.fromMap(d.data())).toList();
  }

  Stream<List<PairedRobot>> watchUserRobots(String uid) {
    if (!FirebaseInitializer.isInitialized) return const Stream.empty();
    return _robots(uid)
        .orderBy('pairedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PairedRobot.fromMap(d.data())).toList());
  }

  Future<void> updatePresence(String uid, String robotId, bool isOnline) async {
    if (!FirebaseInitializer.isInitialized) return;
    await _robots(uid).doc(robotId).set({
      'isOnline': isOnline,
      'lastSeenAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<void> removeRobot(String uid, String robotId) async {
    if (!FirebaseInitializer.isInitialized) return;
    await _robots(uid).doc(robotId).delete();
  }
}
