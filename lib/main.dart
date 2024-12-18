import 'dart:io';

import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  try {
    await dotenv.load(fileName: "assets/.env");
    if (dotenv.env.containsKey('KAKAO_NATIVE_APP_KEY')) {
      print("환경 변수 로드 성공!");
      print("KAKAO_NATIVE_APP_KEY: ${dotenv.env['KAKAO_NATIVE_APP_KEY']}");
    } else {
      throw Exception('환경 변수 KAKAO_NATIVE_APP_KEY 가 없습니다.');
    }
  } catch (e) {
    print("환경 변수 로드 실패: $e");
    return;
  }


  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? 'YOUR_NATIVE_APP_KEY',
    javaScriptAppKey: dotenv.env['KAKAO_JAVASCRIPT_APP_KEY'] ?? 'YOUR_JS_APP_KEY',
  );

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
      home: LoginPage(),
    );
  }
}
