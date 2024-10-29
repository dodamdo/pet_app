import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  String _token = "";
  List<SchEntity> _schedules = [];

  // 색상 옵션
  List<String> colorOptions = [
    'black', 'red', 'gray', 'yellow', 'green', 'blue', 'purple'
  ];

  @override
  void initState() {
    super.initState();
    _loadToken();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? "";
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _schedules
        .where((schedule) => isSameDay(schedule.schDate, day))
        .map((schedule) => Event(schedule.petName))
        .toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
      _searchSchedules(selectedDay);
    }
  }

// 색상 선택 다이얼로그 표시
  void _showColorPickerDialog(BuildContext context, SchEntity schedule) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('색상 선택', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: colorOptions.map((colorName) {
                return GestureDetector(
                  onTap: () {
                    _updateScheduleColor(schedule.schId, colorName);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10), // 항목의 패딩
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _getColorFromString(colorName),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black54, width: 1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            colorName,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }



  Future<void> _searchSchedules(DateTime selectedDay) async {
    final response = await http.get(
      //Uri.parse('http://152.67.208.206:8080/api/reservation?schDate=${selectedDay.toIso8601String().split('T')[0]}'),
      Uri.parse('http://10.0.2.2:8080/api/reservation?schDate=${selectedDay.toIso8601String().split('T')[0]}'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _schedules = data.map((item) => SchEntity.fromJson(item)).toList();
        _selectedEvents.value = _getEventsForDay(_selectedDay);
      });
    } else {
      print('검색 실패: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 실패: ${response.body}')),
      );
    }
  }

  // 색상 업데이트 API 호출
  Future<void> _updateScheduleColor(int schId, String color) async {
    final response = await http.post(
      //Uri.parse('http://152.67.208.206:8080/api/changecolor?schId=$schId&schColor=$color'),
      Uri.parse('http://10.0.2.2:8080/api/changecolor?schId=$schId&schColor=$color'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    print('색상 변경 요청: schId=$schId, schColor=$color');
    if (response.statusCode == 200) {
      _searchSchedules(_selectedDay);
    } else {
      print('색상 변경 실패: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('색상 변경 실패: ${response.body}')),
      );
    }
  }

  // 상세 정보 모달
  void _showScheduleDetail(BuildContext context, SchEntity schedule) {
    final String? photoUrl = schedule.photoUrl.isNotEmpty
        ? 'https://objectstorage.ap-chuncheon-1.oraclecloud.com/n/ax6zqcd108vv/b/dodam/o/${schedule.photoUrl}'
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(schedule.petName),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${schedule.groomingStyle}'),
                const SizedBox(height: 8.0),
                Text('${schedule.schNotes}'),
                const SizedBox(height: 8.0),
                photoUrl != null
                    ? Image.network(
                  photoUrl,
                  height: 200,
                  fit: BoxFit.cover,
                )
                    : Text('사진 없음'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('색상 변경'),
              onPressed: () {
                Navigator.of(context).pop();
                _showColorPickerDialog(context, schedule);
              },
            ),
            TextButton(
              child: Text('닫기'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('달력'),
        backgroundColor: Color(0xFFFAE7ED),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleTextFormatter: (date, locale) {
              return '${date.year}/${date.month.toString().padLeft(2, '0')}';
            },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                return Container(
                  decoration: BoxDecoration(
                    color: schedule.schColor != "black"
                        ? _getColorFromString(schedule.schColor).withOpacity(0.2) // 투명도 적용
                        : Colors.transparent,
                    border: Border(left: BorderSide(
                        color: _getColorFromString(schedule.schColor), width: 4)), // 왼쪽에 색상 테두리
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 8, // 줄의 너비
                      height: double.infinity, // 높이를 꽉 채움
                      color: _getColorFromString(schedule.schColor),
                    ),
                    title: Text('${schedule.petName} (${schedule.ownerId})'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(schedule.schTime ?? '시간 정보 없음'),
                        const SizedBox(height: 4.0),
                        Text('${schedule.groomingStyle}'),
                      ],
                    ),
                    onTap: () {
                      _showScheduleDetail(context, schedule); // 상세 정보 모달
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'gray':
        return Color(0xFFB0B0B0);
      case 'red':
        return Color(0xFFFE90A9);
      case 'yellow':
        return Color(0xFFF5D465);
      case 'green':
        return Color(0xFF69D4A6);
      case 'blue':
        return Color(0xFF7FA9FD);
      case 'purple':
        return Color(0xFFBB8EF5);
      case 'black':
        return Colors.black;
      default:
        return Colors.black;
    }
  }


}

class Event {
  final String title;
  Event(this.title);
}

class SchEntity {
  final int schId;
  final int petId;
  final String petName;
  final String ownerId;
  final DateTime schDate;
  final String schTime;
  final String schColor;
  final String groomingStyle;
  final String paymentMethod;
  final int groomingPrice;
  final String schState;
  final String schNotes;
  final String photoUrl;

  SchEntity({
    required this.schId,
    required this.petId,
    required this.petName,
    required this.ownerId,
    required this.schDate,
    required this.schTime,
    required this.schColor,
    required this.groomingStyle,
    required this.paymentMethod,
    required this.groomingPrice,
    required this.schState,
    required this.schNotes,
    required this.photoUrl,
  });

  factory SchEntity.fromJson(Map<String, dynamic> json) {
    return SchEntity(
      schId: json['schId'] ?? 0,
      petId: json['petId'] ?? 0,
      petName: json['petName'] ?? "",
      ownerId: json['ownerId'] ?? "",
      schDate: json['schDate'] != null ? DateTime.parse(json['schDate']) : DateTime.now(),
      schTime: json['schTime'] ?? "",
      schColor: json['schColor'] ?? "black",
      groomingStyle: json['groomingStyle'] ?? "",
      paymentMethod: json['paymentMethod'] ?? "",
      groomingPrice: json['groomingPrice'] ?? 0,
      schState: json['schState'] ?? ".",
      schNotes: json['schNotes'] ?? ".",
      photoUrl: json['photoUrl'] ?? "",
    );
  }
}
