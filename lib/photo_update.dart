import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class PhotoUpdatePage extends StatefulWidget {
  final int schId;
  final int petId;
  final String token;

  PhotoUpdatePage({required this.schId, required this.petId, required this.token});

  @override
  _PhotoUpdatePageState createState() => _PhotoUpdatePageState();
}

class _PhotoUpdatePageState extends State<PhotoUpdatePage> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진을 선택해주세요.')),
      );
      return;
    }

    try {
      final uri = Uri.parse('http://152.67.208.206:8080/api/uploadPhoto');
      final request = http.MultipartRequest('POST', uri);

      request.fields['schId'] = widget.schId.toString();
      request.fields['petId'] = widget.petId.toString();
      request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));
      request.headers['Authorization'] = 'Bearer ${widget.token}';

      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 업로드 성공!')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 업로드 실패. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print('업로드 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 업로드 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('사진 업로드'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _selectedImage != null
                ? Image.file(
              _selectedImage!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            )
                : Placeholder(fallbackHeight: 200, fallbackWidth: 200),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('사진 선택'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploadPhoto,
              child: Text('사진 업로드'),
            ),
          ],
        ),
      ),
    );
  }
}
