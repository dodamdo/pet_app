import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 추가

class PetDetailPage extends StatefulWidget {
  final int petId; // 선택된 펫의 ID

  PetDetailPage({required this.petId});

  @override
  _PetDetailPageState createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  Map<String, dynamic>? petInfo; // 펫 상세 정보 저장 변수
  bool isLoading = true; // 로딩 상태
  String _token = ""; // 토큰 변수

  final Color primaryColor = const Color(0xFFFAE7ED); // 메인 색상 정의

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchPetDetail(); // 토큰 로드 후 펫 상세 정보 가져오기
  }

  Future<void> _loadTokenAndFetchPetDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? ""; // 저장된 토큰 불러오기

    setState(() {
      _token = token;
    });

    fetchPetDetail(); // 토큰을 불러온 후 API 호출
  }

  Future<void> fetchPetDetail() async {
    final response = await http.get(
      //Uri.parse('http://152.67.208.206:8080/api/petDetail?petId=${widget.petId}'),
      Uri.parse('http://10.0.2.2:8080/api/petDetail?petId=${widget.petId}'),
      headers: {
        'Authorization': 'Bearer $_token', // 토큰 포함
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        petInfo = json.decode(response.body); // JSON 파싱 후 저장
        isLoading = false; // 로딩 완료
      });
    } else {
      print('펫 상세 조회 실패: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('펫 정보를 가져오는데 실패했습니다.')),
      );
    }
  }

  String formatPhoneNumber(String ownerId) {
    if (ownerId.length == 8) {
      return '010-${ownerId.substring(0, 4)}-${ownerId.substring(4)}';
    }
    return ownerId;
  }
  void _showImageDialog(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(10),
          color: primaryColor,
          child: Image.network(photoUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('펫 상세 정보'),
          backgroundColor: primaryColor,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (petInfo == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('펫 상세 정보'),
          backgroundColor: primaryColor,
        ),
        body: Center(child: Text('펫 정보를 찾을 수 없습니다.')),
      );
    }

    final String? photoUrl = petInfo!['lastPhoto'] != null
        ? 'https://objectstorage.ap-chuncheon-1.oraclecloud.com/n/ax6zqcd108vv/b/dodam/o/${petInfo!['lastPhoto']}'
        : null; // 이미지 URL 조합

    return Scaffold(
      appBar: AppBar(
        title: Text('${petInfo!['petName']} 상세 정보'),
        backgroundColor: primaryColor,
      ),
      body: Container(
        color: primaryColor.withOpacity(0.3), // 배경 색상 지정
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('이름', petInfo!['petName']),
            _buildDetailRow('품종', petInfo!['petBreed']),
            _buildDetailRow('연락처', formatPhoneNumber(petInfo!['ownerId'].toString())),
            _buildDetailRow('최근 미용 날짜', petInfo!['lastGroomingDate'] ?? "정보 없음"),
            _buildDetailRow('최근 미용 스타일', petInfo!['lastGroomingStyle'] ?? "정보 없음"),
            _buildDetailRow('노쇼 횟수', petInfo!['noShowCount'].toString()),
            SizedBox(height: 20),
            photoUrl != null
                ? GestureDetector(
              onTap: () => _showImageDialog(photoUrl), // 이미지 클릭 이벤트
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            )
                : Text('사진 없음', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
