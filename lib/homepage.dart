// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';

import 'package:btserverhost/loginpassword.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _ch = MethodChannel('bt_server');
  static const _ev = EventChannel('bt_server_stream');

  String _format3(num value) {
    final s = value.toStringAsFixed(3);   // e.g. "1.000" or "0.500"
    final parts = s.split('.');
    final intPart = parts[0].padLeft(3, '0');
    final fracPart = parts[1];
    return '$intPart.$fracPart';
  }

  StreamSubscription? _sub;
  bool _running = false;
  bool _connected = false; // best-effort flag based on incoming events
  String _log = '';

  num? selectedNumber; // <-- defined
  String _status = '';  // optional UI status if you want to show it later

  Future<void> _start() async {
    final perms = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    if (perms.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
      setState(() => _log = 'Permissions denied.');
      return;
    }

    try {
      final ok = await _ch.invokeMethod<bool>('start', {'seconds': 10800}) ?? false;
      if (!ok) {
        setState(() => _log = 'Failed to start server.');
        return;
      }

      await _sub?.cancel();
      _sub = _ev.receiveBroadcastStream().listen((e) {
        if (e is Uint8List) {
          final text = utf8.decode(e, allowMalformed: true);
          if (text.contains('Client connected')) _connected = true;
          if (text.contains('Client disconnected')) _connected = false;
          setState(() => _log = text.startsWith('RX:') ? text : 'RX: $text');
        } else {
          setState(() => _log = 'RX: $e');
        }
      });

      setState(() {
        _running = true;
        _log = 'Server started';
      });
    } on PlatformException catch (e) {
      setState(() => _log = 'Error: ${e.message}');
    }
  }

  Future<void> _stop() async {
    try {
      await _ch.invokeMethod('stop');
    } catch (_) {}
    await _sub?.cancel();
    setState(() {
      _running = false;
      _connected = false;
      _log = 'Server stopped.';
    });
  }

  Future<void> _send(String text) async {
    final payload = Uint8List.fromList(utf8.encode('$text\n'));
    final ok = await _ch.invokeMethod<bool>('send', {'data': payload}) ?? false;
    if (!ok) {
      setState(() => _log = 'Send failed (not connected yet?).');
    } else {
      setState(() => _log = 'TX: $text');
    }
  }

  // Convenience: send any number
  Future<void> _sendNumber(num value) => _send(_format3(value));

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_time');

    final url = Uri.parse('https://app1.1bluetooth.com/api.php?action=logoutnew');

    try {
      final phone = prefs.getString('phone'); // <-- no await

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode == 200) {

        _stop();
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        Fluttertoast.showToast(msg: responseData['message']);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Loginpassword()),
          (Route<dynamic> route) => false,
        );
      } else {
        debugPrint('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  void initState() {
    _start();
    super.initState();
  }

  @override
  void dispose() {
    _stop();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allNumbers = <num>[
      0, 0.5, 1, 1.5, 2, 2.5,
      3, 3.5, 4, 4.5, 5, 6,
      7, 8, 9, 10, 11, 12,
      13, 14, 15, 16, 17, 18,
      19, 20, 25, 30, 35, 40,
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth - 75) / 5;

    final canSend = _running && _connected;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Exit App"),
            content: const Text("Do you want to disconnect and exit?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _stop(); // <-- actually call it
                  Navigator.pop(context, true);
                },
                child: const Text("Exit"),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          _stop();
          Future.delayed(const Duration(milliseconds: 200), () {
            SystemNavigator.pop();
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 50, 50, 50),
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Row(
            children: [
              // RawMaterialButton(
              //   onPressed: _running ? _stop : _start,
              //   fillColor: _running ? Colors.red : Colors.green,
              //   constraints: const BoxConstraints.tightFor(height: 35),
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(10),
              //   ),
              //   child: Padding(
              //     padding: EdgeInsets.symmetric(horizontal: 15),
              //     child: Text(
              //       _running ? 'Stop Server' : 'Start Server',
              //       style: TextStyle(
              //         fontFamily: 'Poppins',
              //         fontSize: 14,
              //         color: Colors.white,
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(width: 12),
              if (_running)
                Text(
                  _connected ? 'Connected' : 'Waiting…',
                  style: TextStyle(
                    color: _connected ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: RawMaterialButton(
                onPressed: _logout,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (selectedNumber != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                selectedNumber.toString(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 60,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  for (int row = 0; row < (allNumbers.length / 5).ceil(); row++)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final index = row * 5 + i;
                          if (index >= allNumbers.length) {
                            return SizedBox(width: buttonWidth);
                          }
                          final val = allNumbers[index];

                          return number(
                            val,
                            () async {
                              setState(() => selectedNumber = val);
                                if (!canSend) {
                                  Fluttertoast.showToast(
                                    msg: 'Not connected yet.',
                                  );
                                return;
                              }
                              await _sendNumber(val);
                            },
                            buttonWidth,
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    selectedNumber = null;
                    _status = "Selection cleared.";
                  });
                },
                fillColor: Colors.green,
                constraints: const BoxConstraints.tightFor(
                  height: 50, width: double.infinity),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // label is derived from num; `onPressed` already checks canSend
  Widget number(num value, VoidCallback onPressed, double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: RawMaterialButton(
        onPressed: onPressed,
        constraints: BoxConstraints.tightFor(
          width: width,
          height: 60,
        ),
        fillColor: const Color.fromARGB(255, 80, 80, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 22,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
