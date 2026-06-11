import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../shared/services/storage_service.dart';
import 'login_screen.dart';

import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../navigation/screens/main_navigation_screen.dart';

class AuthWrapperScreen extends StatefulWidget {
  const AuthWrapperScreen({super.key});

  @override
  State<AuthWrapperScreen> createState() => _AuthWrapperScreenState();
}

class _AuthWrapperScreenState extends State<AuthWrapperScreen> {
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    try {
      final token = await StorageService.getToken();

      debugPrint("SAVED TOKEN => $token");

      if (token == null || token.isEmpty || token == "null") {
        if (!mounted) return;

        setState(() {
          isLoggedIn = false;
          isLoading = false;
        });
        return;
      }

      setState(() {
        isLoggedIn = true;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Auth Wrapper Error => $e");

      if (!mounted) return;

      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isLoggedIn) {
      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}
