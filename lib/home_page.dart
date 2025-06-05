import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lazycat_shop/token_storage.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lazyCatDio = context.read<ApiService>().getLazyCatDio();
    final tokenStorage = TokenStorage();
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
            var refreshToken = response.data.toString();
            tokenStorage.setRefreshToken(refreshToken);
            final response2 = await lazyCatDio.get('/admin/users');
            log("response2:${response2.data}");
          },
          child: const Text('登入'),
        ),
      ),
    );
  }
}
