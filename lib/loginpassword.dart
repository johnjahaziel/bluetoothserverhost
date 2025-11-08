// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:btserverhost/Userprovider.dart';
import 'package:btserverhost/homepage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Loginpassword extends StatefulWidget {
  const Loginpassword({super.key});

  @override
  State<Loginpassword> createState() => _LoginpasswordState();
}

class _LoginpasswordState extends State<Loginpassword> {
  final TextEditingController _passwordController = TextEditingController();
  bool isPassword = true;
  bool isLoading = false;

  List<dynamic> user = [];

  Future<void> login() async {
    final url = Uri.parse('https://app1.1bluetooth.com/api.php?action=user_simple_loginnew');

    if (_passwordController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter password");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone');

    print(phone);

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': _passwordController.text,
        }),
      );
      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['message'] == 'User login successful (simple login)') {
          final String userid = responseData['user_id'].toString();

          if (responseData['status_value'] == 'Active') {
            if (responseData['loging_status'] == 0) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('login_time', DateTime.now().millisecondsSinceEpoch);
              await prefs.setString('userId', userid);

              String? storedUserId = prefs.getString('userId');
              Provider.of<UserProvider>(context, listen: false).setUserid(
                storedUserId ?? userid,
              );

              print('storedUserId: $storedUserId');

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                (Route<dynamic> route) => false,
              );
            } else {
              Fluttertoast.showToast(msg: "Already Logged In");
            }
          } else {
            Fluttertoast.showToast(msg: "Account is not active. Please contact Admin");
          }
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
            password('Password',
              Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          isPassword = !isPassword;
                        });
                      },
                      icon: isPassword ? Icon(
                        FontAwesomeIcons.solidEyeSlash,
                        color: Colors.black,
                        size: 20,
                      ) : Icon(
                        FontAwesomeIcons.solidEye,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
              isPassword,
              _passwordController
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