import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  String? userName;
  String? userEmail;
  String? userPhone;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

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
          userEmail = userDoc['email'];
          userPhone = userDoc['phone'];
        });
      }
    }
  }

  Future<void> updateUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': userName,
        'email': userEmail,
        'phone': userPhone,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '프로필 수정',
          style: TextStyle(
              color: Colors.black,
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w500,
              fontSize: 22,
            ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 360,
                  decoration: BoxDecoration(color: Colors.white),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        InputField(
                          label: '이름',
                          hintText: '이름을 입력하세요',
                          icon: Icons.person,
                          initialValue: userName,
                          onChanged: (value) {
                            userName = value;
                          },
                        ),
                        // InputField(
                        //   label: '이메일',
                        //   hintText: '이메일을 입력하세요',
                        //   icon: Icons.email,
                        //   initialValue: userEmail,
                        //   onChanged: (value) {
                        //     userEmail = value;
                        //   },
                        // ),
                        InputField(
                          label: '전화번호',
                          hintText: '전화번호를 입력하세요',
                          icon: Icons.phone,
                          initialValue: userPhone,
                          onChanged: (value) {
                            userPhone = value;
                          },
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
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                updateUserInfo().then((_) {
                                  Navigator.pop(context);
                                });
                              }
                            },
                            child: Text(
                              '저장',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'NotoSansKR',
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const InputField({
    required this.label,
    required this.hintText,
    required this.icon,
    this.initialValue,
    required this.onChanged,
  });

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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFFD6D6D6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF7D8491), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: initialValue,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Color(0xFF7D8491),
                        fontSize: 14,
                        fontFamily: 'Suit',
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: onChanged,
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
