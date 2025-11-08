import 'package:btserverhost/Userprovider.dart';
import 'package:btserverhost/homepage.dart';
import 'package:btserverhost/loginpassword.dart';
import 'package:btserverhost/pinpage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId') ?? '';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider()..setUserid(userId)
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _isPinVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isPinVerified') ?? false;
  }

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt('login_time');
    return loginTime != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isPinVerified(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          if (snapshot.hasData && snapshot.data == true) {
            // PIN verified already → go to login/auth check
            return FutureBuilder<bool>(
              future: _isLoggedIn(),
              builder: (context, loginSnapshot) {
                if (loginSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  if (loginSnapshot.hasData && loginSnapshot.data == true) {
                    return const HomePage();
                  } else {
                    return const Loginpassword();
                  }
                }
              },
            );
          } else {
            // First time → Ask for PIN
            return const Pinpage();
          }
        }
      },
    );
  }
}
