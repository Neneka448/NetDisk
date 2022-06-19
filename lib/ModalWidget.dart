import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:netdisk/GlobalClass.dart';
import 'package:http/http.dart' as http;
import 'package:netdisk/GlobalVariables.dart';
import 'package:netdisk/Store.dart';
import 'package:netdisk/views/FileList.dart';

Widget buildBottomSheetWidget(dynamic shared,BuildContext context,{Function? onDelete}) {
  final Store store=Get.find();
  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(26),topRight: Radius.circular(26)),
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Text(jsonDecode(shared['shareName']).join(','),style: TextStyle(
                  overflow: TextOverflow.ellipsis
                ),),
                Text(shared['source']),
                Text(getFormatTime(DateTime.fromMillisecondsSinceEpoch(shared['shareDate']),needYear: true)),
                Text(getFormatTime(DateTime.fromMillisecondsSinceEpoch(shared['expireDate']),needYear: true))
              ],
            ),
          ),
        ),
      ),
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("已复制到剪贴板"),
                      ));
                      Clipboard.setData(ClipboardData(text: "Netdisk Shared Code: ${shared['crypted']} and extract code is ${shared["psw"]}."));
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Text(
                        "提取码",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ))),
            Expanded(
                child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red, side: BorderSide.none),
              onPressed: () async{
                String source=shared['source'];
                String crypted=shared['crypted'];
                await http.delete(Uri.parse(remoteUrl+'/passageOther/share/deCrypto/'+crypted));
                var res=await http.get(Uri.parse(remoteUrl+'/?prefix=passageOther/share/files/'+source+'/'));
                var files=getFileFromXML(utf8.decode(res.bodyBytes));
                for(var file in files){
                  print(file.fileID);
                  await http.delete(Uri.parse(remoteUrl+'/'+file.fileID));
                }
                await http.delete(Uri.parse(remoteUrl+'/passageOther/share/real/'+source));
                store.shareList.remove(source);
                await http.put(Uri.parse(remoteUrl+'/passageOther/share/user/${store.token.value}'),body: jsonEncode(store.shareList));
                store.shareList.refresh();
                if(onDelete!=null){
                  onDelete();
                }
              },
              child: Container(
                height: 60,
                alignment: Alignment.center,
                child: Text(
                  "删除分享",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ))
          ],
        ),
      )
    ],
  );
}

Widget buildShareQueryWidget(File file,BuildContext context,{Function? onDelete}) {
  final Store store=Get.find();
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
                      Navigator.pop(context);
                      Navigator.pushNamed(context,'/',arguments: {"file":file});
                    },
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Text(
                        "打开文件",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ))),
            Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.red, side: BorderSide.none),
                  onPressed: () async{
                    var res=await http.post(Uri.parse(baseURl+'/share/cancel'),headers: {
                      "Authorization":"Basic ${base64Encode(utf8.encode(store.token.value))}"
                    },body: jsonEncode({
                      "id":file.fileID
                    }));
                    var result=jsonDecode(res.body)['data']['result'];
                    if(result=='ok'){
                      if(onDelete!=null){
                        onDelete();
                      }
                    }
                  },
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    child: Text(
                      "删除收藏",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ))
          ],
        ),
      )
    ],
  );
}
