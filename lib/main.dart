import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter SDK 초기화
  KakaoSdk.init(
    nativeAppKey: '81ddd7f8f8dde10459c0652548ce793d',
    javaScriptAppKey: 'f14fd59e578bd71c812f08cde6b876ee',
  );
  print("Kakao SDK initialized successfully");

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
