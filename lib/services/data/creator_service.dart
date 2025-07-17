import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorService {
  static final CreatorService _instance = CreatorService._internal();

  factory CreatorService() => _instance;

  CreatorService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getCreatorID() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('Creator').doc('userID').get();
      if (docSnapshot.exists) {
        final Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        String? uid = data['aaditsingal7859@gmail.com'];
        return uid;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching UID from Firestore: $e');
      return null;
    }
  }
}
