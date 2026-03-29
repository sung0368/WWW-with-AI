# 우리 여기서 볼까? 🗺️ - 공학경진대회 동상 작품

![포스터](gitpic/wwwwithai.png)

여러 명이 만날 때 **중간 지점을 자동으로 찾고**, AI가 그날의 일정까지 추천해주는 Flutter 앱입니다. 

---

## 주요 기능

### 📍 중간 지점 찾기
- 여러 사람의 주소 또는 장소명을 자유롭게 추가 입력
- 카카오 로컬 API로 각 위치의 좌표를 변환 후 평균값으로 중간 지점 계산 (Haversine 공식)
- 중간 지점 및 각 출발지 마커를 카카오맵 위에 표시
- 랜덤 장소 추천 모드 지원

### 🤖 AI 하루 일정 생성
- 중간 지점 주변 카페, 식당, 놀거리(보드게임, 볼링장, 술집 등)를 카카오 로컬 API로 자동 검색
- Firebase에 저장된 즐겨찾기 장소를 우선 반영하여 맞춤 일정 구성
- GPT-3.5-turbo를 활용해 자연스러운 구어체의 하루 모임 일정 텍스트 생성

### 🚗 길찾기 및 공유
- 카카오맵 웹뷰를 통해 중간 지점까지 길찾기 연결
- Google Directions API로 도보 / 자동차 / 자전거 / 대중교통 경로 제공
- 중간 지점의 카카오맵 링크를 외부 앱으로 공유

### 🔖 장소 저장
- 카페, 식당, 놀거리를 카테고리별로 Firebase Firestore에 저장
- 저장된 장소 목록을 상호명 / 주소로 검색 및 조회
- 저장 횟수가 많은 장소를 AI 일정 생성 시 우선 추천

### ☁️ 날씨 검색
- OpenWeatherMap API를 통해 원하는 지역의 날씨 정보 조회
- 앱 내에서 장소 검색 후 시간대별 날씨 확인 가능

### 🗺️ 서울 구별 지도 오버레이
- 서울 25개 자치구의 GeoJSON 데이터를 지도 위에 시각화
- 구별 저장 장소 검색 및 대중교통 경로 확인

### 🔐 로그인 및 회원 관리
- Firebase Authentication을 통한 이메일 회원가입 / 로그인
- 개인 프로필 수정 및 저장 장소 개인화 관리

---

## 화면 구성

| 화면 | 설명 |
|------|------|
| 스플래시 / 인트로 | 최초 실행 시 온보딩 페이지 표시 |
| 로그인 / 회원가입 | Firebase Auth 기반 이메일 인증 |
| 홈 (KakaoMap) | 위치 입력 및 중간 지점 검색 |
| 지도 (MapScreen) | 중간 지점 마커 표시, AI 일정 생성, 길찾기, 공유 |
| AI 플랜 | GPT가 생성한 하루 일정 텍스트 표시 |
| 저장 목록 | Firestore에 저장된 장소 목록 |
| 지도 오버레이 | 서울 구별 GeoJSON 지도 |
| 날씨 | 날씨 검색 |
| 설정 / 마이페이지 | 프로필 편집 및 앱 설정 |

---

## 기술 스택

| 분류 | 기술 |
|------|------|
| 프레임워크 | Flutter (Dart) |
| 지도 | Kakao Map WebView, Google Maps Flutter |
| AI | OpenAI GPT-3.5-turbo |
| 백엔드 | Firebase Auth, Cloud Firestore |
| API | 카카오 로컬 API, Google Directions API |
| 위치 | geolocator, geocoding |
| 기타 | flutter_dotenv, share_plus, shared_preferences, flutter_inappwebview |

---

## 환경 설정

### 1. 필수 API 키

프로젝트 루트에 `.env` 파일을 생성하고 아래 키를 입력합니다.

```
KAKAO_MAP_KEY=your_kakao_map_key
KAKAO_REST_API_KEY=your_kakao_rest_api_key
OPENAI_API_KEY=your_openai_api_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 2. Firebase 설정

- `google-services.json` (Android): `android/app/` 경로에 배치
- Firebase 콘솔에서 Authentication(이메일/비밀번호)과 Cloud Firestore를 활성화

### 3. 실행

```bash
flutter pub get
flutter run
```

---

## Firestore 컬렉션 구조

```
saved_cafes/
  - name, address, latitude, longitude

saved_restaurants/
  - name, address, latitude, longitude

saved_entertainment/
  - name, address, latitude, longitude

users/
  - uid, name, email, ...
```

---

## 개발 환경

- Flutter SDK `>=2.12.0 <3.0.0`
- Dart Null Safety 적용

---

## 시연 영상

[![시연 영상](https://img.youtube.com/vi/9Rb5yM7H5bE/0.jpg)](https://www.youtube.com/watch?v=9Rb5yM7H5bE)

---

## 팀원

| **서연수** | **성시우** | **박영빈** | **유두연** |
| :------: |  :------: | :------: | :------: |
| [<img src="https://github.com/user-attachments/assets/b8ee6c21-e044-4dcf-ade4-7ea26aa8c78c" height=150 width=150> <br/> @brynn00](https://github.com/brynn00) | [<img src="https://github.com/user-attachments/assets/05a676d3-31ae-4dc5-ba33-2bb342d952cf" height=150 width=150> <br/> @sung0368](https://github.com/sung0368) | [<img src="https://github.com/user-attachments/assets/d9ec4cf1-2319-4320-bf95-b074ad6d5bd7" height=150 width=150> <br/> @dudqls1106](https://github.com/dudqls1106) | [<img src="https://github.com/user-attachments/assets/57142a10-8c2b-43e5-b308-928823a941c4" height=150 width=150> <br/> @duyeonyoo99](https://github.com/duyeonyoo99) |
