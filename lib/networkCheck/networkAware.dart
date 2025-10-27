import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';

class NetworkAwareWidget extends StatefulWidget {
  final Widget child;

  const NetworkAwareWidget({required this.child, super.key});

  @override
  State<NetworkAwareWidget> createState() => _NetworkAwareWidgetState();
}

class _NetworkAwareWidgetState extends State<NetworkAwareWidget> {
  bool isOnline = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    // Check every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (mounted) {
        setState(() {
          isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        });
        print('net status: $isOnline');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isOnline = false;
        });
        print('net status: $isOnline');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Offline banner at top
          if (!isOnline)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.wifi_off, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'No Internet Connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Main content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}