import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Store.dart';

class OtherSettingsPage extends StatefulWidget {
  const OtherSettingsPage({Key? key}) : super(key: key);

  @override
  State<OtherSettingsPage> createState() => _UserInfoSettingsPageState();
}

class _UserInfoSettingsPageState extends State<OtherSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final Store store = Get.find();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        toolbarTextStyle: const TextStyle(color: Colors.black),
        elevation: 0,
        title: Text(
          "其他设置",
          style: TextStyle(color: Colors.black),
        ),
        leading: Container(
            alignment: Alignment.center,
            child: BackButton(
              color: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
            )),
      ),
      body: Column(
        children: [
          Expanded(
              child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: BorderSide.none),
            onPressed: () {},
            child: Container(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "下载限速",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  Text(">")
                ],
              ),
            ),
          )),
          Expanded(
              child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: BorderSide.none),
            onPressed: () {},
            child: Container(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "上传限速",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  Text(">", style: TextStyle(fontSize: 14, color: Colors.grey))
                ],
              ),
            ),
          )),
          // Expanded(
          //     child: OutlinedButton(
          //       style: OutlinedButton.styleFrom(side: BorderSide.none),
          //       onPressed: () {},
          //       child: Container(
          //         padding: EdgeInsets.only(left: 10, right: 10),
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: [
          //             Text(
          //               "下载目录设置",
          //               style: TextStyle(fontSize: 18, color: Colors.black),
          //             ),
          //             Text(" >", style: TextStyle(fontSize: 14, color: Colors.grey))
          //           ],
          //         ),
          //       ),
          //     )),
          Expanded(
              child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: BorderSide.none),
            onPressed: () {
              store.clearManifest();
            },
            child: Container(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "清除数据",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  Text("上传、下载数据 >", style: TextStyle(fontSize: 14, color: Colors.grey))
                ],
              ),
            ),
          )),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10,right: 10,top:4,bottom: 4),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: BorderSide.none,backgroundColor: Colors.red),
                    onPressed: ()async {
                      store.loginState.value=false;
                      var shared=await SharedPreferences.getInstance();
                      shared.remove("token");
                      store.token.value="";
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "退出登录",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )),
            ),
          ),
          Spacer(
            flex: 6,
          )
        ],
      ),
    );
  }
}
