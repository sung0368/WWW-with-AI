import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakaomap_with_ai/weather_search.dart';
import 'settingpage.dart';
import 'mypage.dart'; // MyPage 파일 임포트
import 'map_screen.dart';
import 'savedpage.dart'; // SavedPage 파일 임포트
import 'dart:math'; // Random 클래스를 사용하기 위해 임포트
import 'map_overlay.dart';

final String kakaoMapKey = dotenv.env['KAKAO_MAP_KEY']!;
final String kakaoRestApiKey = dotenv.env['KAKAO_REST_API_KEY']!;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: KakaoMap(),
    );
  }
}

class KakaoMap extends StatefulWidget {
  @override
  _KakaoMapState createState() => _KakaoMapState();
}

class _KakaoMapState extends State<KakaoMap> {
  /////추가된 코드
  int _selectedIndex = 0;
  /////

  List<TextEditingController> locationControllers = [TextEditingController()];
  List<List<Map<String, dynamic>>> searchResults = [[]];
  List<int> selectedIndices = [-1];
  List<Map<String, dynamic>> locations = [];
  double centerLat = 0, centerLng = 0;
  String centerAddress = '';
  bool isLoading = false;

  String? userName;

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'];
        });
      }
    }
  }

  /////추가된 코드
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (_selectedIndex) {
      case 0:
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
        // 길찾기 버튼을 눌렀을 때 카카오맵 화면으로 이동
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
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      //resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '우리 어디서 볼래?',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w500,
              fontSize: 22,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height * 0.2,
              color: Color(0xFF2979FF), // 배경 색상을 파란색으로 변경
              padding: EdgeInsets.all(16.0), // 적절한 패딩을 추가하여 여백 설정
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white, // 아바타 배경 색상을 흰색으로 변경
                    radius: 30, // 아바타 크기 설정
                    child: Text(
                      userName != null ? userName![0] : 'U',
                      style: TextStyle(
                          fontSize: 40,
                          color: Colors.black,
                          fontFamily: 'NotoSansKR',
                          fontWeight: FontWeight.w500,
                        ), // 글자 색상을 검정색으로 변경
                    ),
                  ),
                  SizedBox(width: 16.0), // 프로필 사진과 이름 사이에 간격 추가
                  Text(
                    userName ?? 'User Name',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w400
                      ), // 텍스트 색상을 하얀색으로 변경하고 폰트 크기를 24로 설정
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(
                '마이페이지',
                style: TextStyle(
                    fontFamily: 'NotoSansKR', // 폰트 이름 지정
                    fontWeight: FontWeight.w400, // 폰트 굵기 (선택 사항)
                    fontSize: 18, // 폰트 크기 (선택 사항)
                    color: Colors.black, // 폰트 색상 (선택 사항)
                  ),
                ),
              onTap: () {
                Navigator.pop(context); // 사이드바 닫기
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyPage()),
                ); // MyPage 화면으로 이동
              },
            ),
            ListTile(
              title: Text(
                userName != null ? '$userName\'s choice' : '내 저장',
                style: TextStyle(
                  fontFamily: 'NotoSansKR', // 폰트 이름 지정
                  fontWeight: FontWeight.w400, // 폰트 굵기 (선택 사항)
                  fontSize: 18, // 폰트 크기 (선택 사항)
                  color: Colors.black, // 폰트 색상 (선택 사항)
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SavedPage()),
                ); // SavedPage 화면으로 이동
              },
            ),
            ListTile(
              title: Text(
                '설정',
                style: TextStyle(
                    fontFamily: 'NotoSansKR', // 폰트 이름 지정
                    fontWeight: FontWeight.w400, // 폰트 굵기 (선택 사항)
                    fontSize: 18, // 폰트 크기 (선택 사항)
                    color: Colors.black, // 폰트 색상 (선택 사항)
                  ),
                ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingPage()),
                );
                // 설정 화면으로 이동
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < locationControllers.length; i++) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '장소 ${i + 1}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w400
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFF7D8491)),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: locationControllers[i],
                                  decoration: InputDecoration(
                                    hintText: '장소 입력',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF7D8491),
                                      fontSize: 14,
                                      fontFamily: 'NotoSansKR',
                                      fontWeight: FontWeight.w400
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFF7D8491)),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFF7D8491)),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFF2979FF)),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.search, color: Colors.black),
                                onPressed: () {
                                  searchLocation(i);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.black),
                                onPressed: () {
                                  setState(() {
                                    locationControllers.removeAt(i);
                                    searchResults.removeAt(i);
                                    selectedIndices.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (searchResults[i].isNotEmpty && selectedIndices[i] == -1)
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResults[i].length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(searchResults[i][index]['place_name']),
                      subtitle: Text(searchResults[i][index]['address_name']),
                      onTap: () {
                        setState(() {
                          // 선택된 장소 이름을 TextField에 반영
                          locationControllers[i].text =
                              searchResults[i][index]['place_name'];
                          selectedIndices[i] = index;
                        });
                      },
                    );
                  },
                ),
            ],
            ElevatedButton(
              onPressed: selectedIndices.contains(-1)
                  ? null
                  : () async {
                      await displayMap(isRandom: false);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2979FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15.0),
                child: Text(
                  '중간장소 찾기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w500
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  locationControllers.add(TextEditingController());
                  searchResults.add([]);
                  selectedIndices.add(-1);
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, color: Colors.black),
                  SizedBox(width: 5),
                  Text(
                    '인원 추가하기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6),
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () async {
                      await displayMap(isRandom: true);
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino, color: Colors.black),
                  SizedBox(width: 5),
                  Text(
                    '랜덤장소 선정',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              icon: Icon(
                Icons.home,
                color: Colors.black,
              ),
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
          selectedItemColor: Colors.black,
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

  Future<void> searchLocation(int locationIndex) async {
    setState(() {
      isLoading = true;
      searchResults[locationIndex].clear();
      selectedIndices[locationIndex] = -1;
    });

    try {
      final results =
          await getCoordinates(locationControllers[locationIndex].text);
      setState(() {
        searchResults[locationIndex] = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소를 찾는 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> displayMap({required bool isRandom}) async {
    setState(() {
      isLoading = true;
      locations.clear();
    });

    try {
      List<double> lats = [];
      List<double> lngs = [];
      if (isRandom) {
        final results = await getRandomLocations(5); // 5개의 랜덤 장소 검색
        if (results.isNotEmpty) {
          for (int i = 0; i < results.length; i++) {
            final location = results[i];
            lats.add(double.parse(location['y']));
            lngs.add(double.parse(location['x']));
            locations.add({
              'name': '랜덤 장소 ${i + 1}',
              'x': double.parse(location['x']),
              'y': double.parse(location['y'])
            });
          }
        } else {
          throw Exception('랜덤 장소를 찾을 수 없습니다');
        }
      } else {
        for (int i = 0; i < selectedIndices.length; i++) {
          final location = searchResults[i][selectedIndices[i]];
          lats.add(double.parse(location['y']));
          lngs.add(double.parse(location['x']));
          locations.add({
            'name': '장소${i + 1}',
            'x': double.parse(location['x']),
            'y': double.parse(location['y'])
          });
        }
      }

      centerLat = lats.reduce((a, b) => a + b) / lats.length;
      centerLng = lngs.reduce((a, b) => a + b) / lngs.length;

      centerAddress = await getAddress(centerLat, centerLng);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            locations: locations,
            centerLat: centerLat,
            centerLng: centerLng,
            centerAddress: centerAddress,
            isRandom: isRandom,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('지도 표시 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCoordinates(String keyword) async {
    final response = await http.get(
      Uri.parse(
          'https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword'),
      headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['documents'].isNotEmpty) {
        return List<Map<String, dynamic>>.from(data['documents']);
      }
    }
    throw Exception('주소를 찾을 수 없습니다');
  }

  Future<List<Map<String, dynamic>>> getRandomLocations(int count) async {
    final random = Random();
    final List<Map<String, dynamic>> results = [];

    // 서울의 경도 및 위도 범위 (약 20km x 20km)
    final double latMin = 37.464;
    final double latMax = 37.700;
    final double lngMin = 126.830;
    final double lngMax = 127.100;

    for (int i = 0; i < count; i++) {
      final randomLat = latMin + (random.nextDouble() * (latMax - latMin));
      final randomLng = lngMin + (random.nextDouble() * (lngMax - lngMin));

      final response = await http.get(
        Uri.parse(
            'https://dapi.kakao.com/v2/local/search/keyword.json?query=서울&x=$randomLng&y=$randomLat&radius=1000'),
        headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List<dynamic>;
        if (documents.isNotEmpty) {
          results.addAll(
              documents.map((doc) => doc as Map<String, dynamic>).toList());
        }
      }
    }

    if (results.isEmpty) {
      throw Exception('랜덤 장소를 찾을 수 없습니다');
    }

    return results;
  }

  Future<String> getAddress(double lat, double lng) async {
    final response = await http.get(
      Uri.parse(
          'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat'),
      headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['documents'].isNotEmpty) {
        return data['documents'][0]['address']['address_name'];
      }
    }
    throw Exception('주소를 찾을 수 없습니다');
  }
}
