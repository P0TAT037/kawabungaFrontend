import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

late String serverIp;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
String? _error;
class _HomeScreenState extends State<HomeScreen> {
  final serverIpTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
              child: TextField(
                controller: serverIpTextController,
                onChanged: (value) => serverIp = value,
                autofocus: true,
                decoration: InputDecoration(
                    errorText: _error,
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: serverIpTextController.text.isEmpty
                        ? Container(
                            width: 0,
                          )
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => serverIpTextController.clear(),
                            iconSize: 16,
                          ),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    labelText: "server ip"),
              ),
            ),
            Flexible(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {
                   tryConnection(context, "/join");
                },
                child: const Text("Join"),
              ),
            ),
            Flexible(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () {
                     tryConnection(context, "/signin");
                  },
                  child: const Text("Sign In"),
                )),
            Flexible(
                flex: 1,
                child: ElevatedButton(
                  onPressed: ()  {
                     tryConnection(context, "/signup");
                  },
                  child: const Text("Sign Up"),
                )
            ),
          ],
        ),
      ),
    );
  }

  tryConnection(BuildContext context, String path) async {
    try{
      _error = null;
      await http.get(Uri.parse("http://$serverIp/"));
      setState(() {
        Navigator.pushNamed(context, path);
      });
    }catch(E){
      print(E);
      setState(() {
        _error = "server not found on that address";
      });
    }
  }
}
