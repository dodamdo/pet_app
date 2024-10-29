import 'package:flutter/material.dart';
import 'login_page.dart'; // 로그인 페이지 가져오기

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(), // 로그인 페이지를 기본 화면으로 설정
    );
  }
}
