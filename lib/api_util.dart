import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// Haversine 공식을 이용한 두 지점 간의 거리 계산
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // 지구 반지름 (킬로미터)

  final double dLat = _toRadians(lat2 - lat1);
  final double dLon = _toRadians(lon2 - lon1);
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

double _toRadians(double degree) => degree * pi / 180;

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<List<Map<String, dynamic>>> getSavedCafes() async {
  try {
    final snapshot = await _firestore.collection('saved_cafes').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  } catch (e) {
    print('Error fetching saved cafes: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> getSavedEntertainment() async {
  try {
    final snapshot = await _firestore.collection('saved_entertainment').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  } catch (e) {
    print('Error fetching saved entertainment: $e');
    return [];
  }
}

Future<List<Map<String, dynamic>>> getSavedRestaurants() async {
  try {
    final snapshot = await _firestore.collection('saved_restaurants').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  } catch (e) {
    print('Error fetching saved restaurants: $e');
    return [];
  }
}

final String openAiApiKey = dotenv.env['OPENAI_API_KEY']!;
final String kakaoApiKey = dotenv.env['KAKAO_REST_API_KEY']!;

Future<List<Map<String, dynamic>>> getNearbyCafes(String address) async {
  return _getPlacesFromKakao(address, '카페', 1.0);
}

Future<List<Map<String, dynamic>>> getNearbyRestaurants(String address) async {
  return _getPlacesFromKakao(address, '맛집', 1.0);
}

Future<List<Map<String, dynamic>>> getNearbyEntertainment(String address) async {
  final categories = ['보드게임', '볼링장', '산책', '술집', '백화점', '가볼만한곳']; //마트 등..
  final results = <Map<String, dynamic>>[];

  for (final category in categories) {
    final places = await _getPlacesFromKakao(address, category, 1.0);
    results.addAll(places);
  }

  return results;
}

Future<List<Map<String, dynamic>>> _getPlacesFromKakao(String address, String category, double radius) async {
  try {
    final coordinates = await _getCoordinatesFromAddress(address);

    if (coordinates == null) {
      throw Exception('Failed to get coordinates from address');
    }

    final lat = coordinates['lat']!;
    final lng = coordinates['lng']!;

    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=$category&x=$lng&y=$lat&radius=${(radius * 1000).toInt()}');
    final headers = {
      'Authorization': 'KakaoAK $kakaoApiKey',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final places = (data['documents'] as List)
          .map((doc) => {
                'name': doc['place_name'] as String,
                'address': doc['road_address_name'] as String? ?? doc['address_name'] as String,
                'latitude': double.parse(doc['y'].toString()),
                'longitude': double.parse(doc['x'].toString()),
              })
          .toList();
      return places;
    } else {
      throw Exception('Failed to get response from Kakao API');
    }
  } catch (e) {
    print('Error in _getPlacesFromKakao: $e');
    throw Exception('Failed to get response from Kakao API');
  }
}

Future<Map<String, double>?> _getCoordinatesFromAddress(String address) async {
  try {
    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/address.json?query=$address');
    final headers = {
      'Authorization': 'KakaoAK $kakaoApiKey',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final documents = data['documents'] as List;
      if (documents.isNotEmpty) {
        final location = documents[0];
        return {
          'lat': double.parse(location['y'].toString()),
          'lng': double.parse(location['x'].toString()),
        };
      }
      return null;
    } else {
      throw Exception('Failed to get coordinates from Kakao API');
    }
  } catch (e) {
    print('Error in _getCoordinatesFromAddress: $e');
    throw Exception('Failed to get coordinates from Kakao API');
  }
}
