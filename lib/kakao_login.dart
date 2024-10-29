import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'kakao_main.dart'; // KakaoMain import

class KakaoLogin extends StatefulWidget {
  @override
  _KakaoLoginState createState() => _KakaoLoginState();
}

class _KakaoLoginState extends State<KakaoLogin> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _loginWithKakao() async {
    print('로그인 시도 중...');  // 로그인 시도 로그
    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡으로 로그인 성공');
        // 로그인 성공 시 KakaoMain 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KakaoMain()),
        );
      } catch (error) {
        print('카카오톡으로 로그인 실패: ${error.toString()}'); // 에러 정보 출력

        if (error is PlatformException && error.code == 'CANCELED') {
          // 로그인 취소 시 처리
          return;
        }

        // KakaoTalk에 연결된 계정이 없는 경우 Kakao 계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount();
          print('카카오계정으로 로그인 성공');
          // 로그인 성공 시 KakaoMain 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KakaoMain()),
          );
        } catch (error) {
          print('카카오계정으로 로그인 실패: ${error.toString()}'); // 에러 정보 출력
        }
      }
    } else {
      // KakaoTalk이 설치되지 않은 경우 Kakao 계정으로 로그인
      try {
        await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인 성공');
        // 로그인 성공 시 KakaoMain 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => KakaoMain()),
        );
      } catch (error) {
        print('카카오계정으로 로그인 실패: ${error.toString()}'); // 에러 정보 출력
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kakao Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _loginWithKakao,
          child: Text('카카오 로그인'),
        ),
      ),
    );
  }
}
