// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:btserverhost/loginpassword.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Loginnumber extends StatefulWidget {
  const Loginnumber({super.key});

  @override
  State<Loginnumber> createState() => _LoginnumberState();
}

class _LoginnumberState extends State<Loginnumber> {
  final TextEditingController _numberController = TextEditingController();
  bool isLoading = false;

  List<dynamic> user = [];

  Future<void> login() async {
    final url = Uri.parse('https://app2.1bluetooth.com/api.php?action=phone_loging_statusnew');

    if (_numberController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter mobile number");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _numberController.text,
        }),
      );
      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['message'] == "User loging_status updated to 1") {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('phone', _numberController.text);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Loginpassword()),
            (Route<dynamic> route) => false,
          );
        } else {
          Fluttertoast.showToast(msg: responseData['message']);
        }
      } else {
        Fluttertoast.showToast(msg: 'Invalid Credentials');
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "Something went wrong");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 229, 226, 226),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            textfield(
              'Mobile Number',
              _numberController
            ),
            SizedBox(
              height: 40,
            ),
            Divider(),
            SizedBox(height: 20),
            button('Login', login)
          ],
        ),
      ),
    );
  }
}

textfield(String title, TextEditingController controller) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          color: Color.fromARGB(255, 0, 0, 0)
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(left: 25,right: 25,top: 5),
      child: SizedBox(
        child: TextField(
          controller: controller,
          maxLines: 1,
          decoration: InputDecoration(
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
            )
          )
        ),
      ),
    ),
  ],
);

password(String title, suffixIcon,bool isPassword,TextEditingController controller) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          color: Color.fromARGB(255, 0, 0, 0)
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.only(left: 25,right: 25,top: 5),
      child: TextField(
        maxLines: 1,
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
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
          suffixIcon: suffixIcon
        ),
      ),
    ),
  ],
);

button(String title, VoidCallback onPressed,) => Padding(
  padding: const EdgeInsets.only(left: 25,right: 25),
  child: RawMaterialButton(
    onPressed: onPressed,
    fillColor: const Color.fromARGB(255, 109, 109, 109),
    constraints: BoxConstraints.tightFor(
      width: double.infinity,
      height: 55
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10)
    ),
    child: Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontSize: 16
      ),
    )
  ),
);