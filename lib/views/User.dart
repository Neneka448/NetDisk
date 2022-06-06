import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../GlobalVariables.dart' show baseURl;
import '../GlobalClass.dart' show RawResponse, Token, User;
import '../Store.dart' show Store;
import 'package:shared_preferences/shared_preferences.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool isLogin = false;
  void setLogin(bool loginState) {
    setState(() {
      isLogin = loginState;
    });
  }
  final Store store = Get.find();
  @override
  void initState() {
    super.initState();
    if(store.loginState.value==false){
      SharedPreferences.getInstance().then((preference){
        var token=preference.getString('token');
        if(token != null){
          http.post(Uri.parse(baseURl + "/auth/check"),headers: {
            'Authorization':'Basic $token'
          }).then((response){
            var rawRes=jsonDecode(response.body);
            var res=RawResponse(
                status: rawRes['status'],
                desc: rawRes['desc'],
                data: null
            );
            if(res.status=='ok'){
              store.token.value=token;
              store.changeLoginState(true);
              _initUser();
            }else{
              preference.remove('token');
            }
          });
        }
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Obx(()=>store.loginState.value
          ? const UserPageHasLogin()
          : UserPageNotLogin(setLogin: setLogin,initUser: _initUser,)),
    );
  }
  void _initUser(){
    http.get(Uri.parse(baseURl + "/user/info"),headers: {
      'Authorization':'Basic ${store.token.value}'
    }).then((res){
      dynamic rawData=jsonDecode(res.body)['data'];
      store.setUser(User.fromJson(rawData));
    });
  }
}

class UserPageNotLogin extends StatefulWidget {
  final Function setLogin;
  final Function initUser;
  const UserPageNotLogin({Key? key, required this.setLogin,required this.initUser}) : super(key: key);

  @override
  State<UserPageNotLogin> createState() => _UserPageNotLoginState();
}

class _UserPageNotLoginState extends State<UserPageNotLogin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _account = '';
  String _psw = '';
  @override
  Widget build(BuildContext context) {
    final Store store = Get.find();
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(hintText: "Account"),
                onSaved: (v) => _account = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(hintText: "Password"),
                onSaved: (v) => _psw = v ?? '',
              )
            ],
          ),
        ),
        ElevatedButton(
            onPressed: () {
              _formKey.currentState?.save();
              http.post(Uri.parse(baseURl + "/auth/login"),
                  body: {"acc": _account, "psw": _psw}).then((res) {
                dynamic rawObj = jsonDecode(res.body);
                var rawRes = RawResponse<Token>(
                    status: rawObj['status'],
                    desc: rawObj['desc'],
                    data: Token.fromJson(rawObj['data']));
                if (rawRes.status == 'ok') {
                  widget.setLogin(true);
                  store.token.value=rawRes.data.token;
                  store.changeLoginState(true);
                  widget.initUser();
                  SharedPreferences.getInstance().then((value) => value.setString('token', rawRes.data.token));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(rawRes.data.token),
                  ));
                }
              });
            },
            child: const Text("校验"))
      ]),
    );
  }
}

class UserPageHasLogin extends StatefulWidget {
  const UserPageHasLogin({Key? key}) : super(key: key);

  @override
  State<UserPageHasLogin> createState() => _UserPageHasLoginState();
}

class _UserPageHasLoginState extends State<UserPageHasLogin> {
  @override
  Widget build(BuildContext context) {
    final Store store=Get.find();
    return Flex(
      direction: Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              child: Icon(Icons.people),
            ),
            Container(
                child: Obx(()=>Text(store.user.value.name, style: TextStyle(fontSize: 20))),
                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0)),
          ],
        )),
        Container(
          child: Column(
            children: [
              const Text(
                "空间",
                textAlign: TextAlign.left,
              ),
              Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Obx(()=>LinearProgressIndicator(
                        value: store.user.value.usedSpace/store.user.value.maxSpace,
                        minHeight: 14,
                        valueColor:const AlwaysStoppedAnimation(Colors.red),
                        backgroundColor: Colors.blue,
                      )),
                    )),
              ),
              Obx(()=>Text(
                "${store.user.value.usedSpace}/${store.user.value.maxSpace}GB",
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.grey),
              ))
            ],
          ),
        ),
        Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                    child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/favorite');
                    },
                    child: const Text("收藏"),
                  ),
                )),
                Expanded(
                    child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/recycle');
                    },
                    child: const Text("回收站"),
                  ),
                ))
              ],
            ))
      ],
    );
  }
}
