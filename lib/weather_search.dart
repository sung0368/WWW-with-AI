import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kakao_map_test.dart';
import 'map_overlay.dart';
import 'savedpage.dart';
import 'settingpage.dart';

class WeatherSearchScreen extends StatefulWidget {
  @override
  _WeatherSearchScreenState createState() => _WeatherSearchScreenState();
}

class _WeatherSearchScreenState extends State<WeatherSearchScreen> {
  final String apiKey = dotenv.env['OPENWEATHER_API_KEY']!;
  final String kakaoRestApiKey = dotenv.env['KAKAO_REST_API_KEY']!;
  int _selectedIndex_nav = 3;

  TextEditingController _searchController = TextEditingController();
  bool isLoading = false;
  List<Map<String, dynamic>> searchResults = [];
  List<String> recentSearches = [];
  List<String> savedPlaces = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Load recent searches and saved places
    _loadSearchHistory().then((history) {
      setState(() {
        recentSearches = history;
      });
    });

    _loadSavedPlaces().then((places) {
      setState(() {
        savedPlaces = places;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveSearchKeyword(String keyword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> searchHistory = prefs.getStringList('searchHistory') ?? [];

    // Remove duplicates
    if (searchHistory.contains(keyword)) {
      searchHistory.remove(keyword);
    }

    // Add to the front of the list
    searchHistory.insert(0, keyword);

    // Save only the latest 10 searches
    if (searchHistory.length > 10) {
      searchHistory = searchHistory.sublist(0, 10);
    }

    await prefs.setStringList('searchHistory', searchHistory);
  }

  Future<void> _savePlace(String place) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> places = prefs.getStringList('savedPlaces') ?? [];

    // Remove duplicates
    if (places.contains(place)) {
      places.remove(place);
    }

    // Add to the front of the list
    places.insert(0, place);

    // Save only the latest 10 places
    if (places.length > 10) {
      places = places.sublist(0, 10);
    }

    await prefs.setStringList('savedPlaces', places);
  }

  Future<List<String>> _loadSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('searchHistory') ?? [];
  }

  Future<List<String>> _loadSavedPlaces() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('savedPlaces') ?? [];
  }

  Future<void> _clearSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('searchHistory');
    setState(() {
      recentSearches.clear();
    });
  }

  Future<void> _clearSavedPlaces() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedPlaces');
    setState(() {
      savedPlaces.clear();
    });
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;

    // Save the search keyword
    await _saveSearchKeyword(query);

    // Reload the recent searches to ensure they are up-to-date
    final updatedRecentSearches = await _loadSearchHistory();
    setState(() {
      isLoading = true;
      searchResults.clear();
      recentSearches = updatedRecentSearches; // Update the recent searches
    });

    try {
      final results = await _getCoordinates(query);
      if (results.isNotEmpty) {
        for (var location in results) {
          await _fetchWeather(
            double.parse(location['y']),
            double.parse(location['x']),
            location['place_name'],
          );
        }
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchWeather(double lat, double lon, String address) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&exclude=current,minutely,daily,alerts&appid=$apiKey&units=metric');
    final response = await http.get(url);
    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      setState(() {
        searchResults.add({
          'address': address,
          'hourlyWeather': List<Map<String, dynamic>>.from(data['hourly']),
          'icon':
              getWeatherIcon(data['hourly'][0]['weather'][0]['description']),
          'description': translateDescription(
              data['hourly'][0]['weather'][0]['description']),
          'temp': data['hourly'][0]['temp'].toStringAsFixed(1),
          'feels_like': data['hourly'][0]['feels_like'] != null
              ? data['hourly'][0]['feels_like'].toStringAsFixed(1)
              : 'N/A',
          'humidity': data['hourly'][0]['humidity'] != null
              ? data['hourly'][0]['humidity'].toString()
              : 'N/A',
          'wind_speed': data['hourly'][0]['wind_speed'] != null
              ? data['hourly'][0]['wind_speed'].toStringAsFixed(2)
              : 'N/A',
        });
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getCoordinates(String keyword) async {
    final response = await http.get(
      Uri.parse(
          'https://dapi.kakao.com/v2/local/search/keyword.json?query=$keyword'),
      headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['documents']);
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  IconData getWeatherIcon(String description) {
    switch (description.toLowerCase()) {
      case 'clear sky':
        return Icons.wb_sunny;
      case 'few clouds':
        return Icons.cloud_queue;
      case 'scattered clouds':
        return Icons.cloud;
      case 'broken clouds':
      case 'overcast clouds':
        return Icons.filter_drama;
      case 'shower rain':
      case 'light rain':
      case 'moderate rain':
      case 'heavy intensity rain':
        return Icons.umbrella;
      case 'rain':
        return Icons.cloud;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
      case 'light snow':
      case 'heavy snow':
        return Icons.ac_unit;
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'fog':
        return Icons.blur_on;
      case 'sand':
      case 'dust':
      case 'volcanic ash':
      case 'sand/dust whirls':
        return Icons.cloud_off;
      case 'squalls':
        return Icons.air;
      case 'tornado':
        return Icons.tornado;
      case 'drizzle':
      case 'light drizzle':
      case 'heavy intensity drizzle':
        return Icons.grain;
      default:
        return Icons.error_outline;
    }
  }

  String translateDescription(String description) {
    switch (description.toLowerCase()) {
      case 'clear sky':
        return '맑음';
      case 'few clouds':
        return '약간 흐림';
      case 'scattered clouds':
        return '구름 많음';
      case 'broken clouds':
        return '흐림';
      case 'overcast clouds':
        return '매우 흐림';
      case 'shower rain':
        return '소나기';
      case 'light rain':
        return '가벼운 비';
      case 'moderate rain':
        return '적당한 비';
      case 'heavy intensity rain':
        return '강한 비';
      case 'rain':
        return '비';
      case 'thunderstorm':
        return '천둥번개';
      case 'snow':
        return '눈';
      case 'light snow':
        return '가벼운 눈';
      case 'heavy snow':
        return '많은 눈';
      case 'mist':
        return '안개';
      case 'smoke':
        return '연기';
      case 'haze':
        return '연무';
      case 'fog':
        return '안개';
      case 'sand':
        return '모래';
      case 'dust':
        return '먼지';
      case 'volcanic ash':
        return '화산재';
      case 'sand/dust whirls':
        return '모래/먼지 소용돌이';
      case 'squalls':
        return '돌풍';
      case 'tornado':
        return '토네이도';
      case 'drizzle':
        return '이슬비';
      case 'light drizzle':
        return '가벼운 이슬비';
      case 'heavy intensity drizzle':
        return '강한 이슬비';
      default:
        return '날씨 정보 없음';
    }
  }

  void _showHourlyWeatherDetails(
      List<Map<String, dynamic>> hourlyData, String address) async {
    await _savePlace(address); // 장소 저장
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('$address'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: hourlyData.length,
              itemBuilder: (BuildContext context, int index) {
                var weather = hourlyData[index];
                DateTime time =
                    DateTime.fromMillisecondsSinceEpoch(weather['dt'] * 1000);
                return ListTile(
                  leading: Icon(
                    getWeatherIcon(weather['weather'][0]['description']),
                    color: Colors.black,
                  ),
                  title: Text('${time.hour}:00'),
                  subtitle: Text(
                      '${weather['temp']}°C, ${translateDescription(weather['weather'][0]['description'])}'),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('닫기', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    // 장소 저장 후 UI 업데이트
    final places = await _loadSavedPlaces();
    setState(() {
      savedPlaces = places;
    });
  }

  Future<void> _fetchAndDisplaySavedPlace(String place) async {
    setState(() {
      isLoading = true;
      searchResults.clear();
    });

    try {
      // 장소명으로 검색하고 날씨 정보를 가져옴
      final results = await _getCoordinates(place);
      if (results.isNotEmpty) {
        var location = results.first;
        await _fetchWeather(
          double.parse(location['y']),
          double.parse(location['x']),
          location['place_name'],
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmClearHistory(VoidCallback clearFunction) async {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool? confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        content: Text(
          '전체 삭제하시겠습니까?',
          style: TextStyle(fontFamily: 'Suit', fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(
              '취소',
              style: TextStyle(color: Color(0xFF2979FF), fontFamily: 'Suit'),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_passwordController.text ==
                  _confirmPasswordController.text) {
                Navigator.of(context).pop(true);
              } else {
                _showErrorDialog('비밀번호가 일치하지 않습니다.');
              }
            },
            child: Text(
              '삭제',
              style: TextStyle(fontFamily: 'Suit', color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2979FF),
            ),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    clearFunction();
  }
}

  void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('오류'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('확인'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '날씨는 어때?',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '주소 입력',
                hintStyle: TextStyle(
                  color: Color(0xFF7D8491),
                  fontSize: 16,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w400
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.black),
                  onPressed: () => _searchAddress(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Color(0xFF7D8491)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Color(0xFF2979FF), width: 2.0), // 포커스 시 테두리 색상
                ),
              ),
            ),
            SizedBox(height: 16),
            if (isLoading)
              Center(
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
              )
            else if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final result = searchResults[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 4,
                      color: Color(0xFFF5F7FA),
                      child: ListTile(
                        leading:
                            Icon(result['icon'], color: Colors.black, size: 30),
                        title: Text(
                          result['address'],
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'NotoSansKR',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(
                            '기온: ${result['temp']}°C\n체감 온도: ${result['feels_like']}°C\n습도: ${result['humidity']}%\n풍속: ${result['wind_speed']} m/s\n날씨: ${result['description']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        trailing: IconButton(
                          icon: Icon(Icons.access_time, color: Colors.black),
                          onPressed: () => _showHourlyWeatherDetails(
                              result['hourlyWeather'], result['address']),
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
            if (recentSearches.isNotEmpty || savedPlaces.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    if (recentSearches.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '최근 검색어',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () =>
                                _confirmClearHistory(_clearSearchHistory),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: recentSearches.map((search) {
                          return GestureDetector(
                            onTap: () => _searchAddress(search),
                            child: Chip(
                              backgroundColor: Colors.white,
                              label: Text(search),
                              deleteIcon: Icon(Icons.clear),
                              onDeleted: () async {
                                setState(() {
                                  recentSearches.remove(search);
                                });
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setStringList(
                                    'searchHistory', recentSearches);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    if (savedPlaces.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '조회한 장소',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'NotoSansKR',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () =>
                                _confirmClearHistory(_clearSavedPlaces),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Column(
                        children: savedPlaces.map((place) {
                          return ListTile(
                            title: Text(place),
                            onTap: () => _fetchAndDisplaySavedPlace(place),
                            trailing: IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () async {
                                setState(() {
                                  savedPlaces.remove(place);
                                });
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setStringList(
                                    'savedPlaces', savedPlaces);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
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
              icon: Icon(Icons.star),
              label: '검색',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud, color: Colors.black),
              label: '날씨',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
          currentIndex: _selectedIndex_nav,
          selectedItemColor: Colors.black,
          unselectedItemColor: Color(0xFF7D8491),
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: _onItemTapped_nav,
        ),
      ),
    );
  }
}
