import 'package:flutter/material.dart';

class PickerItem {
  final String uuid;
  final String nickname;
  final String? thumbnail;

  PickerItem(this.uuid, this.nickname, this.thumbnail);
}

class FriendPage extends StatefulWidget {
  final List<PickerItem> items;

  FriendPage({required this.items});

  @override
  _FriendPageState createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  final Map<String, bool> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    // 모든 친구의 체크 상태를 초기화
    widget.items.forEach((item) {
      _selectedItems[item.uuid] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('친구 목록'),
      ),
      body: ListView.builder(
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: item.thumbnail != null
                  ? NetworkImage(item.thumbnail!)
                  : null,
              child: item.thumbnail == null ? Icon(Icons.person) : null,
            ),
            title: Text(item.nickname),
            trailing: Checkbox(
              value: _selectedItems[item.uuid] ?? false,
              onChanged: (bool? value) {
                setState(() {
                  _selectedItems[item.uuid] = value ?? false;
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 선택된 친구들의 UUID 목록을 수집
          List<String> selectedUuids = _selectedItems.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
          Navigator.of(context).pop(selectedUuids);
        },
        child: Icon(Icons.check),
      ),
    );
  }
}
