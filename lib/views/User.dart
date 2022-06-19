import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../GlobalVariables.dart' show baseURl, remoteUrl;
import '../GlobalClass.dart' show RawResponse, Token, User, formatSize;
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
    if (store.loginState.value == false) {
      SharedPreferences.getInstance().then((preference) {
        var token = preference.getString('token');
        if (token != null) {
          http.get(Uri.parse(remoteUrl + "/passageOther/user/$token")).then((response) {
            if (response.statusCode == 200) {
              store.token.value = token;
              store.changeLoginState(true);
              _initUser();
            } else {
              preference.remove('token');
            }

          });
        }
      });
    }
    if(store.token.value!=""){
      http.get(Uri.parse(remoteUrl + "/?prefix=passageOther/disk/${store.token.value}/")).then((res){
        var size=0;
        RegExp("<Size>(.*)</Size>").allMatches(res.body).toList().forEach((element) {
          if(element.group(1)!=null){
            size+=int.parse(element.group(1)!);
          }
        });
        store.user.value.usedSpace=size;
        store.user.refresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Obx(() => store.loginState.value
          ? const UserPageHasLogin()
          : UserPageNotLogin(
              setLogin: setLogin,
              initUser: _initUser,
            )),
    );
  }

  void _initUser() {
    http.get(Uri.parse("https://img-passage.oss-cn-hangzhou.aliyuncs.com/passageOther/user/${store.token.value}"))
        .then((res){
      dynamic rawData = jsonDecode(res.body);
      print(rawData);
      store.setUser(User.fromJson(rawData));
    });
    // http.get(Uri.parse(baseURl + "/user/info"),
    //     headers: {'Authorization': 'Basic ${store.token.value}'}).then((res) {
    //   dynamic rawData = jsonDecode(res.body)['data'];
    //   store.setUser(User.fromJson(rawData));
    // });
  }
}

class UserPageNotLogin extends StatefulWidget {
  final Function setLogin;
  final Function initUser;

  const UserPageNotLogin(
      {Key? key, required this.setLogin, required this.initUser})
      : super(key: key);

  @override
  State<UserPageNotLogin> createState() => _UserPageNotLoginState();
}

class _UserPageNotLoginState extends State<UserPageNotLogin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _account = '';
  String _psw = '';
  String _repeatPsw='';
  String _nickname="";
  int mode=0;
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
              mode==1?TextFormField(
                decoration: const InputDecoration(hintText: "Nickname"),
                onSaved: (v) => _account = v ?? '',
                onChanged: (v)=>_nickname=v,
              ):Container(),
              TextFormField(
                decoration: const InputDecoration(hintText: "Password"),
                onChanged: (v){_psw=v;},
                obscureText: true,
                onSaved: (v) => _psw = v ?? '',
              ),
              mode==0?Container():TextFormField(
                decoration: _psw==_repeatPsw?const InputDecoration(
                    hintText: "Repeat Password",
                ):const InputDecoration(
                  hintText: "Repeat Password",
                  errorText: "与输入密码不一致"
                ),
                obscureText: true,
                onChanged: (v){setState(() {
                  _repeatPsw=v;
                });},
                onSaved: (v) => _repeatPsw = v ?? '',
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            mode==0?TextButton(onPressed: (){
              setState(() {
                mode=1;
              });
            }, child: Text("转到注册")):TextButton(onPressed: (){
              setState(() {
                mode=0;
              });
            }, child: Text("转到登录")),
            ElevatedButton(
                onPressed: () async{
                  _formKey.currentState?.save();
                  if(mode==0){
                    final id=md5.convert(utf8.encode(_account+":"+_psw)).toString();
                    var res=await http.get(Uri.parse(remoteUrl+"/passageOther/user/$id"));
                    if(res.statusCode==404){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("登录失败,错误码${res.statusCode}"),
                      ));
                    }else if(res.statusCode==200){
                      widget.setLogin(true);
                      store.token.value = id;
                      store.changeLoginState(true);
                      widget.initUser();
                      SharedPreferences.getInstance().then(
                              (value) => value.setString('token', id));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("登陆成功"),
                      ));
                    }
                  }else{
                    if(_psw==_repeatPsw){
                      final id=md5.convert(utf8.encode(_account+":"+_psw)).toString();
                      var res=await http.put(Uri.parse("https://img-passage.oss-cn-hangzhou.aliyuncs.com/passageOther/user/$id"),
                      body: jsonEncode({
                        "user_id":id,
                        "user_name":_account,
                        "nickname":_nickname,
                        "max_space":1024,
                        "used_space":0,
                        "avatar":"https://img-passage.oss-cn-hangzhou.aliyuncs.com/passageOther/1121.jpg"
                      }));
                      if(res.statusCode==200){
                        widget.setLogin(true);
                        store.token.value = id;
                        store.changeLoginState(true);
                        widget.initUser();
                        SharedPreferences.getInstance().then(
                                (value) => value.setString('token', id));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("注册成功"),
                        ));
                      }else{
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("注册失败,错误码:${res.statusCode}"),
                        ));
                      }
                    }
                    //http.put("");
                  }
                  // http.post(Uri.parse(baseURl + "/auth/login"),
                  //     body: {"acc": _account, "psw": _psw}).then((res) {
                  //   dynamic rawObj = jsonDecode(res.body);
                  //   var rawRes = RawResponse<Token>(
                  //       status: rawObj['status'],
                  //       desc: rawObj['desc'],
                  //       data: Token.fromJson(rawObj['data']));
                  //   if (rawRes.status == 'ok') {
                  //     widget.setLogin(true);
                  //     store.token.value = rawRes.data.token;
                  //     store.changeLoginState(true);
                  //     widget.initUser();
                  //     SharedPreferences.getInstance().then(
                  //             (value) => value.setString('token', rawRes.data.token));
                  //
                  //   }
                  // });
                },
                child: mode==0?const Text("登录"):const Text("注册"))
          ],
        )
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
    final Store store = Get.find();
    return Flex(
      direction: Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Obx((){
                  return Image.network(store.user.value.avatar);
                },
              ),
            ),),
            Container(
                child: Obx(() => Text(store.user.value.nickname==""?store.user.value.name:store.user.value.nickname,
                    style: TextStyle(fontSize: 20))),
                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0)),
          ],
        )),
        Divider(
          color: Colors.transparent,
          height: 16,
        ),
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
                      child: Obx(() => LinearProgressIndicator(
                            value: store.user.value.usedSpace/1024/1024/1024 /
                                store.user.value.maxSpace,
                            minHeight: 14,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.red),
                            backgroundColor: Colors.blue,
                          )),
                    )),
              ),
              Obx(() => Text(
                    "${formatSize(store.user.value.usedSpace*1.0)}/${store.user.value.maxSpace}GB",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey),
                  ))
            ],
          ),
        ),
        Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Expanded(
                //     child: ClipRRect(
                //   borderRadius: BorderRadius.circular(26),
                //   child: OutlinedButton(
                //     style: OutlinedButton.styleFrom(
                //         side: BorderSide.none,
                //         backgroundColor: Color(0xFFECEBEB)),
                //     onPressed: () {
                //       Navigator.pushNamed(context, '/favorite');
                //     },
                //     child: const Text("收藏"),
                //   ),
                // )),
                // Divider(
                //   indent: 10,
                // ),
                Expanded(
                    child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        backgroundColor: Color(0xFFECEBEB)),
                    onPressed: () {
                      Navigator.pushNamed(context, '/recycle');
                    },
                    child: const Text("回收站"),
                  ),
                ))
              ],
            )),
        Divider(
          color: Colors.transparent,
          height: 14,
        ),
        Expanded(
            child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(left: 16, right: 16),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Color(0xFFECEBEB),
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 10, bottom: 10),
                      child: Text(
                        "设置",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings/userinfo');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "个人信息",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "昵称,头像 >",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            )
                          ],
                        ),
                      ),
                    ),
                    // Container(
                    //   width: double.infinity,
                    //   child: OutlinedButton(
                    //     style: OutlinedButton.styleFrom(
                    //       side: BorderSide.none,
                    //     ),
                    //     onPressed: () {
                    //       Navigator.pushNamed(context, '/settings/account');
                    //     },
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //       children: [
                    //         const Text(
                    //           "安全中心",
                    //           style: TextStyle(
                    //               color: Colors.black,
                    //               fontSize: 16,
                    //               fontWeight: FontWeight.bold),
                    //         ),
                    //         const Text(
                    //           "修改密码 >",
                    //           style:
                    //               TextStyle(color: Colors.grey, fontSize: 12),
                    //         )
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    Container(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                        ),
                        onPressed: () {
                          showAboutDialog(
                              context: context,
                              applicationName: "Netdisk",
                              applicationVersion: "v1.0.0",
                              applicationIcon: Icon(Icons.token)
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "关于",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "版本信息 >",
                              style:
                              TextStyle(color: Colors.grey, fontSize: 12),
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings/other');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "其他设置",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "网络,退出登录 >",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            )
                          ],
                        ),
                      ),
                    ),

                  ],
                ))),
        Divider(
          color: Colors.transparent,
          height: 16,
        )
      ],
    );
  }
}
