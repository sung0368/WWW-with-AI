import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatelessWidget {
  final String url;

  WebViewScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '어떻게 가지?',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w500,
            fontSize: 22,
          ),
        ),
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,  // JavaScript 활성화
        onWebViewCreated: (WebViewController webViewController) {
          // WebView가 생성될 때 호출됩니다. 필요한 추가 설정을 이곳에서 수행할 수 있습니다.
          // 예를 들어, 웹뷰의 컨트롤러를 변수에 저장하거나, 추가적인 초기화 작업을 수행할 수 있습니다.
        },
        onPageFinished: (String url) {
          // 페이지가 완전히 로드되었을 때 호출됩니다.
          print('Page finished loading: $url');
        },
        onWebResourceError: (WebResourceError error) {
          // 리소스 로딩 중 에러가 발생했을 때 호출됩니다.
          print('Error: $error');
        },
        navigationDelegate: (NavigationRequest request) async {
          if (request.url.startsWith('intent://')) {
            // 해당 URL을 처리할 수 있는 앱으로 리디렉션
            String externalUrl = request.url.replaceFirst('intent://', 'https://');
            if (await canLaunchUrl(Uri.parse(externalUrl))) {
              await launchUrl(Uri.parse(externalUrl));
            } else {
              print('해당 URL을 열 수 없습니다: $externalUrl');
            }
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  }
}
