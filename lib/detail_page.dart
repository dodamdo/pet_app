import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/photo_update.dart';

class PetDetailPage extends StatefulWidget {
  final int petId; // 선택된 펫의 ID

  PetDetailPage({required this.petId});

  @override
  _PetDetailPageState createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  Map<String, dynamic>? petInfo;
  List<dynamic>? schedules;
  bool isLoading = true;
  String _token = "";

  final Color primaryColor = const Color(0xFFFAE7ED);

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchPetDetail();
  }

  Future<void> _loadTokenAndFetchPetDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    setState(() {
      _token = token;
    });

    fetchPetDetail();
  }



  Future<void> fetchPetDetail() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(
      Uri.parse('http://152.67.208.206:8080/api/petDetail?petId=${widget.petId}'),
      //Uri.parse('http://10.0.2.2:8080/api/petDetail?petId=${widget.petId}'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body); // JSON 파싱
      setState(() {
        petInfo = data['petInfo']; // petInfo 저장
        schedules = data['schedules']; // schedules 저장
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


  Widget _buildSchedules() {
    if (schedules == null || schedules!.isEmpty) {
      return Text('스케줄 정보가 없습니다.', style: TextStyle(color: Colors.grey));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: schedules!.length,
      itemBuilder: (context, index) {
        final schedule = schedules![index];

        final String? schedulePhotoUrl = schedule['photoUrl'] != null && schedule['photoUrl'].isNotEmpty
            ? 'https://objectstorage.ap-chuncheon-1.oraclecloud.com/n/ax6zqcd108vv/b/dodam/o/${schedule['photoUrl']}'
            : null;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: schedulePhotoUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                schedulePhotoUrl,
                width: 60, // 이미지 너비
                height: 60, // 이미지 높이
                fit: BoxFit.cover, // 이미지 잘림 방지
              ),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: Colors.grey[300], // 기본 배경색
                child: Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            title: Text(schedule['schDate'] ?? '날짜 없음'),
            subtitle: Text(
              '${schedule['groomingStyle'] ?? '스타일 정보 없음'}',
            ),
            trailing: Text('₩${schedule['groomingPrice']}'),
            onTap: () {
              if (schedulePhotoUrl != null) {
                _showFullScreenImage(
                  schedulePhotoUrl,
                  schedule['schNotes'] ?? '메모 없음',
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoUpdatePage(
                      schId: schedule['schId'], // 스케줄 ID
                      petId: widget.petId, // 펫 ID
                      token: _token, // 인증 토큰
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    fetchPetDetail();
                  }
                });
              }
            },


          ),
        );
      },
    );
  }

  void _showFullScreenImage(String imageUrl, String notes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  notes,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
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
      body: SingleChildScrollView(
        child: Container(
          color: primaryColor.withOpacity(0.3), // 배경 색상 지정
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('이름', petInfo!['petName']),
              _buildDetailRow('품종', petInfo!['petBreed']),
              _buildDetailRow('무게', petInfo!['petWeight'] ?? "정보 없음"),
              _buildDetailRow('연락처', formatPhoneNumber(petInfo!['ownerId'].toString())),
              _buildDetailRow('노쇼 횟수', petInfo!['noShowCount'].toString()),

              SizedBox(height: 20),
              Text(
                '스케줄 정보',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildSchedules(), // 스케줄 리스트 추가
            ],
          ),
        ),
      ),
    );
  }
}
