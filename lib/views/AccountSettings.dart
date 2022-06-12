import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Store.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  State<AccountSettingsPage> createState() => _UserInfoSettingsPageState();
}

class _UserInfoSettingsPageState extends State<AccountSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final Store store = Get.find();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        toolbarTextStyle: const TextStyle(color: Colors.black),
        elevation: 0,
        title: Text("安全中心",style: TextStyle(color: Colors.black),),
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
              child:OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: BorderSide.none
                ),
                onPressed: () {},
                child: Container(
                  padding: EdgeInsets.only(left: 10,right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("登陆密码",style: TextStyle(fontSize: 18,color: Colors.black),),
                      Text("已设置 >")
                    ],
                  ),
                ),
              )
          ),
          Expanded(
              child:OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: BorderSide.none
                ),
                onPressed: () {},
                child: Container(
                  padding: EdgeInsets.only(left: 10,right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("账号注销",style: TextStyle(fontSize: 18,color: Colors.black),),
                      Text(">",style: TextStyle(fontSize: 14,color: Colors.grey))
                    ],
                  ),
                ),
              )
          ),
          Spacer(flex: 8,)
        ],
      ),
    );
  }
}
