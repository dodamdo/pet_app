import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'reser_daily.dart'; // reser_daily.dart 파일 임포트
import 'package:intl/intl.dart';

class ReserMain extends StatefulWidget {
  @override
  _ReservationCalendarPageState createState() => _ReservationCalendarPageState();
}

class _ReservationCalendarPageState extends State<ReserMain> {
  String _token = "";
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _dailyReservationsMap = {};

  @override
  void initState() {
    super.initState();
    _loadToken();

  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? "";
    });

    // 토큰이 로드된 후 예약 데이터를 가져옵니다.
    if (_token.isNotEmpty) {
      _fetchMonthlyReservations(DateTime.now());
      _selectedDay = DateTime.now(); // 현재 날짜로 선택된 날짜를 초기화합니다.
    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('토큰을 불러오는 데 실패했습니다.')),
      );
    }
  }

  Future<void> _fetchMonthlyReservations(DateTime date) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/reservations/monthly?year=${date.year}&month=${date.month}'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      setState(() {
        _dailyReservationsMap = data.map((key, value) {
          return MapEntry(DateTime.parse(key), List<Map<String, dynamic>>.from(value));
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('월별 예약 데이터를 불러오는 데 실패했습니다: ${response.body}')),
      );
    }
  }

  Future<void> _fetchDailyReservations(DateTime date) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/reservations/daily?date=$formattedDate'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      List<Map<String, dynamic>> dailyReservations = data
          .map((res) => Map<String, dynamic>.from(res))
          .toList()
        ..sort((a, b) => a['reserTime'].compareTo(b['reserTime']));

      // 예약 내역을 포함한 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReserDailyPage(
            selectedDate: date,
            dailyReservations: dailyReservations,
          ),
        ),
      ).then((_) {

        _fetchMonthlyReservations(date);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일일 예약 데이터를 불러오는 데 실패했습니다: ${response.body}')),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _fetchDailyReservations(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('예약 달력'),
        backgroundColor: Color(0xFFFAE7ED),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _fetchMonthlyReservations(focusedDay);
            },
            onDaySelected: _onDaySelected,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                List<Map<String, dynamic>> reservations = _dailyReservationsMap[DateTime(day.year, day.month, day.day)] ?? [];
                int displayedCount = reservations.length > 6 ? 6 : reservations.length;
                int overflowCount = reservations.length > 6 ? reservations.length - 6 : 0;

                return Container(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(day.day.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        height: 1,
                        color: Colors.black, // 밑줄 색상
                      ),
                      // 예약 목록을 추가
                      if (displayedCount > 0)
                        ...reservations.take(displayedCount).map((res) {
                          final String reserColor = res['reserColor'] ?? 'black';
                          return Container(
                            color: _getColorFromString(reserColor).withOpacity(0.2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  color: _getColorFromString(reserColor),
                                  width: 3,
                                  height: 10,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  res['reserTime'],
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        }),
                      if (overflowCount > 0)
                        Text('+${overflowCount}', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  alignment: Alignment.center,
                  child: Text(day.day.toString()),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                List<Map<String, dynamic>> reservations = _dailyReservationsMap[DateTime(day.year, day.month, day.day)] ?? [];
                int displayedCount = reservations.length > 6 ? 6 : reservations.length;
                int overflowCount = reservations.length > 6 ? reservations.length - 6 : 0;

                return Container(
                  alignment: Alignment.topLeft, // 상단 정렬
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(day.day.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        height: 1,
                        color: Colors.black, // 밑줄 색상
                      ),
                      // 예약 목록을 추가
                      if (displayedCount > 0)
                        ...reservations.take(displayedCount).map((res) {
                          final String reserColor = res['reserColor'] ?? 'black';
                          return Container(
                            color: _getColorFromString(reserColor).withOpacity(0.2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  color: _getColorFromString(reserColor),
                                  width: 3,
                                  height: 10,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  res['reserTime'],
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        }),

                      if (overflowCount > 0)
                        Text('+${overflowCount}', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                );
              },
            ),
            rowHeight: 130.0,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // 색상 문자열을 색상 코드로 변환하는 함수
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
        return Colors.black; // 기본값
    }
  }
}
