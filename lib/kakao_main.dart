import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'friend_page.dart'; // FriendPage import

class KakaoMain extends StatelessWidget {
  // 메시지 템플릿 목록 정의
  final List<String> messages = [
    '❤나에개반하냥입니다❤\n내일 11시 미용 예약되어 있습니다😘\n변경사항 있으시면 미리 연락 부탁드립니다~',
    '예약시간 15분 지각 시 원하시는 미용 스타일의 미용이 어려울 수 있습니다 (20분 지각 시 예약은 자동 취소됩니다)\n예약시간을 꼭 지켜주시길 바랍니다🥰양해 부탁드립니다🙏🏻',
    '내일 비 소식이 있어요~ 털이 비에 젖으면 다 말리고 미용을 해야 돼서 추가 비용이 발생할 수 있습니다😭\n아이들 걸려오지 마시고 안고 방문 부탁드립니다~',
    '내일 눈 소식이 있어요~ 털이 눈에 젖으면 다 말리고 미용을 해야 돼서 추가 비용이 발생할 수 있습니다😭\n아이들 걸려오지 마시고 안고 방문 부탁드립니다~',
    '❤나에개반하냥입니다! 예약금 입금 확인되지 않아 예약이 취소되었음을 안내드립니다.\n재예약시 다시 연락부탁드립니다~🙏🏻',
  ];

  Future<List<PickerItem>> _getFriends(BuildContext context) async {
    try {
      Friends friends = await TalkApi.instance.friends();
      if (friends.elements == null || friends.elements!.isEmpty) {
        print('메시지를 보낼 친구가 없습니다.');
        return [];
      }

      return friends.elements!
          .map((friend) => PickerItem(
        friend.uuid,
        friend.profileNickname ?? '이름 없음',
        friend.profileThumbnailImage,
      ))
          .toList();
    } catch (error) {
      print('카카오톡 친구 목록 가져오기 실패: $error');
      _showMessage(context, '오류', '친구 목록을 불러오는 데 실패했습니다.');
      return [];
    }
  }

  // 메시지 선택 다이얼로그
  Future<String?> _selectMessage(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('메시지 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                  onTap: () {
                    Navigator.of(context).pop(messages[index]);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage(BuildContext context) async {
    List<PickerItem> friends = await _getFriends(context);
    if (friends.isEmpty) return;

    // 친구 목록 페이지로 이동해 UUID 선택
    List<String> selectedUuids = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FriendPage(items: friends),
      ),
    );

    if (selectedUuids.isEmpty) {
      _showMessage(context, '알림', '메시지를 보낼 친구를 선택하지 않았습니다.');
      return;
    }

    // 메시지 선택 다이얼로그 표시
    String? selectedMessage = await _selectMessage(context);
    if (selectedMessage == null) {
      _showMessage(context, '알림', '메시지를 선택하지 않았습니다.');
      return;
    }

    // 선택한 메시지 템플릿 생성
    FeedTemplate template = FeedTemplate(
      content: Content(
        title: 'Flutter로 보낸 메시지',
        description: selectedMessage,
        imageUrl: Uri.parse(
            'https://developers.kakao.com/assets/img/default_thumbnail.png'),
        link: Link(
          webUrl: Uri.parse('https://developers.kakao.com'),
          mobileWebUrl: Uri.parse('https://developers.kakao.com'),
        ),
      ),
    );

    try {
      // 선택된 친구들에게 메시지 전송
      MessageSendResult result = await TalkApi.instance.sendDefaultMessage(
        receiverUuids: selectedUuids,
        template: template,
      );

      print('메시지 보내기 성공: ${result.successfulReceiverUuids}');
      if (result.failureInfos != null) {
        print('일부 친구에게 메시지 보내기 실패: ${result.failureInfos}');
      }

      _showMessage(context, '성공', '메시지가 성공적으로 전송되었습니다.');
    } catch (error) {
      print('메시지 보내기 실패: $error');
      _showMessage(context, '오류', '메시지 보내기에 실패했습니다.');
    }
  }

  void _showMessage(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
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
        title: const Text('Kakao Main'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _sendMessage(context),
          child: const Text('친구에게 메시지 보내기'),
        ),
      ),
    );
  }
}
