import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'detail_page.dart';

class PetSearchPage extends StatefulWidget {
  @override
  _PetSearchPageState createState() => _PetSearchPageState();
}

class _PetSearchPageState extends State<PetSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _pets = [];
  List<dynamic> _owners = [];
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

  Future<void> searchPets() async {
    final response = await http.get(
      //Uri.parse('http://10.0.2.2:8080/api/flutterPetSearch?search=${_searchController.text}'),
      Uri.parse('http://152.67.208.206:8080/api/flutterPetSearch?search=${_searchController.text}'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _pets = data['pets'];
        _owners = data['owners'];
      });
    } else {
      print('검색 실패: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 실패: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('검색'),
        backgroundColor: Color(0xFFFAE7ED),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(labelText: '검색어 입력'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: searchPets,
              child: Text('검색'),
            ),
            SizedBox(height: 20),
            Text(
              '검색목록',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _pets.length,
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.pets, size: 40),
                      title: Text('${pet['petName']} (${pet['petBreed']})'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('성별: ${pet['petGender']}, 나이: ${pet['petAge']}'),
                          Text('연락처: ${pet['formattedOwnerId']}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetDetailPage(petId: pet['petId']),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              '추가연락처 목록',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _owners.length,
                itemBuilder: (context, index) {
                  final owner = _owners[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.person, size: 40),
                      title: Text('${owner['petName']}'),
                      subtitle: Text('연락처: ${owner['formattedOwnerId']}'),
                      onTap: () {
                        // 추가 연락처 클릭 시 상세 페이지로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetDetailPage(petId: owner['petId']),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
