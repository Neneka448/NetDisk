import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../GlobalClass.dart' show RawResponse, SharedItemInfo, getFormatTime;
import '../GlobalVariables.dart' show baseURl;
import 'dart:convert';

import '../ModalWidget.dart';

class SharePage extends StatefulWidget {
  const SharePage({Key? key}) : super(key: key);

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  var shares = <OutlinedButton>[];

  @override
  void initState() {
    super.initState();
    http.get(Uri.parse(baseURl + "/share/list")).then((res) {
      dynamic t = jsonDecode(res.body);
      print(t['data']);
      RawResponse<List<SharedItemInfo>> rawRes =
          RawResponse<List<SharedItemInfo>>(
              status: t['status'],
              desc: t['desc'],
              data:
                  List.from(t['data'].map((v) => SharedItemInfo.fromJson(v))));
      setState(() {
        shares = rawRes.data.map((v) {
          var time = DateTime.fromMillisecondsSinceEpoch(v.sharedTime);
          return OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context){
                      return buildBottomSheetWidget(v);
                    },
                    constraints: BoxConstraints(
                      maxHeight: 260
                    ),
                    backgroundColor: Colors.transparent
                 );
              },
              style: OutlinedButton.styleFrom(side: BorderSide.none),
              child: Flex(
                mainAxisAlignment: MainAxisAlignment.start,
                direction: Axis.horizontal,
                children: [
                  Container(
                    margin: EdgeInsets.only(right:16),
                    child: Icon(Icons.folder),
                  ),
                  Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.sharedName),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${time.month < 10 ? '0${time.month}' : time.month}-${time.day < 10 ? '0${time.day}' : time.day} ${time.hour < 10 ? '0${time.hour}' : time.hour}:${time.minute < 10 ? '0${time.minute}' : time.minute}",
                            style: TextStyle(
                                fontSize: 12,
                                color:Colors.grey
                            ),
                          ),
                          Text(
                            "过期时间:${getFormatTime(DateTime.fromMillisecondsSinceEpoch(v.expireTime))}",
                            style: TextStyle(
                                fontSize: 12,
                                color:Colors.grey
                            ),
                          )
                        ],
                      )
                    ],
                  )),



                ],
              ));
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: shares.length,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: 60,
                child: shares[index],
              );
            }));
  }
}
