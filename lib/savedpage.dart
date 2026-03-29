import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakaomap_with_ai/weather_search.dart';
import 'package:url_launcher/url_launcher.dart';
import 'kakao_map_test.dart';
import 'map_overlay.dart';
import 'settingpage.dart';

class SavedPage extends StatefulWidget {
  @override
  _SavedPageState createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  int _selectedIndex = 1;
  String? userName;

  Map<String, List<Map<String, dynamic>>> _data = {
    'cafes': [],
    'restaurants': [],
    'entertainment': []
  };
  late Future<void> _futureData;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _futureData = _fetchSavedData(user.uid);
      fetchUserInfo();
    }
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
        });
      }
    }
  }

  Future<void> _fetchSavedData(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('users').doc(userId);

    final cafesSnapshot = await userDocRef.collection('cafes').get();
    final restaurantsSnapshot =
        await userDocRef.collection('restaurants').get();
    final entertainmentSnapshot =
        await userDocRef.collection('entertainment').get();

    setState(() {
      _data['cafes'] = cafesSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
      _data['restaurants'] = restaurantsSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
      _data['entertainment'] = entertainmentSnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    });
  }

  Future<void> _deleteItem(
      String userId, String collection, String itemId, String itemName) async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('users').doc(userId);

    try {
      final userCollectionSnapshot = await userDocRef
          .collection(collection)
          .where('name', isEqualTo: itemName)
          .get();

      for (var doc in userCollectionSnapshot.docs) {
        await doc.reference.delete();
        print('Deleted from user collection: $collection/${doc.id}');
      }

      setState(() {
        _data[collection]!.removeWhere((item) => item['id'] == itemId);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제 중 오류가 발생했습니다.')));
      print('Error deleting item: $e');
    }
  }

  Future<void> _launchKakaoMap(String address) async {
    final kakaoMapUrl =
        Uri.encodeFull('https://map.kakao.com/link/search/$address');
    if (await canLaunch(kakaoMapUrl)) {
      await launch(kakaoMapUrl);
    } else {
      throw 'Could not launch $kakaoMapUrl';
    }
  }

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
        //현재 페이지 이므로 아무 동작도 하지 않음.
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('내 저장된 장소', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Text(
            '로그인 후 사용 가능합니다.',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: userName != null
              ? Text(
                  '$userName\'s choice',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Text('내 저장', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.black),
              onPressed: () {
                showSearch(context: context, delegate: ItemSearch(_data));
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: '식당'),
              Tab(text: '카페'),
              Tab(text: '놀거리'),
            ],
            labelStyle: TextStyle(fontSize: 18.0), // 글자 크기를 18로 설정
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2979FF), // 하단 바 색상을 파란색으로 설정
          ),
        ),
        body: TabBarView(
          children: [
            _buildCategoryGrid('식당', _data['restaurants'] ?? [], user.uid,
                'restaurants', Icons.restaurant),
            _buildCategoryGrid('카페', _data['cafes'] ?? [], user.uid, 'cafes',
                Icons.local_cafe),
            _buildCategoryGrid('놀거리', _data['entertainment'] ?? [], user.uid,
                'entertainment', Icons.local_activity),
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
                icon: Icon(
                  Icons.bookmark,
                  color: Colors.black,
                ),
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
            unselectedItemColor: Color(0xFF7D8491),
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(String category, List<Map<String, dynamic>> items,
      String userId, String collection, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1, // 카드의 크기 비율 조정
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item['name'] ?? '이름 없음',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Suit',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Expanded(
                    child: Text(
                      item['address'] ?? '주소 없음',
                      style: TextStyle(
                        fontFamily: 'Suit',
                        color: Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.map, color: Colors.black),
                          onPressed: () {
                            _launchKakaoMap(item['address']);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.black),
                          onPressed: () async {
                            bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                title: Text('삭제 확인'),
                                content: Text('이 항목을 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    child: Text('취소'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFF2979FF),
                                    ),
                                  ),
                                  ElevatedButton(
                                    child: Text('삭제'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF2979FF),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm) {
                              await _deleteItem(userId, collection, item['id']!,
                                  item['name']);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ItemSearch extends SearchDelegate {
  final Map<String, List<Map<String, dynamic>>> data;

  ItemSearch(this.data);

  @override
  String get searchFieldLabel => '상호명/주소 검색';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        color: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.black54),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF2979FF)),
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredCafes = data['cafes']!.where((item) {
      return item['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          item['address']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();

    final filteredRestaurants = data['restaurants']!.where((item) {
      return item['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          item['address']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();

    final filteredEntertainment = data['entertainment']!.where((item) {
      return item['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          item['address']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();

    String result = "";
    if (filteredCafes.isNotEmpty) {
      result += "카페:\n";
      for (var item in filteredCafes) {
        result += "- ${item['name']} (${item['address']})\n";
      }
    }
    if (filteredRestaurants.isNotEmpty) {
      result += "\n식당:\n";
      for (var item in filteredRestaurants) {
        result += "- ${item['name']} (${item['address']})\n";
      }
    }
    if (filteredEntertainment.isNotEmpty) {
      result += "\n놀거리:\n";
      for (var item in filteredEntertainment) {
        result += "- ${item['name']} (${item['address']})\n";
      }
    }

    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('검색 결과'),
          content: SingleChildScrollView(
            child: Text(result),
          ),
          actions: [
            TextButton(
              onPressed: () {
                close(context, null);
              },
              child: Text('확인'),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF2979FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    });

    return Container(
      color: Colors.white,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      color: Colors.white,
    );
  }
}

