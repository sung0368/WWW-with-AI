import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'editprofile.dart'; // ProfileEditPage를 사용하기 위해 임포트
import 'kakao_map_test.dart';
import 'map_overlay.dart';
import 'savedpage.dart';
import 'settingpage.dart';
import 'weather_search.dart';

// MyPage 클래스: 사용자 기본정보 및 로그아웃 기능을 제공하는 화면
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

// _MyPageState 클래스: MyPage 화면의 상태를 관리
class _MyPageState extends State<MyPage> {
  /////추가된 코드
  int _selectedIndex = 0;
  /////

  String? userName;
  String? userEmail;
  String? userPhone;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  // Firestore에서 사용자 정보를 가져오는 함수
  Future<void> fetchUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'];
          userEmail = userDoc['email'];
          userPhone = userDoc['phone'];
        });
      }
    }
  }

  // 로그아웃 함수
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/'); // 로그아웃 후 메인 화면으로 이동
  }

  /////추가된 코드
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (_selectedIndex) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => KakaoMap()));
        break;
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SavedPage()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MapOverlay()));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => WeatherSearchScreen()));
        break;
      case 4:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SettingPage()));
        break;
    }
  }
  /////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Remove shadow
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Color(0xFF2979FF), // 배경색을 파란색으로 설정
                    child: Text(
                      userName != null && userName!.isNotEmpty
                          ? userName![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 60,
                        color: Colors.white,
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 36),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (userName != null)
                        Text(
                          '$userName님',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      SizedBox(height: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          // 여기에 사진 수정 기능을 추가하십시오
                        },
                        child: Text(
                          '사진 수정',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 50),
              Row(
                children: [
                  Container(
                    width: 100, // Fixed width for label
                    child: Text('계정',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: 'NotoSansKR',
                          fontWeight: FontWeight.w400,
                        )),
                  ),
                  SizedBox(width: 8),
                  if (userEmail != null)
                    Text('$userEmail',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'NotoSansKR',
                          fontWeight: FontWeight.w400,
                        )),
                ],
              ),
              SizedBox(height: 25),
              Row(
                children: [
                  Container(
                    width: 100, // Fixed width for label
                    child: Text('전화번호',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: 'NotoSansKR',
                          fontWeight: FontWeight.w400,
                        )),
                  ),
                  SizedBox(width: 8),
                  if (userPhone != null)
                    Text('$userPhone',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'NotoSansKR',
                          fontWeight: FontWeight.w400,
                        )),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ///// 추가된 코드
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: '저장',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: '검색',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud),
              label: '날씨',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color(0xFF7D8491),
          unselectedItemColor: Color(0xFF7D8491), // 선택되지 않은 항목 색상
          backgroundColor: Colors.transparent, // 배경색을 투명으로 설정
          type: BottomNavigationBarType.fixed, // 모든 아이템의 라벨이 항상 보이도록 설정
          elevation: 0, // 그림자 효과 제거
          onTap: _onItemTapped,
        ),
      ),
      /////
    );
  }
}
