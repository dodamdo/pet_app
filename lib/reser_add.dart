import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReservationAddPage extends StatefulWidget {
  final DateTime? selectedDate;

  ReservationAddPage({Key? key, this.selectedDate}) : super(key: key);

  @override
  _ReservationAddPageState createState() => _ReservationAddPageState();
}

class _ReservationAddPageState extends State<ReservationAddPage> {
  final TextEditingController _petSearchController = TextEditingController();
  final TextEditingController _petIdController = TextEditingController();
  final TextEditingController _ownerIdController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _reserDateController = TextEditingController();
  final TextEditingController _reserTimeController = TextEditingController();
  final TextEditingController _groomingStyleController = TextEditingController();

  String _token = "";
  String _selectedColor = 'black';
  String? _selectedTime;
  List<String> _timeOptions = ['11:00', '14:00', '16:00', '18:00', '직접 추가'];
  List<dynamic> _petSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadToken();
    _reserDateController.text = widget.selectedDate?.toIso8601String().split('T').first ?? '';

    _petSearchController.addListener(() {
      _searchPet(_petSearchController.text);
    });
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    setState(() {
      _token = token;
    });
  }

  Future<void> _searchPet(String search) async {
    if (search.length < 1) {
      setState(() {
        _petSuggestions.clear();
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/checkpet?search=$search'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _petSuggestions = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('반려동물 검색 실패: ${response.body}')),
      );
    }
  }

  Future<void> _submitReservation() async {
    final reservationData = {
      'petId': _petIdController.text,
      'ownerId': _ownerIdController.text,
      'petName': _petNameController.text,
      'reserDate': _reserDateController.text,
      'reserTime': _selectedTime == '직접 추가' ? _reserTimeController.text : _selectedTime,
      'reserColor': _selectedColor,
      'reserGroomingStyle': _groomingStyleController.text,
    };

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/reseradd'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(reservationData),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예약이 성공적으로 등록되었습니다.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('예약 등록 실패: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새 예약 추가'),
        backgroundColor: Color(0xFFFAE7ED),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _petSearchController,
              decoration: InputDecoration(labelText: '반려동물 검색'),
            ),
            if (_petSuggestions.isNotEmpty)
              Container(
                height: 100,
                child: ListView.builder(
                  itemCount: _petSuggestions.length,
                  itemBuilder: (context, index) {
                    final pet = _petSuggestions[index];
                    return ListTile(
                      title: Text(pet['petName'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('연락처: ${pet['ownerId']?.toString() ?? ''}'),
                          Text('품종: ${pet['petBreed'] ?? ''}'),
                        ],
                      ),
                      onTap: () {
                        _petIdController.text = pet['petId']?.toString() ?? '';
                        _ownerIdController.text = pet['ownerId']?.toString() ?? '';
                        _petNameController.text = pet['petName']?.toString() ?? '';
                        _petSearchController.clear(); // 검색 필드 초기화
                        setState(() {
                          _petSuggestions.clear();
                        });
                      },
                    );
                  },
                ),
              ),
            TextField(
              controller: _petIdController,
              decoration: InputDecoration(labelText: '반려동물 ID'),
              enabled: false,
            ),
            TextField(
              controller: _ownerIdController,
              decoration: InputDecoration(labelText: '연락처'),
            ),
            TextField(
              controller: _petNameController,
              decoration: InputDecoration(labelText: '반려동물 이름'),
            ),
            TextField(
              controller: _reserDateController,
              decoration: InputDecoration(labelText: '예약 날짜'),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: widget.selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _reserDateController.text = pickedDate.toIso8601String().split('T').first;
                  });
                }
              },
              readOnly: true,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('예약 시간 선택'),
                DropdownButton<String>(
                  hint: Text('시간 선택'),
                  value: _selectedTime,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTime = newValue;
                    });
                  },
                  items: _timeOptions.map<DropdownMenuItem<String>>((String time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                ),
                if (_selectedTime == '직접 추가')
                  TextField(
                    controller: _reserTimeController,
                    decoration: InputDecoration(labelText: '예약 시간 직접 입력'),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('예약 색상 선택'),
                Wrap(
                  spacing: 8.0,
                  children: <String>[
                    'gray', 'red', 'yellow', 'green', 'blue', 'purple', 'black'
                  ].map((String color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: getColorFromString(color),
                          border: Border.all(
                            color: _selectedColor == color ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            TextField(
              controller: _groomingStyleController,
              decoration: InputDecoration(labelText: '미용 스타일'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitReservation,
              child: Text('예약 등록'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFAE7ED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getColorFromString(String color) {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'black':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}
