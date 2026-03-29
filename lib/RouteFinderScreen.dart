import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

class RouteFinderScreen extends StatefulWidget {
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;

  RouteFinderScreen({
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
  });

  @override
  _RouteFinderScreenState createState() => _RouteFinderScreenState();
}

class _RouteFinderScreenState extends State<RouteFinderScreen> {
  bool isLoading = true;
  late InAppWebViewController _webViewController;
  String selectedTravelMode = ''; // 선택된 이동 수단을 저장하는 변수
  List<Map<String, dynamic>> transitDetails = []; // 대중교통 세부 정보를 저장하는 리스트

  @override
  void initState() {
    super.initState();
    _findRoute();
  }

  Future<void> _findRoute() async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
    final List<String> travelModes = [
      'driving',
      'walking',
      'bicycling',
      'transit'
    ];

    for (String mode in travelModes) {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${widget.startLatitude},${widget.startLongitude}'
          '&destination=${widget.endLatitude},${widget.endLongitude}'
          '&mode=$mode&key=$apiKey';

      print('Google Maps Directions API 요청 URL: $url'); // API 요청 URL 로그

      try {
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final polylinePoints = route['overview_polyline']['points'];
            final decodedPolyline = _decodePolyline(polylinePoints);

            print('Google Maps Directions API 호출 성공: 경로 데이터를 성공적으로 받아왔습니다.');
            print('Mode: $mode, Decoded Polyline: $decodedPolyline');

            if (mode == 'transit') {
              _extractTransitDetails(route);
            }

            setState(() {
              isLoading = false;
              selectedTravelMode = mode; // 경로를 찾은 이동 수단을 저장
            });

            _drawRouteOnMap(decodedPolyline, mode);
            return; // 경로를 찾았으면 반복을 멈춤
          } else {
            print(
                'Google Maps Directions API 응답 실패: 경로 데이터를 찾을 수 없습니다. Mode: $mode');
            print('API 응답 데이터: ${response.body}'); // API 응답 데이터 출력
          }
        } else {
          print(
              'Google Maps Directions API 요청 실패: 상태 코드 ${response.statusCode}');
          print('API 응답 데이터: ${response.body}'); // API 응답 데이터 출력
        }
      } catch (e) {
        print('Google Maps Directions API 호출 중 오류가 발생했습니다: $e');
        _showErrorDialog('Google Maps Directions API 호출 중 오류가 발생했습니다: $e');
      }
    }

    // 모든 모드에서 경로를 찾지 못했을 때 오류 표시
    _showErrorDialog('모든 이동 모드에서 경로를 찾을 수 없습니다.');
  }

  void _extractTransitDetails(Map<String, dynamic> route) {
    transitDetails.clear();
    for (var leg in route['legs']) {
      for (var step in leg['steps']) {
        if (step['travel_mode'] == 'TRANSIT') {
          var transitDetailsData = step['transit_details'];
          var lineName = transitDetailsData['line']['short_name'] ?? 'No line';
          var vehicleType =
              transitDetailsData['line']['vehicle']['type'] ?? 'Unknown';
          var departureStop =
              transitDetailsData['departure_stop']['name'] ?? 'Unknown stop';
          var arrivalStop =
              transitDetailsData['arrival_stop']['name'] ?? 'Unknown stop';
          var departureTime = _convertTimeToMinutes(
              transitDetailsData['departure_time']['text'] ?? 'Unknown time');
          var arrivalTime = _convertTimeToMinutes(
              transitDetailsData['arrival_time']['text'] ?? 'Unknown time');
          var numStops = transitDetailsData['num_stops'].toString();

          // 경유 정류장 정보 추출
          List<String> stopNames = [];
          if (transitDetailsData['line']['agencies'] != null &&
              transitDetailsData['line']['agencies'].isNotEmpty) {
            for (var stop in transitDetailsData['line']['stops'] ?? []) {
              stopNames.add(stop['name']);
            }
          }

          var transitDetail = {
            'vehicleType': vehicleType,
            'lineName': lineName,
            'departureStop': departureStop,
            'arrivalStop': arrivalStop,
            'departureTime': departureTime,
            'arrivalTime': arrivalTime,
            'numStops': numStops,
            'stopNames': stopNames, // 정류장 이름 리스트 추가
          };

          transitDetails.add(transitDetail);
        } else if (step['travel_mode'] == 'WALKING') {
          var walkingDistance = step['distance']['text'] ?? 'Unknown distance';
          var walkingDuration = _convertTimeToMinutes(
              step['duration']['text'] ?? 'Unknown duration');

          var walkingDetail = {
            'vehicleType': 'WALKING',
            'distance': walkingDistance,
            'duration': walkingDuration
          };
          transitDetails.add(walkingDetail);
        }
      }
    }
  }

  String _convertTimeToMinutes(String timeText) {
    if (timeText.contains('hour')) {
      final parts = timeText.split(' ');
      int hours = int.parse(parts[0]);
      int minutes = parts.length > 2 ? int.parse(parts[2]) : 0;
      return '${hours * 60 + minutes}분';
    } else if (timeText.contains('min')) {
      return timeText.replaceAll('min', '분').replaceAll('mins', '분');
    } else {
      return timeText;
    }
  }

  List<Map<String, double>> _decodePolyline(String polyline) {
    List<Map<String, double>> polylineCoords = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoords.add({"lat": lat / 1E5, "lng": lng / 1E5});
    }

    return polylineCoords;
  }

  Future<void> _drawRouteOnMap(
      List<Map<String, double>> linePath, String mode) async {
    final bool isWalking = mode == 'walking';

    // 경로 그리기
    _webViewController.evaluateJavascript(source: '''
      try {
        var lineSymbol = {
          path: 'M 0,-1 0,1',
          strokeOpacity: 1,
          scale: 4
        };
        drawRoute(${jsonEncode(linePath)}, $isWalking, lineSymbol);
        console.log('Route drawn successfully');
      } catch (error) {
        console.log('Error drawing route: ' + error.message);
      }
    ''');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  String _getTravelModeText(String mode) {
    switch (mode) {
      case 'driving':
        return '운전';
      case 'walking':
        return '도보';
      case 'bicycling':
        return '자전거';
      case 'transit':
        return '대중교통';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('길찾기 결과'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.assistant_direction),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Container(
          color: Colors.white, // 전체 배경색을 하얀색으로 설정
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xFF2979FF),
                ),
                child: Align(
                  alignment: Alignment.centerLeft, // 좌측에 정렬
                  child: Text(
                    '세부 정보',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              if (transitDetails.isNotEmpty)
                ...transitDetails.map((detail) {
                  if (detail['vehicleType'] == 'WALKING') {
                    return ListTile(
                      leading: Icon(Icons.directions_walk),
                      title: Text('도보'),
                      subtitle: Text(
                        '거리: ${detail['distance']}, 시간: ${detail['duration']}',
                      ),
                    );
                  } else {
                    return ExpansionTile(
                      leading: Icon(Icons.directions_bus),
                      title: Text(
                        '${detail['vehicleType'] == 'BUS' ? '버스' : '지하철'} - ${detail['lineName']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      children: [
                        ListTile(
                          title: Text('출발: ${detail['departureStop']}'),
                          trailing: Text('${detail['departureTime']}'),
                        ),
                        ListTile(
                          title: Text('도착: ${detail['arrivalStop']}'),
                          trailing: Text('${detail['arrivalTime']}'),
                        ),
                        ListTile(
                          title: Text('정류장 수: ${detail['numStops']}'),
                        ),
                        ...detail['stopNames'].map<Widget>((stopName) {
                          return ListTile(
                            title: Text('정류장: $stopName'),
                          );
                        }).toList(),
                      ],
                    );
                  }
                }).toList(),
              if (transitDetails.isEmpty)
                ListTile(
                  title: Text('대중교통 정보가 없습니다.'),
                ),
            ],
          ),
        ),
      ),


      body: Stack(
        children: [
          isLoading
              ? Center(
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
                ) // 로딩 GIF 표시
              : InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: Uri.dataFromString(
                      '''
                      <!DOCTYPE html>
                      <html>
                      <head>
                        <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
                        <meta charset="utf-8">
                        <script async defer src="https://maps.googleapis.com/maps/api/js?key=${dotenv.env['GOOGLE_MAPS_API_KEY']}&callback=initMap"></script>
                        <style>
                          html, body {
                            width: 100%;
                            height: 100%;
                            margin: 0;
                            padding: 0;
                            overflow: hidden;
                          }
                          #map {
                            width: 100%;
                            height: 100%;
                          }
                        </style>
                      </head>
                      <body>
                        <div id="map"></div>
                        <script>
                          function initMap() {
                            var map = new google.maps.Map(document.getElementById('map'), {
                              center: {lat: ${widget.startLatitude}, lng: ${widget.startLongitude}},
                              zoom: 14
                            });

                            // 시작 마커
                            var startMarker = new google.maps.Marker({
                              position: {lat: ${widget.startLatitude}, lng: ${widget.startLongitude}},
                              map: map,
                              title: '출발지'
                            });

                            // 도착 마커
                            var endMarker = new google.maps.Marker({
                              position: {lat: ${widget.endLatitude}, lng: ${widget.endLongitude}},
                              map: map,
                              title: '도착지'
                            });

                            // 경로 그리기 함수
                            window.drawRoute = function(linePath, isWalking, lineSymbol) {
                              var polylineOptions = {
                                path: linePath,
                                geodesic: true,
                                strokeColor: isWalking ? '#000000' : '#FF0000', // 도보 경로는 검정색
                                strokeOpacity: 1.0,
                                strokeWeight: 2,
                                icons: isWalking ? [{
                                  icon: lineSymbol,
                                  offset: '0',
                                  repeat: '20px'
                                }] : []
                              };

                              var polyline = new google.maps.Polyline(polylineOptions);
                              polyline.setMap(map);
                            };

                            console.log('경로 그리기 준비 완료');
                          }
                        </script>
                      </div>
                      </html>
                      ''',
                      mimeType: 'text/html',
                      encoding: Encoding.getByName('utf-8'),
                    ),
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLoading)
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(8.0),
              child: Text(
                '이동 수단: ${_getTravelModeText(selectedTravelMode)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Color(0xFF2979FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: isLoading ? null : _findRoute,
              child: Text(
                '경로 보기',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
