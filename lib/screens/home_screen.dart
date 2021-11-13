import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;
  const HomeScreen({required this.currentUserId, Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
    );
  }
}