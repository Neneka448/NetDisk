import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:netdisk/GlobalClass.dart';

import '../GlobalVariables.dart';
import '../Store.dart';
import 'FavoriteList.dart';
import 'package:http/http.dart' as http;

class RecycleList extends StatefulWidget {
  const RecycleList({Key? key}) : super(key: key);

  @override
  State<RecycleList> createState() => _RecycleListState();
}

class _RecycleListState extends State<RecycleList> {
  var recycle = <ButtonList>[];
  final Store store = Get.find();

  @override
  void initState() {
    super.initState();
    (() async {
      final res=await http.get(Uri.parse(remoteUrl + "/?prefix=passageOther/recycle/${store.token.value}/&delimiter=/"));
      var trash=getFileFromXML(utf8.decode(res.bodyBytes));
      for (var i in trash) {
        var button = OutlinedButton(
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.lightBlue,
                                          side: BorderSide.none,
                                          primary: Color.fromARGB(255, 26, 92, 120)),
                                      onPressed: ()async {
                                        if(i.fileType=='folder'){
                                          var res=await http.get(Uri.parse(remoteUrl+'/?prefix=${i.fileID}'));
                                          var files=getFileFromXML(utf8.decode(res.bodyBytes));
                                          for (var element in files) {
                                            if(element.fileType=='file'){
                                              var filename=element.fileID.split(RegExp(r"/|\\\\")).sublist(3).join('/');
                                              var resCopy=await http.put(Uri.parse(remoteUrl+'/passageOther/disk/${store.token.value}/'+filename),
                                                  headers:{"x-oss-copy-source":'/img-passage/${Uri.encodeComponent(element.fileID)}'} );
                                              if(resCopy.statusCode==200){
                                                var res=await http.delete(Uri.parse(remoteUrl+'/'+Uri.encodeComponent(element.fileID)));
                                              }
                                            }
                                          }
                                        }else{
                                          var filename=i.fileID.split(RegExp(r"/|\\\\")).sublist(3).join('/');
                                          var resCopy=await http.put(Uri.parse(remoteUrl+'/passageOther/disk/${store.token.value}/'+filename),
                                              headers:{"x-oss-copy-source":'/img-passage/${Uri.encodeComponent(i.fileID)}'} );
                                          if(resCopy.statusCode==200){
                                            var res=await http.delete(Uri.parse(remoteUrl+'/'+Uri.encodeComponent(i.fileID)));
                                          }
                                          Navigator.pop(context);
                                        }
                                        setState(() {
                                          recycle = recycle.where((element) {
                                            if (element.tag == i) {
                                              return false;
                                            } else {
                                              return true;
                                            }
                                          }).toList();
                                        });
                                      },
                                      child: Container(
                                        height: 60,
                                        alignment: Alignment.center,
                                        child: Text(
                                          "还原",
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ))),
                              Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.red, side: BorderSide.none),
                                    onPressed: () async{

                                    },
                                    child: Container(
                                      height: 60,
                                      alignment: Alignment.center,
                                      child: Text(
                                        "彻底删除",
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ))
                            ],
                          ),
                        )
                      ],
                    );
                  },
                  constraints: BoxConstraints(maxHeight: 260),
                  backgroundColor: Colors.transparent);
            },
            style: OutlinedButton.styleFrom(side: BorderSide.none),
            child: Flex(
              mainAxisAlignment: MainAxisAlignment.start,
              direction: Axis.horizontal,
              children: [
                Container(
                  margin: EdgeInsets.only(right: 16),
                  child: Icon(Icons.folder),
                ),
                Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.fileName),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "过期时间:${getFormatTime(DateTime.fromMillisecondsSinceEpoch(i.lastModifiedTime.millisecondsSinceEpoch+30*24*60*60*1000))}",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            )
                          ],
                        )
                      ],
                    )),
              ],
            ));
        setState(() {
          recycle.add(ButtonList(button: button, tag: i));
        });
      }
    })();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    IconButton(onPressed: (){
                      Navigator.pop(context);
                    }, icon: Icon(Icons.arrow_back)),
                    Divider(indent: 10,),
                    Text("回收站",style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                    ),)
                  ],
                )
              ),
              Divider(height: 10,),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: recycle.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SizedBox(
                      height: 60,
                      child: recycle[index].button,
                    );
                  })
            ],
          )
      ),
    );
  }
}
