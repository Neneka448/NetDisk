import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import "package:images_picker/images_picker.dart";
import 'package:netdisk/GlobalVariables.dart';
import '../Store.dart';
import "package:http/http.dart" as http;
import 'package:dio/dio.dart' as dio;
class UserInfoSettingsPage extends StatefulWidget {
  const UserInfoSettingsPage({Key? key}) : super(key: key);

  @override
  State<UserInfoSettingsPage> createState() => _UserInfoSettingsPageState();
}

class _UserInfoSettingsPageState extends State<UserInfoSettingsPage> {
  var newNickname='';
  @override
  Widget build(BuildContext context) {
    final Store store = Get.find();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        toolbarTextStyle: const TextStyle(color: Colors.black),
        elevation: 0,
        title: Text(
          "个人信息",
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
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(builder: (context,_setState){
                      return Container(
                        constraints: BoxConstraints(maxHeight: 150),
                        child: Column(
                          children: [
                            Expanded(child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide.none
                                ),
                                onPressed: ()async {
                                  var res= await ImagesPicker.openCamera(
                                      pickType: PickType.image
                                  );
                                  if(res!=null){
                                    var t=res[0];
                                    var formData=dio.FormData.fromMap({
                                      "avatar":await dio.MultipartFile.fromFile(t.path,filename: t.path.split('/').last)
                                    });
                                    var response=await dio.Dio().post(baseURl+"/user/newavatar",data: formData,options: dio.Options(
                                      headers: {"Authorization":"Basic ${base64Encode(utf8.encode(store.token.value))}"}
                                    ));
                                    if(response.data['status']=='ok'){
                                      _setState((){
                                        print(response.data['data']['url']);
                                        store.user.value.avatar=response.data['data']['url'];
                                        store.user.refresh();
                                      });
                                      Navigator.pop(context);
                                    }
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  child: Text("拍照",style: TextStyle(color: Colors.black,fontSize: 18),),
                                ))),
                            Expanded(child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide.none,
                                ),
                                onPressed: ()async {
                                  print(111);
                                  var res= await ImagesPicker.pick(
                                      pickType: PickType.image
                                  );
                                  if(res!=null){
                                    var t=res[0];
                                    var formData=dio.FormData.fromMap({
                                      "avatar":await dio.MultipartFile.fromFile(t.path,filename: t.path.split('/').last)
                                    });
                                    var response=await dio.Dio().post(baseURl+"/user/newavatar",data: formData,options: dio.Options(
                                        headers: {"Authorization":"Basic ${base64Encode(utf8.encode(store.token.value))}"}
                                    ));
                                    if(response.data['status']=='ok'){
                                      _setState((){
                                        print(response.data['data']['url']);
                                        store.user.value.avatar=response.data['data']['url'];
                                        store.user.refresh();
                                      });
                                      Navigator.pop(context);
                                    }
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  child: Text("从相册选择",style: TextStyle(color: Colors.black,fontSize: 18),),
                                ))),
                          ],
                        ),
                      );
                    });
                  });
            },
            child: Container(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "头像",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CircleAvatar(
                          child: Obx(() {
                            return Image.network(store.user.value.avatar);
                          }),
                        ),
                      ),
                      Divider(
                        indent: 10,
                      ),
                      Text(">")
                    ],
                  )
                ],
              ),
            ),
          )),
          Expanded(
              child: OutlinedButton(
            style: OutlinedButton.styleFrom(side: BorderSide.none),
            onPressed: () {
              showModalBottomSheet(context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context){
                    return StatefulBuilder(builder: (context,setState){
                      return AnimatedPadding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          duration: Duration.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
                            child: Container(
                              constraints: BoxConstraints(
                                  maxHeight: 100
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "请输入昵称",
                                  filled: true,
                                  fillColor: Colors.white
                                ),
                                onSubmitted: (v)async{
                                  setState((){
                                    newNickname=v;
                                  });
                                  var res=await http.post(Uri.parse(baseURl+"/user/newname"),headers:{
                                    "Authorization":"Basic ${base64Encode(utf8.encode(store.token.value))}"
                                  });
                                  if(jsonDecode(res.body)['data']['result']=='ok'){
                                    store.user.value.nickname=newNickname;
                                    store.user.refresh();
                                  }
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),);
                    });
                  });
            },
            child: Container(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "昵称",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  Obx((){
                    return Text("${store.user.value.nickname} >", style: TextStyle(fontSize: 14, color: Colors.grey));
                  })
                ],
              ),
            ),
          )),
          Spacer(
            flex: 8,
          )
        ],
      ),
    );
  }
}
