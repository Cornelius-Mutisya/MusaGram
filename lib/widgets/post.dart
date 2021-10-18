import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:musagram/models/user.dart';
import 'package:musagram/pages/activity_feed.dart';
import 'package:musagram/pages/comments.dart';
import 'package:musagram/pages/home.dart';
import 'package:musagram/widgets/custom_image.dart';
import 'package:musagram/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String caption;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.caption,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot docc) {
    return Post(
      postId: docc['postId'],
      ownerId: docc['ownerId'],
      username: docc['username'],
      location: docc['location'],
      caption: docc['caption'],
      mediaUrl: docc['mediaUrl'],
      likes: docc['likes'],
    );
  }

  int getLikeCount(likes) {
    // If no likes, return 0
    if (likes == null) {
      return 0;
    }
    int count = 0;
    // If the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        caption: this.caption,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String caption;
  final String mediaUrl;
  Map likes;
  int likeCount;
  bool isLiked;
  bool showHeart = false;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.caption,
    this.mediaUrl,
    this.likes,
    this.likeCount,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: usersReference.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Userr postUser = Userr.fromDocument(snapshot.data);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(postUser.url),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: postUser.id),
            child: Text(
              postUser.username,
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
                  onPressed: () => handleDeletePost(context),
                  icon: Icon(Icons.more_vert),
                )
              : Text(''),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post?"),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          );
        });
  }

  // Note: To delete a post, ownerId and userId MUST be equal, so they can be used interchangeably
  deletePost() async {
    // Delete the post itself
    postsReference
        .doc(ownerId)
        .collection("userPosts")
        .doc(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // Delete uploaded image for the post from storage
    storageReference.child("post_$postId.jpg").delete();
    // Then delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedReference
        .doc(ownerId)
        .collection("feedItems")
        .where('postId', isEqualTo: postId)
        .get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // Then delete all comments
    QuerySnapshot commentsSnapshot = await commentsReference.doc(postId).collection("comments").get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postsReference
          .doc(ownerId)
          .collection("userPosts")
          .doc(postId)
          .update({'likes.$currentUserId': false});

      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsReference
          .doc(ownerId)
          .collection("userPosts")
          .doc(postId)
          .update({'likes.$currentUserId': true});

      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    // Add a notification to the post Owner's activity feed only if like made by OTHER user (to avoid getting notification for your own like)

    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activityFeedReference
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .set({
        "type": "like",
        "username": currentUser.username,
        "userId": currentUser.id,
        "UserProfileImg": currentUser.url,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": timestamp,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedReference
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((doc) => {
                if (doc.exists) {doc.reference.delete()}
              });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: [
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.4),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (context, anim, child) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80.0,
                      color: Colors.red,
                    ),
                  ),
                )
              : Text(""),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 40.0, left: 20.0),
            ),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20.0),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username ",
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: Text(caption)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}

showComments(BuildContext context,
    {String postId, String ownerId, String mediaUrl}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl,
    );
  }));
}
