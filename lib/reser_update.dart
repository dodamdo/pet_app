import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReservationUpdatePage extends StatefulWidget {
  final int reserId;
  final Map<String, dynamic> reservationData;

  ReservationUpdatePage({required this.reserId, required this.reservationData});

  @override
  _ReservationUpdatePageState createState() => _ReservationUpdatePageState();
}

class _ReservationUpdatePageState extends State<ReservationUpdatePage> {
  late TextEditingController _petIdController;
  late TextEditingController _ownerIdController;
  late TextEditingController _petNameController;
  late TextEditingController _reserDateController;
  late TextEditingController _reserTimeController;
  late TextEditingController _groomingStyleController;
  String _selectedColor = 'black';
  String _token = "";
  String? _selectedTime;
  List<String> _timeOptions = ['11:00', '14:00', '16:00', '18:00', '직접 추가'];

  @override
  void initState() {
    super.initState();
    _petIdController = TextEditingController(text: widget.reservationData['petId']?.toString() ?? '');
    _ownerIdController = TextEditingController(text: widget.reservationData['ownerId']?.toString() ?? '');
    _petNameController = TextEditingController(text: widget.reservationData['petName'] ?? '');
    _reserDateController = TextEditingController(text: widget.reservationData['reserDate'] ?? '');
    _reserTimeController = TextEditingController(text: widget.reservationData['reserTime'] ?? '');
    _groomingStyleController = TextEditingController(text: widget.reservationData['reserGroomingStyle'] ?? '');
    _selectedColor = widget.reservationData['reserColor'] ?? 'black';
    _selectedTime = widget.reservationData['reserTime'] ?? '';
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? "";
    });
  }

  Future<void> _updateReservation() async {
    if (_token.isEmpty) return;

    final updatedData = {
      'reserId': widget.reserId,
      'petId': _petIdController.text,
      'ownerId': _ownerIdController.text,
      'petName': _petNameController.text,
      'reserDate': _reserDateController.text,
      'reserTime': _selectedTime == '직접 추가' ? _reserTimeController.text : _selectedTime,
      'reserColor': _selectedColor,
      'reserGroomingStyle': _groomingStyleController.text,
    };

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/reservation/update'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(updatedData),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('예약이 성공적으로 업데이트되었습니다.')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('예약 업데이트 실패: ${response.body}')));
    }
  }

  Future<void> _deleteReservation() async {
    if (_token.isEmpty) return;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/reservation/delete?reserId=${widget.reserId}'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('예약이 성공적으로 삭제되었습니다.')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('예약 삭제 실패: ${response.body}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('예약 수정 / 삭제'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _petIdController,
              decoration: InputDecoration(labelText: '반려동물 ID'),
              readOnly: true,
            ),
            TextField(
              controller: _ownerIdController,
              decoration: InputDecoration(labelText: '소유자 ID'),
              readOnly: true,
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
                  initialDate: DateTime.parse(_reserDateController.text),
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
            TextField(
              controller: _groomingStyleController,
              decoration: InputDecoration(labelText: '미용 스타일'),
            ),
            DropdownButton<String>(
              value: _selectedColor,
              onChanged: (String? newColor) {
                setState(() {
                  _selectedColor = newColor ?? 'black';
                });
              },
              items: <String>['gray', 'red', 'yellow', 'green', 'blue', 'purple', 'black']
                  .map<DropdownMenuItem<String>>((String color) {
                return DropdownMenuItem<String>(
                  value: color,
                  child: Text(color),
                );
              }).toList(),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _updateReservation,
                  child: Text('수정'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _deleteReservation,
                  child: Text('삭제'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
