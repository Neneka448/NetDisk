import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../GlobalClass.dart' show RawResponse, SharedItemInfo, getFormatTime;
import '../GlobalVariables.dart' show baseURl, remoteUrl;
import 'dart:convert';
import 'package:get/get.dart';
import '../ModalWidget.dart';
import '../Store.dart';

class ButtonList {
  late dynamic tag;
  late OutlinedButton button;

  ButtonList({required this.button, required this.tag});
}

class SharePage extends StatefulWidget {
  const SharePage({Key? key}) : super(key: key);

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  var shares = <ButtonList>[];
  final Store store = Get.find();

  @override
  void initState() {
    super.initState();
    http.get(Uri.parse(remoteUrl + "/passageOther/share/user/${store.token.value}")).then((res) async {
      List<dynamic> t = jsonDecode(res.body);
      (() async {
        for (var i in t) {
          var ss = jsonDecode((await http.get(Uri.parse(remoteUrl + "/passageOther/share/real/$i"))).body);
          var time = DateTime.fromMillisecondsSinceEpoch(ss['shareDate']);
          var button = OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return buildBottomSheetWidget(ss, context, onDelete: () {
                        setState(() {
                          shares = shares.where((element) {
                            if (element.tag == ss) {
                              return false;
                            } else {
                              return true;
                            }
                          }).toList();
                        });
                        Navigator.pop(context);
                      });
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
                          Text("我的分享"),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${time.month < 10 ? '0${time.month}' : time.month}-${time.day < 10 ? '0${time.day}' : time.day} ${time.hour < 10 ? '0${time.hour}' : time.hour}:${time.minute < 10 ? '0${time.minute}' : time.minute}",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                "过期时间:${getFormatTime(DateTime.fromMillisecondsSinceEpoch(ss['expireDate']))}",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              )
                            ],
                          )
                        ],
                      )),
                ],
              ));
          setState(() {
            shares.add(ButtonList(button: button, tag: ss));
          });
        }
      })();
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
                child: shares[index].button,
              );
            }));
  }
}
