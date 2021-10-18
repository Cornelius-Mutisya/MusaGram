import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:musagram/models/user.dart';
import 'package:musagram/pages/home.dart';
import 'package:musagram/widgets/progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final Userr currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  File file;
  final _picker = ImagePicker();
  bool isUploading = false;

  String postId = Uuid().v4();

  handleTakePhoto() async {
    Navigator.pop(context);
    PickedFile pickedFile = await _picker.getImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );

    file = File(pickedFile.path);
    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    PickedFile pickedFile = await _picker.getImage(
      source: ImageSource.gallery,
      maxHeight: 675,
      maxWidth: 960,
    );

    file = File(pickedFile.path);
    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Create Post"),
            children: [
              SimpleDialogOption(
                child: Text("Take Photo"),
                onPressed: handleTakePhoto,
              ),
              SimpleDialogOption(
                child: Text("Choose from Gallery"),
                onPressed: handleChooseFromGallery,
              ),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            "assets/images/upload.svg",
            height: 260.0,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: ElevatedButton(
              child: Text(
                "Upload Image",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.deepOrange,
              ),
              onPressed: () => selectImage(context),
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());

    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));

    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask =
        storageReference.child("post_$postId.jpg").putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask.whenComplete(() => null);
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore({String mediaUrl, String location, String caption}) {
    postsReference
        .doc(widget.currentUser.id)
        .collection("userPosts")
        .doc(postId)
        .set({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "caption": caption,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
        mediaUrl: mediaUrl,
        location: locationController.text,
        caption: captionController.text);
    captionController.clear();
    locationController.clear();

    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: clearImage),
        title: Text(
          "Caption Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          isUploading ? linearProgress() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.4,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.url),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: "Write a caption ...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                "Use Current Location",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea} ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);
    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
