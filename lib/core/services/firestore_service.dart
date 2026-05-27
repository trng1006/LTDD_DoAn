import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/topic_model.dart';
import '../../models/group_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Operations ---
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toJson());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  // --- Topic Operations ---
  Stream<List<TopicModel>> getTopics() {
    return _db.collection('topics').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TopicModel.fromJson(doc.data())).toList());
  }

  Future<void> addTopic(TopicModel topic) async {
    await _db.collection('topics').add(topic.toJson());
  }

  Future<void> updateTopic(TopicModel topic) async {
    await _db.collection('topics').doc(topic.id).update(topic.toJson());
  }

  // --- Group Operations ---
  Stream<List<GroupModel>> getGroups() {
    return _db.collection('groups').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => GroupModel.fromJson(doc.data())).toList());
  }

  Future<void> createGroup(GroupModel group) async {
    await _db.collection('groups').add(group.toJson());
  }

  Future<void> updateGroup(GroupModel group) async {
    await _db.collection('groups').doc(group.id).update(group.toJson());
  }

  // --- Notification Operations ---
  Future<void> sendNotification(Map<String, dynamic> notification) async {
    await _db.collection('notifications').add({
      ...notification,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}
