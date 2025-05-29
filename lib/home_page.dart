import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lazyCatDio = context.read<ApiService>().getLazyCatDio();

    return Scaffold(
      appBar: AppBar(title: const Text('Home page'), centerTitle: true),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Navigator.pushNamed(context, '/login'); // 導頁
            final response = await lazyCatDio.post(
              '/login',
              data: {'username': 'test123', 'password': 'dummy'},
            );
          },
          child: const Text('登入'),
        ),
      ),
    );
  }
}
