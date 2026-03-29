import 'package:flutter/material.dart'; // Flutter의 기본 위젯과 레이아웃을 사용하기 위한 임포트
import 'package:firebase_auth/firebase_auth.dart'; // Firebase 인증을 위한 임포트
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore 데이터베이스 사용을 위한 임포트
import 'kakaoMap_view.dart'; // KakaoMapView 위젯 임포트
import 'kakao_map_test.dart'; // KakaoMap 테스트용 위젯 임포트
import 'savedpage.dart'; // 저장된 페이지 임포트
import 'settingpage.dart'; // 설정 페이지 임포트
import 'weather_search.dart'; // 날씨 검색 페이지 임포트

// MapOverlay는 상태를 가지는 위젯(StatefulWidget) 클래스
class MapOverlay extends StatefulWidget {
  @override
  _MapOverlayState createState() => _MapOverlayState(); // 상태 관리 객체 생성
}

// _MapOverlayState는 MapOverlay의 상태를 관리하는 클래스
class _MapOverlayState extends State<MapOverlay> {
  int _selectedIndex = 2; // 하단 네비게이션 바에서 선택된 인덱스 (초기값: 2, 검색)
  List<Map<String, dynamic>> _locations = []; // 위치 정보 리스트
  List<Map<String, dynamic>> _filteredLocations = []; // 필터링된 위치 정보 리스트
  String _selectedGu = ''; // 선택된 구 이름
  bool _showMap = true; // 지도를 표시할지 여부 (초기값: true)
  TextEditingController _searchController = TextEditingController(); // 검색 입력을 받기 위한 컨트롤러

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser; // 현재 로그인된 사용자 정보 가져오기
    if (user != null) {
      _fetchSavedData(user.uid); // 사용자 ID로 저장된 데이터 가져오기
    }
  }

  // Firebase에서 사용자가 저장한 데이터를 가져오는 비동기 함수
  Future<void> _fetchSavedData(String userId) async {
    final firestore = FirebaseFirestore.instance; // Firestore 인스턴스 가져오기
    final userDocRef = firestore.collection('users').doc(userId); // 사용자 도큐먼트 참조

    final cafesSnapshot = await userDocRef.collection('cafes').get(); // 카페 컬렉션 가져오기
    final restaurantsSnapshot =
        await userDocRef.collection('restaurants').get(); // 레스토랑 컬렉션 가져오기
    final entertainmentSnapshot =
        await userDocRef.collection('entertainment').get(); // 엔터테인먼트 컬렉션 가져오기

    setState(() {
      _locations = [
        ...cafesSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>), // 가져온 카페 데이터를 리스트에 추가
        ...restaurantsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>), // 가져온 레스토랑 데이터를 리스트에 추가
        ...entertainmentSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>), // 가져온 엔터테인먼트 데이터를 리스트에 추가
      ];
    });
  }

  // 구 이름을 검색하여 위치 정보를 필터링하는 함수
  void _searchGu(String query) async {
    List<Map<String, dynamic>> filteredLocations = _locations.where((location) {
      return location['address'].contains(query); // 주소에 검색어가 포함된 위치 정보 필터링
    }).toList();

    setState(() {
      _selectedGu = query; // 선택된 구 업데이트
      _filteredLocations = filteredLocations; // 필터링된 위치 정보 업데이트
      _showMap = true; // 지도를 표시하도록 설정
    });
  }

  // 마커를 탭했을 때 호출되는 함수
  void _onMarkerTap(Map<String, dynamic> marker) {
    setState(() {
      _filteredLocations.add(marker); // 필터링된 위치 정보 리스트에 마커 추가
    });
  }

  // 검색 아이콘을 눌렀을 때 호출되는 함수
  void _handleSearchIconPressed() {
    _searchGu(_searchController.text); // 검색어로 구 이름 검색
  }

  // 하단 네비게이션 바에서 항목을 선택했을 때 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // 선택된 인덱스 업데이트
    });

    switch (_selectedIndex) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => KakaoMap())); // 홈 화면으로 이동
        break;
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SavedPage())); // 저장된 페이지로 이동
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MapOverlay())); // 검색 화면으로 이동
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => WeatherSearchScreen())); // 날씨 검색 화면으로 이동
        break;
      case 4:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SettingPage())); // 설정 화면으로 이동
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '그곳의 내 choice는?',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w500,
              fontSize: 22,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          // 지도 화면
          Positioned.fill(
            child: KakaoMapView(
              placeName: _selectedGu,
              geoJsonFile: 'assets/$_selectedGu.geojson',
              locations: _filteredLocations,
              onMarkerTap: _onMarkerTap,
              onSearchIconPressed: _handleSearchIconPressed,
            ),
          ),
          // 지도 위에 TextField를 겹치도록 배치
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '구 이름 입력',
                hintStyle: TextStyle(
                  color: Color(0xFF7D8491),
                  fontSize: 16,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w400,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _handleSearchIconPressed,
                ),
                fillColor: Colors.white,  // 배경색을 하얀색으로 설정
                filled: true,  // 배경색 적용 활성화
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Color(0xFF7D8491)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Color(0xFF2979FF), width: 2.0),
                ),
              ),
              onSubmitted: (value) {
                _searchGu(value);
              },
            ),
          ),
        ],
      ),
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
              icon: Icon(Icons.star, color: Colors.black),
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
          selectedItemColor: Colors.black,
          unselectedItemColor: Color(0xFF7D8491),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}