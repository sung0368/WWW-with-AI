import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'RouteFinderScreen.dart';

class KakaoMapView extends StatefulWidget {
  final String placeName;
  final String geoJsonFile;
  final List<Map<String, dynamic>> locations;
  final Function(Map<String, dynamic>) onMarkerTap;
  final Function() onSearchIconPressed;

  KakaoMapView({
    Key? key,
    required this.placeName,
    required this.geoJsonFile,
    required this.locations,
    required this.onMarkerTap,
    required this.onSearchIconPressed,
  }) : super(key: key);

  @override
  _KakaoMapViewState createState() => _KakaoMapViewState();
}

class _KakaoMapViewState extends State<KakaoMapView> {
  List<List<double>>? boundaryCoordinates;
  double? centerLatitude = 37.5889;
  double? centerLongitude = 127.0063;
  bool isGeoJsonLoaded = false;
  late InAppWebViewController _webViewController;
  List<Map<String, dynamic>> selectedMarkers = [];
  Map<String, dynamic>? startMarker;
  Map<String, dynamic>? endMarker;

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  @override
  void didUpdateWidget(covariant KakaoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.geoJsonFile != oldWidget.geoJsonFile) {
      _clearAllData();
      _loadGeoJson();
    }
  }

  void _clearAllData() {
    setState(() {
      selectedMarkers.clear();
      startMarker = null;
      endMarker = null;
      isGeoJsonLoaded = false;
    });
    _clearRoute();
  }

  Future<void> _loadGeoJson() async {
    try {
      final geoJsonData = await rootBundle.loadString(widget.geoJsonFile);
      final jsonData = json.decode(geoJsonData);

      if (jsonData['features'] != null &&
          jsonData['features'].isNotEmpty &&
          jsonData['features'][0]['geometry'] != null &&
          jsonData['features'][0]['geometry']['coordinates'] != null) {
        setState(() {
          boundaryCoordinates =
              (jsonData['features'][0]['geometry']['coordinates'][0] as List)
                  .map<List<double>>(
                      (coord) => [coord[1].toDouble(), coord[0].toDouble()])
                  .toList();

          double latSum = 0;
          double lngSum = 0;
          boundaryCoordinates!.forEach((coord) {
            latSum += coord[0];
            lngSum += coord[1];
          });

          centerLatitude = latSum / boundaryCoordinates!.length;
          centerLongitude = lngSum / boundaryCoordinates!.length;
          isGeoJsonLoaded = true;
        });
      } else {
        print('GeoJSON 데이터가 비어있거나 잘못되었습니다.');
        setState(() {
          isGeoJsonLoaded = false;
        });
      }
    } catch (e) {
      print('GeoJSON 파일을 로드할 수 없습니다: $e');
      setState(() {
        isGeoJsonLoaded = false;
      });
    }
  }

  void _removeMarker(int index) {
    setState(() {
      if (index == 0) {
        startMarker = null;
      } else if (index == 1) {
        endMarker = null;
      }
      selectedMarkers.removeAt(index);
      _clearRoute();
    });
  }

  void _addMarker(Map<String, dynamic> marker) {
    setState(() {
      if (startMarker == null) {
        startMarker = marker;
        selectedMarkers.add(marker);
      } else if (endMarker == null) {
        endMarker = marker;
        selectedMarkers.add(marker);
        _drawStraightLine(startMarker!, endMarker!);
      }
    });
  }

  void _clearRoute() {
    if (_webViewController != null) {
      _webViewController.evaluateJavascript(source: '''
        (function() {
          if (window.straightLine) {
            window.straightLine.setMap(null);
          }
        })();
      ''');
    }
  }

  void _drawStraightLine(Map<String, dynamic> start, Map<String, dynamic> end) {
    if (_webViewController != null) {
      _webViewController.evaluateJavascript(source: '''
        (function() {
          if (window.straightLine) {
            window.straightLine.setMap(null);
          }

          var linePath = [
            new kakao.maps.LatLng(${start['latitude']}, ${start['longitude']}),
            new kakao.maps.LatLng(${end['latitude']}, ${end['longitude']})
          ];

          window.straightLine = new kakao.maps.Polyline({
            path: linePath,
            strokeWeight: 5,
            strokeColor: '#FF0000',
            strokeOpacity: 0.8,
            strokeStyle: 'solid'
          });

          window.straightLine.setMap(map);
        })();
      ''');
    }
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

  void _handleSearchIconPressed() {
    _clearAllData();
    widget.onSearchIconPressed();
  }

  void _handleFindRouteButtonPressed() {
    if (startMarker != null && endMarker != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RouteFinderScreen(
            startLatitude: startMarker!['latitude'],
            startLongitude: startMarker!['longitude'],
            endLatitude: endMarker!['latitude'],
            endLongitude: endMarker!['longitude'],
          ),
        ),
      );
    } else {
      _showErrorDialog('출발지와 도착지를 모두 선택해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String kakaoMapKey = dotenv.env['KAKAO_MAP_KEY2']!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: InAppWebView(
              key: isGeoJsonLoaded ? Key(widget.geoJsonFile) : Key('defaultKey'),
              initialUrlRequest: URLRequest(
                url: Uri.dataFromString('''
                  <!DOCTYPE html>
                  <html>
                  <head>
                    <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
                    <meta charset="utf-8">
                    <script type="text/javascript"
                        src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=$kakaoMapKey&libraries=services,geometry"></script>
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
                      var mapContainer = document.getElementById('map'); 
                      var mapOption = {
                        center: new kakao.maps.LatLng(37.5889, 127.0063),
                        level: 4 
                      };

                      var map = new kakao.maps.Map(mapContainer, mapOption); 
                      var markers = [];
                      var infowindows = [];
                      var bounds = new kakao.maps.LatLngBounds();

                      ${isGeoJsonLoaded ? _getMapScripts() : ''}
                    </script>
                  </body>
                  </html>
                ''',
                  mimeType: 'text/html', encoding: Encoding.getByName('utf-8')),
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                _webViewController.addJavaScriptHandler(
                    handlerName: 'markerClicked',
                    callback: (args) {
                      widget.onMarkerTap(args[0]);
                      _addMarker(args[0]);
                    });
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
                  _buildLocationRow(startMarker, 0),
                  SizedBox(height: 15),
                  _buildLocationRow(endMarker, 1),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Color(0xFF2979FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _handleFindRouteButtonPressed,
                    child: Text(
                      '경로 찾기',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(Map<String, dynamic>? marker, int index) {
    if (marker == null) {
      return _buildDefaultRow(index);
    } else {
      return Row(
        children: [
          Text(
            index == 0 ? '출발' : '도착',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: index == 0 ? Color(0xFF2979FF) : Colors.red,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marker['name'] ?? '',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  marker['address'] ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => _removeMarker(index),
          ),
        ],
      );
    }
  }

  Widget _buildDefaultRow(int index) {
    return Row(
      children: [
        Icon(
          index == 0 ? Icons.my_location : Icons.place,
          color: index == 0 ? Color(0xFF2979FF) : Colors.red,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            index == 0 ? '출발지 설정' : '도착지 설정',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  String _getMapScripts() {
    final markersScript = widget.locations.isNotEmpty
        ? widget.locations.map((location) {
            return '''
            (function() {
              var marker = new kakao.maps.Marker({
                position: new kakao.maps.LatLng(${location['latitude']}, ${location['longitude']}),
                map: map
              });

              bounds.extend(new kakao.maps.LatLng(${location['latitude']}, ${location['longitude']}));

              var infowindow = new kakao.maps.InfoWindow({
                content: '<div style="padding:10px; font-size:14px;">' +
                         '<b>${location['name']}</b><br>' +
                         '${location['address']}' +
                         '</div>'
              });

              kakao.maps.event.addListener(marker, 'click', function() {
                closeAllInfowindows();
                infowindow.open(map, marker);

                window.flutter_inappwebview.callHandler('markerClicked', {
                  "name": "${location['name']}",
                  "address": "${location['address']}",
                  "latitude": ${location['latitude']},
                  "longitude": ${location['longitude']}
                });
              });

              markers.push(marker);
              infowindows.push(infowindow);
            })();
          ''';
          }).join('')
        : '';

    final closeAllInfowindowsScript = '''
      function closeAllInfowindows() {
        for (var i = 0; i < infowindows.length; i++) {
          infowindows[i].close();
        }
      }
    ''';

    final polygonPathScript =
        boundaryCoordinates != null && boundaryCoordinates!.isNotEmpty
            ? '''
            var polygonPath = [
              ${boundaryCoordinates!.map((coord) => 'new kakao.maps.LatLng(${coord[0]}, ${coord[1]})').join(',')}
            ];

            var polygon = new kakao.maps.Polygon({
                path: polygonPath,
                strokeWeight: 2,
                strokeColor: '#004c80',
                strokeOpacity: 0.8,
                fillColor: 'transparent',
                fillOpacity: 0.0
            });

            polygon.setMap(map);
            
            polygonPath.forEach(function(latlng) {
              bounds.extend(latlng);
            });
          '''
            : '';

    final setBoundsScript = '''
      if (markers.length > 0 || polygonPath.length > 0) {
        map.setBounds(bounds);
      } else {
        map.setCenter(new kakao.maps.LatLng($centerLatitude, $centerLongitude));
      }
    ''';

    return '''
      $closeAllInfowindowsScript
      $markersScript
      $polygonPathScript
      $setBoundsScript
    ''';
  }
}
