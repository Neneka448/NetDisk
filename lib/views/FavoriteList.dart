import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:netdisk/views/FileList.dart';
import '../GlobalClass.dart';
import '../GlobalVariables.dart';
import '../ModalWidget.dart';
import 'SharePage.dart';

class FavoriteList extends StatefulWidget {
  const FavoriteList({Key? key}) : super(key: key);

  @override
  State<FavoriteList> createState() => _FavoriteListState();
}

class ButtonList {
  late File tag;
  late OutlinedButton button;

  ButtonList({required this.button, required this.tag});
}

class _FavoriteListState extends State<FavoriteList> {
  var shares = <ButtonList>[];

  @override
  void initState() {
    super.initState();
    http.get(Uri.parse(baseURl + "/favorite/list")).then((res) {
      dynamic t = jsonDecode(res.body);
      print(t['data']);
      RawResponse<List<File>> rawRes = RawResponse<List<File>>(
          status: t['status'],
          desc: t['desc'],
          data: List.from(t['data'].map((v) => File.fromJson(v))));
      setState(() {
        shares = rawRes.data.map((v) {
          var t = OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return buildShareQueryWidget(v, context, onDelete: () {
                        setState(() {
                          shares = shares.where((element) {
                            if (element.tag == v) {
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
                      Text(v.fileName),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getFormatTime(DateTime.fromMillisecondsSinceEpoch(int.parse(v.date))),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      )
                    ],
                  )),
                ],
              ));
          return ButtonList(button: t, tag: v);
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        toolbarTextStyle: const TextStyle(color: Colors.black),
        elevation: 0,
        leading: Container(
            alignment: Alignment.center,
            child: BackButton(
              color: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
            )),
      ),
      body: Container(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: shares.length,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  height: 60,
                  child: shares[index].button,
                );
              })),
    );
  }
}
