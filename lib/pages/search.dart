import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musagram/models/user.dart';
import 'package:musagram/pages/activity_feed.dart';
import 'package:musagram/pages/home.dart';
import 'package:musagram/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>
    with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  handleSearch(String str) {
    Future<QuerySnapshot> userss =
        usersReference.where("profileName", isGreaterThanOrEqualTo: str).get();
    // Future<QuerySnapshot> users = usersReference
    //     .where("profileName", isGreaterThanOrEqualTo: str)
    //     .get();
    setState(() {
      searchResultsFuture = userss;
    });
  }

  clearSearch() {
    searchController.clear();
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search for a user...",
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28.0,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: clearSearch,
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  Container buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              "assets/images/search.svg",
              height: orientation == Orientation.portrait ? 300.0 : 200.0,
            ),
            Text(
              "Find Users",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 60.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
        future: searchResultsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> searchUserResults = [];
          snapshot.data.docs.forEach((doccc) {
            Userr eachUser = Userr.fromDocument(doccc);
            UserResult searchResult = UserResult(eachUser);
            searchUserResults.add(searchResult);
          });
          return ListView(
            children: searchUserResults,
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
  
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final Userr eachUser;

  UserResult(this.eachUser);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: eachUser.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(eachUser.url),
              ),
              title: Text(
                eachUser.profileName,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                eachUser.username,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}
