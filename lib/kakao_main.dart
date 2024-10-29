import 'package:flutter/material.dart';

class KakaoMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kakao Main'),
      ),
      body: Center(
        child: Text('카카오 로그인 성공!'),
      ),
    );
  }
}
