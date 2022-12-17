import 'dart:io';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'home.dart';

late String code;

class JoinScreen extends StatefulWidget {
  const JoinScreen({Key? key}) : super(key: key);

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _joinCodeTextController = TextEditingController();
  final _deviceNameTextController = TextEditingController();
  String? _error;
  late Widget _screen;
  late final WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _screen = _buildJoinScreen();
  }

  @override
  Widget build(BuildContext context) {
    return _screen;
  }

  _join(){
    _error = null;
    code = _joinCodeTextController.text.trim();
    final name = _deviceNameTextController.text.trim();
    String uri = 'ws://$serverIp/join?code=$code&name=$name';

    try{
      _channel = WebSocketChannel.connect(Uri.parse(uri));
    }catch(e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't connect, something wrong happened")));
    }


    _listenForData();
  }

  _listenForData() async {
    _channel?.stream.listen(
          (data) {
            if(data == "wrong code"){
              setState(() {
                _error = "wrong code";
                _screen = _buildJoinScreen();
              });
            }else{
              setState(() {
                _screen = _buildViewScreen(data);
              });
            }

      },
      onError: (error) {
        setState(() {
          _screen = _buildViewScreen("error receiving data");
          print(error);
        });
      },
    );
  }

  _buildJoinScreen(){
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: TextField(
                  controller: _deviceNameTextController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      labelText: "Device name",
                      prefixIcon: Icon(Icons.devices_rounded),
                  ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                  controller: _joinCodeTextController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      labelText: "Join code",
                      prefixIcon: const Icon(Icons.numbers_rounded),
                      errorText: _error
                  ),
              ),
            ),
            ElevatedButton(onPressed: ()=>_join(), child: const Text("connect"))
          ],
        ),
      ),
    );
  }

  _buildViewScreen(data){
    Widget w =
    (data.runtimeType == String)?
    Text(data)
        :
    Image.memory(data);

    return WillPopScope(
      onWillPop: () async {
        _channel?.sink.close(WebSocketStatus.goingAway, "device disconnected");
        return true;
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                w
            ],
          ),
        ),
      ),
    );
  }
}

