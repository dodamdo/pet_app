import 'package:flutter/material.dart';
import 'reser_add.dart';
import 'reser_update.dart';

class ReserDailyPage extends StatefulWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> dailyReservations;

  ReserDailyPage({required this.selectedDate, required this.dailyReservations});

  @override
  _ReserDailyPageState createState() => _ReserDailyPageState();
}

class _ReserDailyPageState extends State<ReserDailyPage> {
  late List<Map<String, dynamic>> dailyReservations;

  @override
  void initState() {
    super.initState();
    dailyReservations = widget.dailyReservations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedDate.year}-${widget.selectedDate.month}-${widget.selectedDate.day} 예약 내역'),
        backgroundColor: Color(0xFFFAE7ED),
      ),
      body: Column(
        children: [
          Expanded(
            child: dailyReservations.isEmpty
                ? Center(child: Text('예약 내역이 없습니다.', style: TextStyle(fontSize: 16)))
                : ListView.builder(
              itemCount: dailyReservations.length,
              itemBuilder: (context, index) {
                final reservation = dailyReservations[index];
                final String reserColor = reservation['reserColor'] ?? 'black';
                return Container(
                  decoration: BoxDecoration(
                    color: _getColorFromString(reserColor).withOpacity(0.2),
                    border: Border(
                      left: BorderSide(
                        color: _getColorFromString(reserColor),
                        width: 20,
                      ),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      '시간 : ${reservation['reserTime']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('id: ${reservation['reserId']}'),
                        Text('반려동물: ${reservation['petName']}'),
                        Text('미용 스타일: ${reservation['reserGroomingStyle'] ?? '정보 없음'}'),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReservationUpdatePage(
                            reserId: reservation['reserId'],
                            reservationData: reservation,
                          ),
                        ),
                      );

                      if (result == true) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReservationAddPage(selectedDate: widget.selectedDate),
                ),
              ).then((_) {
                // 예약 추가 후 데일리 페이지를 다시 불러옵니다.
                Navigator.pop(context, true);
              });
            },
            child: Text('예약 추가하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFAE7ED),
            ),
          ),
        ],
      ),
    );
  }

  void _loadReservations() {
    setState(() {
    });
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
        return Colors.black;
    }
  }
}
