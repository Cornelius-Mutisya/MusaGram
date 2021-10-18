import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:musagram/models/user.dart';
import 'package:musagram/pages/activity_feed.dart';
import 'package:musagram/pages/create_account.dart';
import 'package:musagram/pages/profile.dart';
import 'package:musagram/pages/search.dart';
import 'package:musagram/pages/timeline.dart';
// import 'package:musagram/pages/timeline.dart';
import 'package:musagram/pages/upload.dart';

final GoogleSignIn gSignIn = GoogleSignIn();
final storageReference = FirebaseStorage.instance.ref();
final usersReference = FirebaseFirestore.instance.collection("users");
final postsReference = FirebaseFirestore.instance.collection("posts");
final commentsReference = FirebaseFirestore.instance.collection("comments");
final activityFeedReference = FirebaseFirestore.instance.collection("feed");
final followersReference = FirebaseFirestore.instance.collection("followers");
final followingReference = FirebaseFirestore.instance.collection("following");
final timelineReference = FirebaseFirestore.instance.collection("timeline");

final DateTime timestamp = DateTime.now();
Userr currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isSignedin = false;
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    gSignIn.onCurrentUserChanged.listen((gSignInAccount) {
      controllSignIn(gSignInAccount);
    }, onError: (gError) {
      print("Error signing in: " + gError);
    });

    gSignIn.signInSilently(suppressErrors: false).then((gSignInAccount) {
      controllSignIn(gSignInAccount);
    }).catchError((gError) {
      print("Error signing in: " + gError);
    });
  }

  controllSignIn(GoogleSignInAccount signInAccount) async {
    if (signInAccount != null) {
      await saveUserInfoToFireStore();
      setState(() {
        isSignedin = true;
      });
    } else {
      setState(() {
        isSignedin = false;
      });
    }
  }

  saveUserInfoToFireStore() async {
    final GoogleSignInAccount gCurrentUser = gSignIn.currentUser;
    DocumentSnapshot documentSnapshot =
        await usersReference.doc(gCurrentUser.id).get();
    if (!documentSnapshot.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (contect) => CreateAccount()));
      usersReference.doc(gCurrentUser.id).set({
        "id": gCurrentUser.id,
        "profileName": gCurrentUser.displayName,
        "username": username,
        "url": gCurrentUser.photoUrl,
        "email": gCurrentUser.email,
        "bio": "",
        "timestamp": timestamp
      });
      // Make new user their own follower (to include their posts in their timeline)
      await followersReference
          .doc(gCurrentUser.id)
          .collection('userFollowers')
          .doc(gCurrentUser.id)
          .set({});

      documentSnapshot = await usersReference.doc(gCurrentUser.id).get();
    }
    currentUser = Userr.fromDocument(documentSnapshot);
  }

  loginUser() {
    gSignIn.signIn();
  }

  logoutUser() {
    gSignIn.signOut();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
          currentIndex: pageIndex,
          onTap: onTap,
          activeColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.photo_camera,
                size: 35.0,
              ),
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search)),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
          ]),
    );
    // return RaisedButton(
    //   child: Text('Logout'),
    //   onPressed: logout,
    // );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'MusaGram',
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: 90.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: loginUser,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/google_signin_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isSignedin ? buildAuthScreen() : buildUnAuthScreen();
  }
}
