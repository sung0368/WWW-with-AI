import 'package:flutter/material.dart';
import 'package:kakaomap_webview/kakaomap_webview.dart';
import 'package:http/http.dart' as http;
import 'package:kakaomap_with_ai/weather_search.dart';
import 'dart:convert';
import 'map_overlay.dart';
import 'webview_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'option.dart';
import 'api_util.dart';
import 'kakao_map_test.dart';
import 'savedpage.dart';
import 'settingpage.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


final String kakaoMapKey = dotenv.env['KAKAO_MAP_KEY']!;
final String openAiApiKey = dotenv.env['OPENAI_API_KEY']!;

class MapScreen extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final double centerLat;
  final double centerLng;
  final String centerAddress;
  final bool isRandom;

  MapScreen({
    required this.locations,
    required this.centerLat,
    required this.centerLng,
    required this.centerAddress,
    required this.isRandom,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /////추가된 코드
  bool _isNavigating = false;
  int _selectedIndex = 0;
  /////
  late Future<List<Map<String, dynamic>>> _activitiesFuture;
  late Future<List<Map<String, dynamic>>> _cafesFuture;
  late Future<List<Map<String, dynamic>>> _restaurantsFuture;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = getSavedEntertainment();
    _cafesFuture = getSavedCafes();
    _restaurantsFuture = getSavedRestaurants();
  }

  Future<List<Map<String, dynamic>>> _filterLocations(
      Future<List<Map<String, dynamic>>> future) async {
    final data = await future;
    final filteredData = data.where((location) {
      final lat = location['latitude'];
      final lng = location['longitude'];

      if (lat == null || lng == null) {
        print('Invalid location data: $location');
        return false;
      }

      final distance = calculateDistance(
        widget.centerLat,
        widget.centerLng,
        lat.toDouble(),
        lng.toDouble(),
      );

      print('Location: ($lat, $lng) - Distance: $distance km');
      return distance <= 1.0;
    }).toList();

    print('Filtered data: $filteredData');
    return filteredData;
  }

  Future<String> _generatePlan(
      List<Map<String, dynamic>> activities,
      List<Map<String, dynamic>> cafes,
      List<Map<String, dynamic>> restaurants) async {
    List<Map<String, dynamic>> fetchedActivities = activities;
    List<Map<String, dynamic>> fetchedCafes = cafes;
    List<Map<String, dynamic>> fetchedRestaurants = restaurants;

    if (activities.isEmpty) {
      fetchedActivities = await getNearbyEntertainment(widget.centerAddress);
    }
    if (cafes.isEmpty) {
      fetchedCafes = await getNearbyCafes(widget.centerAddress);
    }
    if (restaurants.isEmpty) {
      fetchedRestaurants = await getNearbyRestaurants(widget.centerAddress);
    }

    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAiApiKey',
      };

      final prompt = '''
다음 정보를 바탕으로 하루 계획을 짜주세요. 하루 계획은 카페, 식당, 놀거리 순으로 추천해주세요. 카페나 식당의 경우 메뉴도 같이 추천하면 좋을 것 같아요.
아래 형식으로 응답해 주세요:

오늘 만남에서는 ~ (계획을 8~10줄 정도로 작성. 가독성이 좋도록 줄바꿈을 사용. 부드러운 구어체로 작성.)

계획을 설명하고 난 후에는,
"이상 하루 계획을 생성해주는 Plan AI였습니다! 즐거운 만남 되세요(웃는 이모티콘)" 이 꼭 출력되게 해주세요.
놀거리:
${fetchedActivities.isNotEmpty ? fetchedActivities.map((activity) => activity['name']).join('\n') : '활동 없음'}

카페:
${fetchedCafes.isNotEmpty ? fetchedCafes.map((cafe) => cafe['name']).join('\n') : '카페 없음'}

식당:
${fetchedRestaurants.isNotEmpty ? fetchedRestaurants.map((restaurant) => restaurant['name']).join('\n') : '식당 없음'}

형식에 맞게 응답해 주세요.
''';

      final body = json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 1024,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('Failed to get response from OpenAI API');
      }
    } catch (e) {
      print('Error in _generatePlan: $e');
      return '계획을 생성하는 데 실패했습니다. 다시 시도해 주세요.';
    }
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

  ////// 현재위치 추가 코드
  Future<void> _navigateToDestination() async {
    try {
      // 도착지 좌표
      double destLat = widget.centerLat;
      double destLng = widget.centerLng;

      // KakaoMap URL 생성
      String url = 'https://map.kakao.com/link/to/${Uri.encodeComponent(widget.centerAddress)},$destLat,$destLng';

      // 웹뷰로 URL 열기
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(url: url),
        ),
      );
    } catch (e) {
      print('Error navigating to destination: $e');
    }
  }

  // Future<void> _launchKakaoMapApp(double startLat, double startLng, double destLat, double destLng) async {
  //   String url = 'kakaomap://route?sp=$startLat,$startLng&ep=$destLat,$destLng&by=CAR';

  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      Placemark place = placemarks[0];
      String address = "${place.locality} ${place.street}";
      return address;
    } catch (e) {
      print(e);
      return "주소를 불러오는 데 실패했습니다.";
    }
  }
  //////

  Future<void> _navigateToNextScreen() async {
    if (_isNavigating) return;
    _isNavigating = true;

    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 바깥을 눌러도 닫히지 않도록 설정
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // 배경을 투명하게 설정
          child: Container(
            width: 100, 
            height: 100, 
            
            child: Padding(
              padding: const EdgeInsets.all(0.5),
              child: Image.asset(
                'assets/loading.gif',
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );


  try {
    // 데이터 로드 작업 수행
    final activities = await _filterLocations(_activitiesFuture);
    final cafes = await _filterLocations(_cafesFuture);
    final restaurants = await _filterLocations(_restaurantsFuture);

    final plan = await _generatePlan(
      activities.cast<Map<String, dynamic>>(),
      cafes.cast<Map<String, dynamic>>(),
      restaurants.cast<Map<String, dynamic>>(),
    );

    Navigator.pop(context); // 로딩 다이얼로그 닫기

    // 새 페이지로 이동
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(
            generatedPlan: plan,
            centerAddress: widget.centerAddress,
          ),
        ),
      );
    }
  } catch (e) {
    Navigator.pop(context); // 로딩 다이얼로그 닫기
    // 오류 처리
  } finally {
    _isNavigating = false; // 네비게이션 종료 후 플래그 해제
  }
}



  /////
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '우리 여기서 볼까?',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w500,
            fontSize: 22,
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
          Positioned.fill(
            child: KakaoMapView(
              width: size.width,
              height: size.height,
              kakaoMapKey: kakaoMapKey,
              lat: widget.centerLat,
              lng: widget.centerLng,
              showMapTypeControl: true,
              showZoomControl: true,
              markerImageURL:
                  'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
              customScript: '''
                var markers = [];
                var imageSrc = "https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/markerStar.png";
                var imageSize = new kakao.maps.Size(24, 35);
                var markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize);
                var bounds = new kakao.maps.LatLngBounds(); 

                // ${widget.isRandom ? '랜덤 장소 선정' : '중간 장소 찾기'}
                ${!widget.isRandom ? widget.locations.map((location) => '''
                  var marker = new kakao.maps.Marker({
                    position: new kakao.maps.LatLng(${location['y']}, ${location['x']}),
                    map: map,
                    image: markerImage
                  });
                  markers.push(marker);
                  bounds.extend(marker.getPosition()); 

                  var infowindow = new kakao.maps.InfoWindow({
                    content: '<div style="padding:5px;">장소: ${location['name']}</div>'
                  });

                  kakao.maps.event.addListener(marker, 'mouseover', function() {
                    infowindow.open(map, marker);
                  });

                  kakao.maps.event.addListener(marker, 'mouseout', function() {
                    infowindow.close();
                  });
                ''').join('') : ''}

                var centerMarker = new kakao.maps.Marker({
                  position: new kakao.maps.LatLng(${widget.centerLat}, ${widget.centerLng}),
                  map: map,
                  image: new kakao.maps.MarkerImage(
                    'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
                    new kakao.maps.Size(24, 35)
                  )
                });
                markers.push(centerMarker);
                bounds.extend(centerMarker.getPosition()); 

                var centerInfowindow = new kakao.maps.InfoWindow({
                  content: '<div style="padding:5px;">중간 지점</div>'
                });

                kakao.maps.event.addListener(centerMarker, 'mouseover', function() {
                  centerInfowindow.open(map, centerMarker);
                });

                kakao.maps.event.addListener(centerMarker, 'mouseout', function() {
                  centerInfowindow.close();
                });

                map.setBounds(bounds);
              ''',
              onTapMarker: (message) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('마커 클릭: $message')));
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.centerAddress,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xFF2979FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 24.0),
                        ),
                        onPressed: () async {
                          await _navigateToNextScreen();
                        },
                        child: Text(
                          '뭐하고 놀래?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w400
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: Icon(Icons.directions, color: Colors.black),
                            label: Text(
                              '길찾기',
                              style: TextStyle(
                                  color: Colors.black, 
                                  fontSize: 14,
                                  fontFamily: 'NotoSansKR',
                                  fontWeight: FontWeight.w400,
                              ),
                            ),
                            onPressed: _navigateToDestination,
                          ),
                          Text(
                            '|',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 20,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.share, color: Colors.black),
                            label: Text(
                              '공유하기',
                              style: TextStyle(
                                  color: Colors.black, 
                                  fontSize: 14,
                                  fontFamily: 'NotoSansKR',
                                  fontWeight: FontWeight.w400,
                                ),
                            ),
                            onPressed: () {
                              final address = widget.centerAddress;
                              final kakaoMapUrl =
                                  'https://map.kakao.com/?q=${Uri.encodeComponent(address)}';
                              final message = '여기 가보세요! $kakaoMapUrl';
                              Share.share(message);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
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
