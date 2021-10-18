import 'package:cloud_firestore/cloud_firestore.dart';

class Userr {
  final String id;
  final String profileName;
  final String username;
  final String url;
  final String email;
  final String bio;

  Userr(
      {this.id,
      this.profileName,
      this.username,
      this.url,
      this.email,
      this.bio});

  factory Userr.fromDocument(DocumentSnapshot doc) {
    return Userr(
      id: doc.id,
      profileName: doc['profileName'],
      username: doc['username'],
      url: doc['url'],
      email: doc['email'],
      bio: doc['bio']
    );
  }
}
