import 'package:flutter/material.dart';
import 'home.dart';
import 'join.dart';
import 'signup.dart';
import 'signin.dart';

void main() {
  runApp(const Kawabunga());
}

class Kawabunga extends StatelessWidget {
  const Kawabunga({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kawabunga',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/join': (context) => const JoinScreen(),
        '/signin': (context) => const SigninScreen(),
        '/signup': (context) => const SignUpScreen(),
      },
    );
  }
}


