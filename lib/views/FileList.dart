import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../GlobalVariables.dart' show baseURl;
import '../GlobalClass.dart' show NavigatorKey, getFormatTime;

class File {
  final String fileName;
  final String fileSize;
  final String date;
  final String fileType;
  final String fileID;
  final DateTime lastModifiedTime;

  const File(
      {required this.fileName,
      required this.fileSize,
      required this.date,
      required this.fileType,
      required this.fileID,
      required this.lastModifiedTime});

  factory File.fromJson(Map<String, dynamic> json) {
    return File(
        fileName: json['file_name'],
        fileSize: json['file_size'],
        date: json['date'],
        fileType: json['file_type'],
        fileID: json['file_id'],
        lastModifiedTime: DateTime.fromMillisecondsSinceEpoch(int.parse(json['last_modified_time']))
    );
  }
}

class FileListTree {
  File file;
  FileListTree? parent;
  Map<String, FileListTree>? children;

  FileListTree(File f) : file = f;

  void buildChildren(List<File> f) {
    children = {};
    for (var item in f) {
      children![item.fileID] = FileListTree(item);
      children![item.fileID]?.parent = this;
    }
  }

  bool hasChild() {
    if (children != null) {
      return children!.isNotEmpty;
    } else {
      return false;
    }
  }

  void removeChild(String fileID) {
    if (hasChild()) {
      children!.remove(fileID);
    }
  }

  FileListTree getChild(String fileID) {
    if (children!.containsKey(fileID)) {
      return children![fileID]!;
    } else {
      return this;
    }
  }
}

class FileListTreeVisitor {
  FileListTree visitee;

  FileListTreeVisitor(this.visitee);

  FileListTreeVisitor moveTo(String fileID) {
    return FileListTreeVisitor(visitee.getChild(fileID));
  }

  bool isRootFile() {
    if (visitee.file.fileType == "RootFile") {
      return true;
    } else {
      return false;
    }
  }

  FileListTreeVisitor buildChildren(List<File> f) {
    visitee.buildChildren(f);
    return FileListTreeVisitor(visitee);
  }

  FileListTreeVisitor returnToParent() {
    if (visitee.file.fileType != "RootFile") {
      return FileListTreeVisitor(visitee.parent!);
    }
    return this;
  }
  String getFilePathToRoot(String fileID){
    var s=<String>[];
    var now=FileListTreeVisitor(visitee.getChild(fileID));
    while(!now.isRootFile()){
      s.add(now.visitee.file.fileName);
      now=now.returnToParent();
    }
    return s.reversed.join("<");
  }
  File getFile() {
    return visitee.file;
  }

  List<File> getChildren() {
    if (visitee.hasChild()) {
      List<File> res = [];
      visitee.children!.forEach((key, value) {
        res.add(value.file);
      });
      return res;
    } else {
      return [];
    }
  }

  void removeFile(String fileID) {
    visitee.removeChild(fileID);
  }

  bool hasChild() {
    return visitee.hasChild();
  }
}

class FileList extends StatefulWidget {
  final Function backToParentCallback;
  final Function onChangeNavi;
  const FileList({Key? key, required this.backToParentCallback,required this.onChangeNavi})
      : super(key: key);

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  bool chooseMode = false;
  var chosenMap = <String, bool>{};
  List<File>files=[];
  FileListTree fileTree = FileListTree(File(
      fileName: "_ROOT",
      fileID: "-1",
      fileType: "RootFile",
      fileSize: "0",
      date: "-1",
  lastModifiedTime: DateTime.fromMillisecondsSinceEpoch(0)));
  late FileListTreeVisitor visitor = FileListTreeVisitor(fileTree);

  void getFileListWhenInit() async {
    final res = await http.get(Uri.parse(baseURl + "/disk/list"));
    List<dynamic> t = jsonDecode(res.body);
    files = t.map((ele) => File.fromJson(ele)).toList();
    setState(() {
      visitor = visitor.buildChildren(files);
    });
  }
  @override
  void initState() {
    super.initState();
    getFileListWhenInit();
    widget.onChangeNavi((){
      if(chooseMode==true){
        Navigator.pop(context);
      }
    });
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    widget.onChangeNavi((){});
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    super.widget.backToParentCallback(() {
      if (chooseMode) {
        setState(() {
          chooseMode = false;
        });
      } else {
        setState(() {
          visitor = visitor.returnToParent();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var itemWidget = visitor.getChildren().map((e) {
      double fileSize = double.parse(e.fileSize);
      String fileSizeExt = "bit";
      if (fileSize < 8 * 1024) {
        fileSize /= 8;
        fileSizeExt = "B";
      } else if (fileSize < 8 * 1024 * 1024) {
        fileSizeExt = "KB";
        fileSize /= 8 * 1024;
      } else if (fileSize < 8 * 1024 * 1024 * 1024) {
        fileSizeExt = "MB";
        fileSize /= 8 * 1024 * 1024;
      } else {
        fileSizeExt = "GB";
        fileSize /= 8 * 1024 * 1024 * 1024;
      }
      return OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
          ),
          onLongPress: () {
            setState(() {
              chooseMode = true;
              chosenMap[e.fileID] = true;
            });
            showBottomSheet(
              enableDrag: false,
              backgroundColor: Colors.blue,
                context: context,
                builder: (BuildContext context) {
                  return SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                        style:
                            OutlinedButton.styleFrom(side: BorderSide.none),
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.file_download_outlined,
                              color: Colors.white,
                            ),
                            Text(
                              "下载",
                              style: TextStyle(color: Colors.white),
                            )
                          ],
                        )),
                    OutlinedButton(
                        style:
                            OutlinedButton.styleFrom(side: BorderSide.none),
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, color: Colors.white),
                            Text("分享",
                                style: TextStyle(color: Colors.white)),
                          ],
                        )),
                    OutlinedButton(
                        style:
                            OutlinedButton.styleFrom(side: BorderSide.none),
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            Text("删除",
                                style: TextStyle(color: Colors.white)),
                          ],
                        )),
                    OutlinedButton(
                        style:
                            OutlinedButton.styleFrom(side: BorderSide.none),
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_outlined,
                              color: Colors.white,
                            ),
                            Text("收藏",
                                style: TextStyle(color: Colors.white)),
                          ],
                        )),
                    OutlinedButton(
                        style:
                            OutlinedButton.styleFrom(side: BorderSide.none),
                        onPressed: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.more_horiz,
                              color: Colors.white,
                            ),
                            Text("更多",
                                style: TextStyle(color: Colors.white))
                          ],
                        ))
                  ],
                    ),
                  );
                });
          },
          onPressed: () {
            if (chooseMode) {
              if (chosenMap.containsKey(e.fileID)) {
                setState(() {
                  chosenMap.remove(e.fileID);
                });
              } else {
                setState(() {
                  chosenMap[e.fileID] = true;
                });
              }
            } else {
              if (e.fileType == "folder") {
                setState(() {
                  visitor = visitor.moveTo(e.fileID);
                  if (!visitor.hasChild()) {
                    http
                        .get(Uri.parse(baseURl + "/disk/list/details"))
                        .then((res) {
                      List<dynamic> t = jsonDecode(res.body);
                      var files = t.map((ele) => File.fromJson(ele)).toList();
                      setState(() {
                        visitor = visitor.buildChildren(files);
                      });
                    });
                  }
                });
              } else if (e.fileType == "file") {
                Navigator.pushNamed(context, "/file", arguments: {'file':e,'location':visitor.getFilePathToRoot(e.fileID)});
              }
            }
          },
          child: Flex(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: [
              Flex(
                direction: Axis.horizontal,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: Icon(e.fileType == "file"
                        ? Icons.insert_drive_file_sharp
                        : Icons.folder),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(e.fileName,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 16)),
                      Row(
                        children: [
                          Text(
                            getFormatTime(DateTime.fromMillisecondsSinceEpoch(int.parse(e.date)),needYear: true),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 10),
                            child: Text(
                                e.fileType == "file"
                                    ? "${fileSize.toStringAsFixed(2)}$fileSizeExt"
                                    : "",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          )
                        ],
                      )
                    ],
                  ),
                ],
              ),
              Container(
                child: chooseMode == true
                    ? chosenMap.containsKey(e.fileID)
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 18,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            color: Colors.grey,
                            size: 16,
                          )
                    : null,
              )
            ],
          ));
    }).toList();

    return WillPopScope(
        child: Container(
            margin: EdgeInsets.only(bottom: chooseMode ? 60 : 0),
            child: itemWidget.isEmpty
                ? const Text("no content")
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: itemWidget.length,
                    itemBuilder: (BuildContext context, int index) {
                      return SizedBox(height: 60, child: itemWidget[index]);
                    },
                  )),
        onWillPop: () {
          if (chooseMode) {
            setState(() {
              chooseMode = false;
              chosenMap = {};
            });
            Navigator.pop(context);
          } else {
            if (!visitor.isRootFile()) {
              setState(() {
                visitor = visitor.returnToParent();
              });
            } else {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                SystemNavigator.pop();
              }
            }
          }
          return Future.value(false);
        });
  }
}
