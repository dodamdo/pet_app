import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SalesCalculationPage extends StatefulWidget {
  @override
  _SalesCalculationPageState createState() => _SalesCalculationPageState();
}

class _SalesCalculationPageState extends State<SalesCalculationPage> {
  String? _startDate;
  String? _endDate;
  Map<String, int> _result = {};

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  Future<void> _calculateSales() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시작 날짜와 종료 날짜를 모두 선택하세요.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8080/api/calculate?startDate=$_startDate&endDate=$_endDate'),
          //'http://152.67.208.206:8080/api/calculate?startDate=$_startDate&endDate=$_endDate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _result = Map<String, int>.from(json.decode(response.body));
      });
    } else {
      print('계산 실패: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계산 실패: ${response.body}')),
      );
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final formattedDate = picked.toIso8601String().split('T').first;
      setState(() {
        if (isStartDate) {
          _startDate = formattedDate;
          _startDateController.text = formattedDate;
        } else {
          _endDate = formattedDate;
          _endDateController.text = formattedDate;
        }
      });
    }
  }

  String _formatCurrency(int value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardTotal = _result['card_total'] ?? 0;
    final cashTotal = _result['cash_total'] ?? 0;
    final accountTotal = _result['account_total'] ?? 0;
    final totalAmount = _result['total_amount'] ?? 0;
    final vat = (cardTotal * 0.1).round();

    return Scaffold(
      appBar: AppBar(
        title: Text('매출 계산'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDatePicker('시작 날짜 (yyyy-mm-dd)', _startDateController,
                      () => _pickDate(context, true)),
              SizedBox(height: 16),
              _buildDatePicker('종료 날짜 (yyyy-mm-dd)', _endDateController,
                      () => _pickDate(context, false)),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _calculateSales,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFAE7ED),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '정산',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 32),
              _buildResultCard(
                  '카드 총액', _formatCurrency(cardTotal)),
              _buildResultCard(
                  '현금 총액', _formatCurrency(cashTotal)),
              _buildResultCard(
                  '이체 총액', _formatCurrency(accountTotal)),
              _buildResultCard(
                  '총액', _formatCurrency(totalAmount)),
              _buildResultCard(
                  '부가세', _formatCurrency(vat)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(
      String label, TextEditingController controller, VoidCallback onTap) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: onTap,
    );
  }

  Widget _buildResultCard(String label, String value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
