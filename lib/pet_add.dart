import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_page.dart';

class PetAddPage extends StatefulWidget {
  @override
  _PetAddPageState createState() => _PetAddPageState();
}

class _PetAddPageState extends State<PetAddPage> {
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _petBreedController = TextEditingController();
  final TextEditingController _ownerIdController = TextEditingController();
  String _token = "";

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    setState(() {
      _token = token;
    });
  }

  Future<void> _submitPet() async {
    final petData = {
      'petName': _petNameController.text,
      'petBreed': _petBreedController.text,
      'ownerId': _ownerIdController.text,
    };

    final response = await http.post(
      //Uri.parse('http://10.0.2.2:8080/api/petAdd'),
      Uri.parse('http://152.67.208.206/:8080/api/petAdd'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(petData),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('반려동물이 성공적으로 등록되었습니다.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('반려동물 등록 실패: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('반려동물 등록'),
        backgroundColor: Color(0xFFFAE7ED),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _petNameController,
              decoration: InputDecoration(labelText: '반려동물 이름'),
            ),
            TextField(
              controller: _petBreedController,
              decoration: InputDecoration(labelText: '반려동물 품종'),
            ),
            TextField(
              controller: _ownerIdController,
              decoration: InputDecoration(labelText: '연락처'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitPet,
              child: Text('반려동물 등록'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFAE7ED),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
