import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _ch = MethodChannel('bt_server');
  static const _ev = EventChannel('bt_server_stream');
  StreamSubscription? _sub;
  bool _running = false;
  String _log = '';
  bool _connected = false; // best-effort flag based on incoming events

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
      final ok = await _ch.invokeMethod<bool>('start', {'seconds': 300}) ?? false;
      if (!ok) {
        setState(() => _log = 'Failed to start server.');
        return;
      }

      await _sub?.cancel();
      _sub = _ev.receiveBroadcastStream().listen((e) {
        // Native side sends both data and logs as bytes; try to decode as UTF-8 text.
        if (e is Uint8List) {
          final text = utf8.decode(e, allowMalformed: true);
          // Heuristic: mark connected if native log mentions it.
          if (text.contains('Client connected')) _connected = true;
          if (text.contains('Client disconnected')) _connected = false;
          setState(() => _log = text.startsWith('RX:')
              ? text
              : 'RX: $text');
        } else {
          setState(() => _log = 'RX: $e');
        }
      });

      setState(() {
        _running = true;
        _log = 'Server started for 5 minutes. Open Serial Bluetooth Terminal and connect.';
      });
    } on PlatformException catch (e) {
      setState(() => _log = 'Error: ${e.message}');
    }
  }

  Future<void> _stop() async {
    await _ch.invokeMethod('stop');
    await _sub?.cancel();
    setState(() {
      _running = false;
      _connected = false;
      _log = 'Server stopped.';
    });
  }

  Future<void> _send(String text) async {
    // Add newline so it shows nicely in Serial Bluetooth Terminal.
    final payload = Uint8List.fromList(utf8.encode('$text\n'));
    final ok = await _ch.invokeMethod<bool>('send', {'data': payload}) ?? false;
    if (!ok) {
      setState(() => _log = 'Send failed (not connected yet?).');
    } else {
      setState(() => _log = 'TX: $text');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _running && _connected; // enable only when a client is connected

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Start/Stop row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
                    onPressed: _start,
                    child: const Text('Start server'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
                    onPressed: _stop,
                    child: const Text('Stop'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Number pad: 1 2 3 4
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final n in ['1', '2', '3', '4'])
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(64, 48)),
                      onPressed: canSend ? () => _send(n) : null,
                      child: Text(n, style: const TextStyle(fontSize: 18)),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              Text(
                canSend ? 'Connected. Tap a number to send.' : (_running ? 'Waiting for client…' : 'Idle.'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_log, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
