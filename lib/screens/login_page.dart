import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/widgets/loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  SharedPreferences? prefs;

  bool isLoading = false;
  bool isLoggedIn = false;

  User? currentUser;

  @override
  void initState() {
    isSignedIn();
    super.initState();
  }

  void isSignedIn() async {
    setState(() {
      isLoading = true;
    });
    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();


    if (isLoggedIn) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  HomeScreen(currentUserId: prefs!.getString('id')!)));
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoading = true;
    });
    var user = await googleSignIn.signIn();

    GoogleSignInAccount googleUser = user!;

    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

    UserCredential firebaseUser =
        await firebaseAuth.signInWithCredential(credential);

    User userr = firebaseUser.user!;

    if (userr != null) {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.user!.uid)
          .get();

      final List<DocumentSnapshot> documents = result.docs;
      if (documents.length == 0) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.user!.uid)
            .set({
          'nickname': firebaseUser.user!.displayName,
          'photoUrl': firebaseUser.user!.photoURL,
          'id': firebaseUser.user!.uid,
          'createdAt': DateTime.now().toString(),
          'chattingWith': null
          // 'pushToken': ''
        });
        currentUser = userr;
        await prefs!.setString('id', firebaseUser.user!.uid);
        await prefs!.setString('nickname', firebaseUser.user!.displayName!);
        await prefs!.setString('photoUrl', firebaseUser.user!.photoURL!);
      } else {
        await prefs!.setString('id', documents[0].get('id'));
        await prefs!.setString('nickname', documents[0].get('nickname'));
        await prefs!.setString('photoUrl', documents[0].get('photoUrl'));
        await prefs!.setString('aboutMe', documents[0].get('aboutMe'));
      }
      var snackBar = SnackBar(content: Text('Sign In Successfully'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      setState(() {
        isLoading = false;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => HomeScreen(
                    currentUserId: firebaseUser.user!.uid,
                  )));
    } else {
      var snackBar = SnackBar(content: Text('Sign In Failed'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: TextButton(
                style: TextButton.styleFrom(
                  primary: Colors.red,
                  textStyle: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () => handleSignIn().catchError((err) {
                      var snackBar = SnackBar(content: Text('Sign In Failed'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      setState(() {
                        isLoading = false;
                      });
                    }),
                child: Text(
                  'SIGN IN With Gmail',
                  style: TextStyle(fontSize: 16),
                )),
          ),
          Positioned(child: isLoading ? Loading() : Container())
        ],
      ),
    );
  }
}
