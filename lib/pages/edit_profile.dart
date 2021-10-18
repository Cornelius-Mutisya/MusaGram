import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:musagram/models/user.dart';
import 'package:musagram/pages/home.dart';
import 'package:musagram/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController profileNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  Userr userProfile;
  bool _bioValid = true;
  bool _profileNameValid = true;

  final snackBar = SnackBar(
    content: Text('Profile updated'),
    duration: Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersReference.doc(widget.currentUserId).get();
    userProfile = Userr.fromDocument(doc);

    profileNameController.text = userProfile.profileName;
    bioController.text = userProfile.bio;

    setState(() {
      isLoading = false;
    });
  }

  Column buildProfileNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Profile Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: profileNameController,
          decoration: InputDecoration(
            hintText: "Update Profile Name",
            errorText: _profileNameValid ? null : "Profile Name too short",
          ),
        ),
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update Bio",
            errorText: _profileNameValid ? null : "Bio too long",
          ),
        ),
      ],
    );
  }

  updateProfileData() {
    setState(() {
      profileNameController.text.trim().length < 3 ||
              profileNameController.text.isEmpty
          ? _profileNameValid = false
          : _profileNameValid = true;
      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
    });

    if (_profileNameValid && _bioValid) {
      usersReference.doc(widget.currentUserId).update({
        "profileName": profileNameController.text,
        "bio": bioController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  logout() async {
    await gSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.done,
              size: 30.0,
              color: Colors.green,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: [
                Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage:
                              CachedNetworkImageProvider(userProfile.url),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            buildProfileNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: updateProfileData,
                        child: Text(
                          "Update Profile",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(primary: Colors.grey),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: TextButton.icon(
                          onPressed: logout,
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                          label: Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
