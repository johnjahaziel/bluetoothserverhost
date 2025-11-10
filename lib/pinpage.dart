import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:btserverhost/loginnumber.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pinpage extends StatefulWidget {
  const Pinpage({super.key});

  @override
  State<Pinpage> createState() => _PinpageState();
}

class _PinpageState extends State<Pinpage> {
  final TextEditingController _pinController = TextEditingController();
  bool isPin = true;
  List<String> pin = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPins();
  }

  Future<void> _fetchPins() async {
    final url = Uri.parse("https://app2.1bluetooth.com/api.php?action=get_pinsnew");
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        pin = List<String>.from(data['pins'].map((p) => p['pin']));
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkPin() async {
    final enteredPin = _pinController.text.trim();
    if (pin.contains(enteredPin)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPinVerified', true);
      Fluttertoast.showToast(msg: "Correct PIN");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Loginnumber()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid PIN")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Text(
              'Enter the PIN',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            )
          ),
          Padding(
            padding: const EdgeInsets.only(left: 25,right: 25,top: 20),
            child: TextField(
              controller: _pinController,
              obscureText: isPin,
              decoration: InputDecoration(
                labelText: "PIN",
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Color(0xff919EAB)
                  )
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Color(0xff919EAB)
                  )
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPin ? FontAwesomeIcons.solidEyeSlash : FontAwesomeIcons.solidEye,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => isPin = !isPin);
                  },
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 40),
          button('Submit', _checkPin)
        ],
      ),
    );
  }
}