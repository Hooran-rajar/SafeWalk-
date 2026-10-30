import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/emergency_contact.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please log in first.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _contacts =>
      _db.collection('users').doc(_uid).collection('contacts');

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('users').doc(_uid).collection('incidents');

  CollectionReference<Map<String, dynamic>> get _journeys =>
      _db.collection('users').doc(_uid).collection('journeys');

  // ==================== EMERGENCY CONTACTS ====================

  Stream<List<EmergencyContact>> watchContacts() {
    return _contacts.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => EmergencyContact.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addContact(EmergencyContact contact) async {
    await _contacts.add(contact.toMap());
  }

  Future<void> updateContact(EmergencyContact contact) async {
    if (contact.id == null) return;

    await _contacts.doc(contact.id).update(contact.toMap());
  }

  Future<void> deleteContact(String id) async {
    await _contacts.doc(id).delete();
  }

  // ==================== INCIDENTS & SOS ====================

  Stream<QuerySnapshot<Map<String, dynamic>>> watchIncidents() {
    return _incidents
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> saveIncident({
    required String description,
    required String location,
    required DateTime createdAt,
    String type = 'sos',
    double? incidentLatitude,
    double? incidentLongitude,
    double? myLocationLatitude,
    double? myLocationLongitude,
  }) async {
    final data = <String, dynamic>{
      'description': description.trim(),
      'location': location,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (incidentLatitude != null && incidentLongitude != null) {
      data['incidentLatitude'] = incidentLatitude;
      data['incidentLongitude'] = incidentLongitude;
      data['incidentMapUrl'] =
          'https://www.google.com/maps/search/?api=1&query=$incidentLatitude,$incidentLongitude';
    }

    if (myLocationLatitude != null && myLocationLongitude != null) {
      data['myLocationLatitude'] = myLocationLatitude;
      data['myLocationLongitude'] = myLocationLongitude;
      data['myLocationMapUrl'] =
          'https://www.google.com/maps/search/?api=1&query=$myLocationLatitude,$myLocationLongitude';
    }

    await _incidents.add(data);
  }

  Future<void> deleteIncident(String id) async {
    await _incidents.doc(id).delete();
  }

  // ==================== JOURNEY HISTORY ====================

  Stream<QuerySnapshot<Map<String, dynamic>>> watchJourneys() {
    return _journeys
        .orderBy('startedAt', descending: true)
        .snapshots();
  }

  Future<String> saveJourney({
    required String destination,
    required String status,
    required DateTime startedAt,
    double? startLatitude,
    double? startLongitude,
    String? startLocationMapUrl,
  }) async {
    final data = <String, dynamic>{
      'destination': destination.trim(),
      'status': status,
      'startedAt': Timestamp.fromDate(startedAt),
      'finishedAt': null,
      'durationSeconds': null,
      'duration': null,
    };

    // Save the starting GPS coordinates and Google Maps URL.
    if (startLatitude != null && startLongitude != null) {
      data['startLatitude'] = startLatitude;
      data['startLongitude'] = startLongitude;
      data['startLocationMapUrl'] = startLocationMapUrl ??
          'https://www.google.com/maps/search/?api=1&query=$startLatitude,$startLongitude';
    }

    final doc = await _journeys.add(data);

    return doc.id;
  }

  Future<void> finishJourney({
    required String id,
    required DateTime finishedAt,
    required Duration duration,
  }) async {
    await _journeys.doc(id).update({
      'status': 'completed',
      'finishedAt': Timestamp.fromDate(finishedAt),
      'durationSeconds': duration.inSeconds,
      'duration': _formatDuration(duration),
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes =
        (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
        (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  Future<void> deleteJourney(String id) async {
    await _journeys.doc(id).delete();
  }
}