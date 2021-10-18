import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:musagram/pages/home.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings; 

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusaGram',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
      home: Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

