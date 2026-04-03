import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UploadTask uploadIncidentPhotoWithBytes(String incidentId, Uint8List bytes) {
    final ref = _storage.ref().child('incidents/$incidentId/photo.jpg');
    return ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
  }

  UploadTask uploadIncidentPhotoWithFile(String incidentId, File file) {
    final ref = _storage.ref().child('incidents/$incidentId/photo.jpg');
    return ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
  }

  Future<String> getDownloadURL(String incidentId) async {
    final ref = _storage.ref().child('incidents/$incidentId/photo.jpg');
    return await ref.getDownloadURL();
  }
}
