import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _errorMessage;

  Future<void> _register() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      ),// 배경색을 흰색으로 설정
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              Text(
                '가입하기',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 26,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700
                ),
              ),
              SizedBox(height: 50),
              InputField(
                controller: _nameController,
                label: '이름',
                hintText: '이름을 입력해 주세요',
                icon: Icons.person,
              ),
              InputField(
                controller: _emailController,
                label: '이메일',
                hintText: '이메일을 입력해 주세요',
                icon: Icons.email,
              ),
              InputField(
                controller: _passwordController,
                label: '비밀번호',
                hintText: '비밀번호를 입력해 주세요',
                icon: Icons.lock,
                obscureText: true, // 비밀번호 입력 시 텍스트 숨김
              ),
              InputField(
                controller: _phoneController,
                label: '휴대폰',
                hintText: '전화번호를 입력해 주세요',
                icon: Icons.phone,
                keyboardType: TextInputType.phone, // 전화번호 입력 타입 설정
              ),
              SizedBox(height: 10),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 90),
              ElevatedButton(
                onPressed: _register,
                child: Text('회원가입'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF2979FF),
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w600
                  ),
                  minimumSize: Size(328, 60), // 버튼 크기
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;

  const InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text, // 기본 키보드 타입 설정
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              label,
              style: TextStyle(
                color: Color(0xFF7D8491),
                fontSize: 14,
                fontFamily: 'Suit',
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType, // 키보드 타입 설정
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Color(0xFF7D8491),
                  fontSize: 14,
                  fontFamily: 'Suit',
                ),
                prefixIcon: Icon(icon, color: Color(0xFF7D8491)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7D8491)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2979FF)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
