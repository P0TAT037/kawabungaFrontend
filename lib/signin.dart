import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'home.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({Key? key}) : super(key: key);

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final usernameTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  String? _error;
  late bool _obscure;
  late Widget _screen;
  late String _basicAuth;
  String? _inviteCode;
  WebSocketChannel? _channel;
  List? _devices;

  @override
  void initState() {
    super.initState();
    _obscure = true;
    _screen = _buildSigninScreen();
  }

  @override
  Widget build(BuildContext context) {
    return _screen;
  }

  _buildSigninScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: usernameTextController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  labelText: "username",
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
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
                            _screen = _buildSigninScreen();
                          });
                        }),
                    errorText: _error),
                obscureText: _obscure,
                onSubmitted: (value) => _signIn(),
              ),
              const SizedBox(
                height: 35,
              ),
              ElevatedButton(onPressed: _signIn, child: const Text("Sign in"))
            ],
          ),
        ),
      ),
    );
  }

  _buildDashboardScreen() {
    return WillPopScope(
      onWillPop: () async {
        _disconnectAdmin();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("connections"),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.grey, offset: Offset(0, 25), blurRadius: 50)
            ],
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              verticalDirection: VerticalDirection.up,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: OutlinedButton(
                      onPressed: () => _broadcast(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "send to all devices",
                        style: TextStyle(color: Colors.blueAccent),
                      )),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  child: OutlinedButton(
                      onPressed: () => _invite(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("invite")),
                ),
              ]),
        ),
        // ,
        body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _devices == null ? 0 : _devices?.length,
            itemBuilder: (context, i) {
              return _deviceCard("${_devices?[i]}", i);
            }),
      ),
    );
  }

  _deviceCard(String deviceName, index) {
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.blueGrey,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.connected_tv_rounded,
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 12),
            Text(deviceName),
            const Spacer(),
            IconButton(
                onPressed: () {
                  _send(index);
                },
                icon: const Icon(
                  Icons.send_outlined,
                  color: Colors.green,
                )),
            IconButton(
                onPressed: () {
                  _disconnectUser(index);
                },
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                ))
          ],
        ),
      ),
    );
  }

  _signIn() async {
    final username = usernameTextController.text;
    final password = passwordTextController.text;
    _error = null;

    _basicAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';
    late final http.Response response;
    try {
      response = await http.get(Uri.parse("http://$serverIp/signin"),
          headers: <String, String>{"authorization": _basicAuth});
    } catch (E) {
      setState(() {
        _error = "server not found";
        _screen = _buildSigninScreen();
        return;
      });
    }

    print(response.body);
    if (response.body == '-1') {
      setState(() {
        _error = "wrong username or password";
        _screen = _buildSigninScreen();
      });
      return;
    }
    _channel = WebSocketChannel.connect(
        Uri.parse('ws://$serverIp/admin?code=${response.body}'));
    _listenForConnections();
    setState(() {
      _screen = _buildDashboardScreen();
    });
  }

  _listenForConnections() async {
    _channel?.stream.listen((data) {
      setState(() {
        print(data);
        _devices = jsonDecode(data);
        _screen = _buildDashboardScreen();
      });
    });
  }

  _broadcast() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    final imgBytes = await img?.readAsBytes();
    try {
      await http.post(Uri.parse("http://$serverIp/broadcast"),
          headers: <String, String>{"authorization": _basicAuth},
          body: imgBytes);
    } catch (E) {
      print(E);
      setState(() {
        _screen = _buildDashboardScreen();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
          "Something went wrong",
          style: TextStyle(color: Colors.red),
        )));
        return;
      });
    }
  }

  _invite() async {
    if (_inviteCode == null) {
      late final http.Response response;
      try {
        response = await http.get(Uri.parse("http://$serverIp/invite"),
            headers: <String, String>{"authorization": _basicAuth});
      } catch (e) {
        print(e);
        setState(() {
          _screen = _buildDashboardScreen();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
            "Something went wrong",
            style: TextStyle(color: Colors.red),
          )));
          return;
        });
      }
      _inviteCode = response.body;
      Future.delayed(const Duration(minutes: 1), () => _inviteCode = null);
    }

    setState(() {
      _screen = _buildDashboardScreen();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(minutes: 1),
          content: Text("code will last for 1 minute: $_inviteCode"),
          action: SnackBarAction(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("invite code copied to clipboard!"),
              ));
            },
            label: "COPY",
          ),
        ),
      );
    });
  }

  _disconnectUser(userIndex) async {
    try {
      await http.get(Uri.parse("http://$serverIp/disconnect?id=$userIndex"),
          headers: <String, String>{"authorization": _basicAuth});
    } catch (e) {
      print(e);
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
          "Something went wrong while disconnecting device",
          style: TextStyle(color: Colors.red),
        )));
        return;
      });
    }
  }

  _disconnectAdmin() async {
    try {
      await http.get(Uri.parse("http://$serverIp/disconnectAdmin"),
          headers: <String, String>{"authorization": _basicAuth});
    } catch (e) {
      print(e);
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
          "Something went wrong while disconnecting",
          style: TextStyle(color: Colors.red),
        )));
        return;
      });
    }
  }

  _send(userIndex) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    final imgBytes = await img?.readAsBytes();
    try {
      await http.post(Uri.parse("http://$serverIp/send?id=$userIndex"),
          headers: <String, String>{"authorization": _basicAuth},
          body: imgBytes);
    } catch (e) {
      print(e);
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
          "Error, something went wrong while sending",
          style: TextStyle(color: Colors.red),
        )));
        return;
      });
    }
  }
}
