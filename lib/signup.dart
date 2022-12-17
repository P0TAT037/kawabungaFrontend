import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final usernameTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  String? error;
  late bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: usernameTextController,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    labelText: "username",
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    errorText: error),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(
                height: 30,
              ),
              TextField(
                controller: passwordTextController,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    labelText: "password",
                    prefixIcon: const Icon(Icons.password_rounded),
                    suffixIcon: IconButton(
                        icon: _obscure
                            ? const Icon(Icons.visibility_off_rounded)
                            : const Icon(Icons.visibility_rounded),
                        onPressed: () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        }),
                    errorText: passwordTextController.text.isEmpty
                        ? "password cannot be empty"
                        : null),
                obscureText: _obscure,
                onChanged: (value) => setState(() {}),
                onSubmitted: (value) => _signup(),
              ),
              const SizedBox(
                height: 35,
              ),
              ElevatedButton(onPressed: _signup, child: const Text("Sign up"))
            ],
          ),
        ),
      ),
    );
  }

  _signup() async {
    final uri = Uri.parse('http://$serverIp/signup');
    if(passwordTextController.text.isEmpty){
      return;
    }
    var data = <String, String>{
      "username": usernameTextController.text,
      "password": passwordTextController.text,
    };

    final response = await http.post(uri, body: data);

    if (response.body == "Error") {
      setState(() {
        error = "this username already exists";
      });
    } else {
      setState(() {
        error = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("User added successfully, you can now sign in")));
      });
    }
  }
}
