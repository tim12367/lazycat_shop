import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login page'), centerTitle: true),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
          },
          child: const Text('首頁'),
        ),
      ),
    );
  }
}
