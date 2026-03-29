import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart';
import 'kakao_map_test.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _signIn() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => KakaoMap()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = '로그인에 실패했습니다. 다시 한 번 확인해주세요.';
      });
    }
  }

  void _navigateToRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    ).then((_) {
      setState(() {
        _errorMessage = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Signin(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  errorMessage: _errorMessage,
                  onSignIn: _signIn,
                  onRegister: _navigateToRegisterPage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Signin extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? errorMessage;
  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  const Signin({
    required this.emailController,
    required this.passwordController,
    required this.errorMessage,
    required this.onSignIn,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 360,
          decoration: BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              SizedBox(height: 50),
              Text(
                '로그인(로고 추가!!)',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
              SizedBox(height: 50),
              InputField(
                controller: emailController,
                label: '이메일',
                hintText: '이메일을 입력해 주세요',
                icon: Icons.email,
              ),
              InputField(
                controller: passwordController,
                label: '비밀번호',
                hintText: '비밀번호를 입력해 주세요',
                icon: Icons.lock,
                obscureText: true,
              ),
              SizedBox(height: 10),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              SizedBox(height: 90),
              Container(
                width: 328,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF2979FF),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF2979FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: onSignIn,
                  child: Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'NotoSansKR',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '아직 회원이 아니신가요? ',
                      style: TextStyle(
                        color: Color(0xFF7D8491),
                        fontSize: 14,
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: '회원가입',
                      style: TextStyle(
                        color: Color(0xFF2979FF),
                        fontSize: 14,
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = onRegister,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool obscureText;

  const InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
  });

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              widget.label,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFFD6D6D6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: Color(0xFF7D8491), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    obscureText: _obscureText,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: Color(0xFF7D8491),
                        fontSize: 14,
                        fontFamily: 'Suit',
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12), // 여기를 조정하세요
                      suffixIcon: widget.obscureText
                          ? IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Color(0xFF7D8491),
                              ),
                              onPressed: _togglePasswordVisibility,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
