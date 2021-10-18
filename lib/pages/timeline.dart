import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:musagram/models/user.dart';
import 'package:musagram/pages/home.dart';
import 'package:musagram/pages/search.dart';
import 'package:musagram/widgets/header.dart';
import 'package:musagram/widgets/post.dart';
import 'package:musagram/widgets/progress.dart';
// import 'package:musagram/widgets/progress.dart';

class Timeline extends StatefulWidget {
  final Userr currentUser;

  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineReference
        .doc(widget.currentUser.id)
        .collection("timelinePosts")
        .orderBy("timestamp", descending: true)
        .get();
    List<Post> posts =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();

    setState(() {
      this.posts = posts;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingReference
        .doc(currentUser.id)
        .collection('userFollowing')
        .get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(
        children: posts,
      );
    }
  }

  buildUsersToFollow() {
    return StreamBuilder(
      stream: usersReference
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.docs.forEach((doc) {
          Userr user = Userr.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool isFollowingUser = followingList.contains(user.id);
          // Remove auth user from recommended list
          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          }
        });
        return Container(
          color: Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                      size: 30.0,
                    ),
                    SizedBox(
                      width: 8.0,
                    ),
                    Text(
                      "People you may know",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(children: userResults),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
