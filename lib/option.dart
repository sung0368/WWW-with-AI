import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth 패키지 추가
import 'package:firebase_core/firebase_core.dart'; // FirebaseCore 패키지 추가
import 'api_util.dart'; // API 유틸 함수가 정의된 파일
import 'kakao_map_test.dart';
import 'map_overlay.dart';
import 'savedpage.dart';
import 'settingpage.dart';
import 'weather_search.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String? generatedPlan;
  final String? centerAddress;

  MyHomePage({this.generatedPlan, this.centerAddress});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex_nav = 0;
  int _selectedIndex = 0;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      MasterPlanScreen(plan: widget.generatedPlan ?? ''),
      CafeScreen(centerAddress: widget.centerAddress ?? ''),
      RestaurantScreen(centerAddress: widget.centerAddress ?? ''),
      EntertainmentScreen(centerAddress: widget.centerAddress ?? ''),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /////추가된 코드
  void _onItemTapped_nav(int index) {
    setState(() {
      _selectedIndex_nav = index;
    });

    switch (_selectedIndex_nav) {
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
      appBar: AppBar(
        title: Text(
          '우리 이렇게 놀까?', 
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w500,
            fontSize: 22,
          )
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCategoryItem('계획', Icons.calendar_today, 0),
                  _buildCategoryItem('카페', Icons.local_cafe, 1),
                  _buildCategoryItem('식당', Icons.restaurant, 2),
                  _buildCategoryItem('놀거리', Icons.local_activity, 3),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: _widgetOptions.elementAt(_selectedIndex),
              ),
            ),
          ),
        ],
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
          currentIndex: _selectedIndex_nav,
          selectedItemColor: Color(0xFF7D8491),
          unselectedItemColor: Color(0xFF7D8491), // 선택되지 않은 항목 색상
          backgroundColor: Colors.transparent, // 배경색을 투명으로 설정
          type: BottomNavigationBarType.fixed, // 모든 아이템의 라벨이 항상 보이도록 설정
          elevation: 0, // 그림자 효과 제거
          onTap: _onItemTapped_nav,
        ),
      ),
      /////
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Color(0xFF2979FF) : Color(0xFF7D8491),
              ),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  color: isSelected ? Color(0xFF2979FF) : Color(0xFF7D8491),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
          if (isSelected)
            Container(
              margin: EdgeInsets.only(top: 4),
              height: 4, // 두께를 더 두껍게
              width: 60, // 길이를 더 길게
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2), // 둥근 모서리
              ),
            ),
        ],
      ),
    );
  }
}

class MasterPlanScreen extends StatelessWidget {
  final String plan;

  MasterPlanScreen({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/planai.gif"),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Text(
                  'PlanAI',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“ 사용자에게',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'NotoSansKR',
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '가장 많은 추천을 받은 곳이에요! ”',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Divider(color: Colors.black),
                      SizedBox(height: 20),
                      Text(
                        plan.isNotEmpty ? plan : '계획이 없습니다',
                        style: TextStyle(
                          color: Colors.black,
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w400,
                            fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CafeScreen extends StatefulWidget {
  final String centerAddress;

  CafeScreen({required this.centerAddress});

  @override
  _CafeScreenState createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> {
  late Future<List<Map<String, dynamic>>> _cafesFuture;

  @override
  void initState() {
    super.initState();
    _cafesFuture = getNearbyCafes(widget.centerAddress);
  }

  Future<void> saveToFirestore(
      String type, String name, String address, double lat, double long) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final firestore = FirebaseFirestore.instance;

        // 'users' 하위 컬렉션에서 이미 저장된 주소 확인
        final userCollectionRef =
            firestore.collection('users').doc(user.uid).collection('$type');
        final querySnapshot =
            await userCollectionRef.where('address', isEqualTo: address).get();

        if (querySnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              '이미 저장되어 있습니다',
                style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                ),
              ),
            ),
          );
          return;
        }

        final batch = firestore.batch();

        // 'saved_<type>' 컬렉션에 데이터 저장
        final savedCollectionRef = firestore.collection('saved_$type');
        final savedDocRef = savedCollectionRef.doc();
        batch.set(savedDocRef, {
          'name': name,
          'address': address,
          'latitude': lat,
          'longitude': long,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 'users' 하위 컬렉션에 데이터 저장
        final userDocRef = userCollectionRef.doc();
        batch.set(userDocRef, {
          'name': name,
          'address': address,
          'latitude': lat,
          'longitude': long,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            '$name 저장 완료',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ),
        );
      } catch (e) {
        print('Error saving $type to Firestore: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            '저장 실패: $e',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          '로그인이 필요합니다',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _cafesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(
            '오류 발생: ${snapshot.error}',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(
            '근처에 카페가 없습니다',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          );
        } else {
          final cafes = snapshot.data!;
          return ListView.builder(
            itemCount: cafes.length,
            itemBuilder: (context, index) {
              final cafe = cafes[index];
              return ListTile(
                title: Text(
                  cafe['name']!,
                  style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  cafe['address']!,
                  style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.save_alt),
                  onPressed: () => saveToFirestore(
                    'cafes',
                    cafe['name']!,
                    cafe['address']!,
                    cafe['latitude'] ?? 0.0,
                    cafe['longitude'] ?? 0.0,
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}

class BookmarkButton extends StatefulWidget {
  final VoidCallback onPressed;

  BookmarkButton({required this.onPressed});

  @override
  _BookmarkButtonState createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  bool _isBookmarked = false;

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        color: _isBookmarked ? Colors.black : null,
      ),
      onPressed: _toggleBookmark,
    );
  }
}

class RestaurantScreen extends StatefulWidget {
  final String centerAddress;

  RestaurantScreen({required this.centerAddress});

  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  late Future<List<Map<String, dynamic>>> _restaurantsFuture;

  @override
  void initState() {
    super.initState();
    _restaurantsFuture = getNearbyRestaurants(widget.centerAddress);
  }

  Future<void> saveToFirestore(
      String type, String name, String address, double lat, double long) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final firestore = FirebaseFirestore.instance;

        // 'users' 하위 컬렉션에서 이미 저장된 주소 확인
        final userCollectionRef =
            firestore.collection('users').doc(user.uid).collection('$type');
        final querySnapshot =
            await userCollectionRef.where('address', isEqualTo: address).get();

        if (querySnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              '이미 저장되어 있습니다',
                style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                ),
              ),
            ),
          );
          return;
        }

        final batch = firestore.batch();

        // 'saved_<type>' 컬렉션에 데이터 저장
        final savedCollectionRef = firestore.collection('saved_$type');
        final savedDocRef = savedCollectionRef.doc();
        batch.set(savedDocRef, {
          'name': name,
          'address': address,
          'latitude': lat,
          'longitude': long,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 'users' 하위 컬렉션에 데이터 저장
        final userDocRef = userCollectionRef.doc();
        batch.set(userDocRef, {
          'name': name,
          'address': address,
          'latitude': lat,
          'longitude': long,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            '$name 저장 완료',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ),
        );
      } catch (e) {
        print('Error saving $type to Firestore: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            '저장 실패: $e',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          '로그인이 필요합니다',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _restaurantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(
            '오류 발생: ${snapshot.error}',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(
            '근처에 식당이 없습니다',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          );
        } else {
          final restaurants = snapshot.data!;
          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return ListTile(
                title: Text(
                  restaurant['name']!,
                  style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  restaurant['address']!,
                  style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.save_alt),
                  onPressed: () => saveToFirestore(
                    'restaurants',
                    restaurant['name']!,
                    restaurant['address']!,
                    restaurant['latitude'] ?? 0.0,
                    restaurant['longitude'] ?? 0.0,
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}

class EntertainmentScreen extends StatefulWidget {
  final String centerAddress;

  EntertainmentScreen({required this.centerAddress});

  @override
  _EntertainmentScreenState createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen> {
  late Future<List<Map<String, dynamic>>> _entertainmentFuture;

  @override
  void initState() {
    super.initState();
    _entertainmentFuture = getNearbyEntertainment(widget.centerAddress);
  }

  Future<void> saveToFirestore(
      String type, String name, String address, double lat, double long) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final firestore = FirebaseFirestore.instance;

        final userCollectionRef =
            firestore.collection('users').doc(user.uid).collection('$type');
        final querySnapshot =
            await userCollectionRef.where('address', isEqualTo: address).get();

        if (querySnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              '이미 저장되어 있습니다',
                style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                ),
              ),
            ),
          );
          return;
        }

        final batch = firestore.batch();

        final savedCollectionRef = firestore.collection('saved_$type');
        final savedDocRef = savedCollectionRef.doc();
        batch.set(savedDocRef, {
          'name': name,
          'address': address,
          'latitude': lat,
          'longitude': long,
          'timestamp': FieldValue.serverTimestamp(),
        });

        final userDocRef = userCollectionRef.doc();
        batch.set(userDocRef, {
          'name': name,
          'address': address,
          'latitude': lat,
          'longitude': long,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await batch.commit();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            '$name 저장 완료',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ),
        );
      } catch (e) {
        print('Error saving $type to Firestore: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            '저장 실패: $e',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          '로그인이 필요합니다',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _entertainmentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(
            '오류 발생: ${snapshot.error}',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(
            '근처에 놀거리가 없습니다',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
            ),
          );
        } else {
          final entertainment = snapshot.data!;
          return ListView.builder(
            itemCount: entertainment.length,
            itemBuilder: (context, index) {
              final activity = entertainment[index];
              // 주소가 없는 항목 필터링
              if (activity['address'] == null || activity['address'].isEmpty) {
                return Container(); // 빈 컨테이너를 반환하여 리스트에 표시하지 않음
              }
              return ListTile(
                title: Text(
                  activity['name']!,
                  style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  activity['address']!,
                  style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.save_alt),
                  onPressed: () => saveToFirestore(
                    'entertainment',
                    activity['name']!,
                    activity['address']!,
                    activity['latitude'] ?? 0.0,
                    activity['longitude'] ?? 0.0,
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
