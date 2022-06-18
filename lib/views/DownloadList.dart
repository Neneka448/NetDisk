import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:open_file/open_file.dart';
import '../DownloadIsolate.dart';
import '../GlobalClass.dart';
import '../Store.dart';
import '../UploadIsolate.dart';

class DownloadList extends StatefulWidget {
  const DownloadList({Key? key}) : super(key: key);

  @override
  State<DownloadList> createState() => _DownloadListState();
}

class _DownloadListState extends State<DownloadList> {
  var files = <FileSystemEntity>[];
  var pageMode = 0; // 0 download 1 upload
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    (() async {
      var dir = await path_provider.getTemporaryDirectory();
      dir = await dir.createTemp("download");
      files = dir.listSync(recursive: false);
    })();
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
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  color: Color.fromARGB(255, 187, 187, 187),
                  child: Row(
                    children: [
                      Expanded(
                          child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                side: BorderSide.none,
                                backgroundColor: pageMode == 0 ? Colors.white : Color.fromARGB(255, 187, 187, 187)),
                            onPressed: () {
                              setState(() {
                                pageMode = 0;
                              });
                            },
                            child: Text(
                              "下载列表",
                              style: TextStyle(color: Colors.black),
                            )),
                      )),
                      Expanded(
                          child: ClipRRect(
                        child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                side: BorderSide.none,
                                backgroundColor: pageMode == 1 ? Colors.white : Color.fromARGB(255, 187, 187, 187)),
                            onPressed: () {
                              setState(() {
                                pageMode = 1;
                              });
                            },
                            child: Text(
                              "上传列表",
                              style: TextStyle(color: Colors.black),
                            )),
                      ))
                    ],
                  ),
                ),
              )),
          pageMode==0?Text("下载中"):Text("上传中"),
          pageMode==0?DownloadBox():UploadBox()
        ]),
      ),
    );
  }
}

class DownloadBox extends StatefulWidget {
  const DownloadBox({Key? key}) : super(key: key);

  @override
  State<DownloadBox> createState() => _DownloadBoxState();
}

class _DownloadBoxState extends State<DownloadBox> {
  @override
  Widget build(BuildContext context) {
    final Store store = Get.find();
    final mediaSize=MediaQuery.of(context).size;
    return Container(
      child: Obx(() {
        return store.downloadList.isNotEmpty
            ? ListView.builder(
          shrinkWrap: true,
          itemCount: store.downloadList.length,
          itemBuilder: (BuildContext context, int index) {
            var p = store.downloadList.entries.toList();
            return SizedBox(
                height: 60,
                width: mediaSize.width,
                child: Container(
                  width: mediaSize.width,
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file,size: 40,),
                      Divider(indent: 8,),
                      Expanded(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p[index].value.name),
                                Text("${(p[index].value.rec*100/p[index].value.size).toStringAsFixed(2)}% ${p[index].value.rec==p[index].value.size?"":"("+getFormatDownloadSpeed(p[index].value)+")"}")
                              ],
                            ),
                          ),
                          Divider(
                            color: Colors.transparent,
                            height: 10,
                          ),
                          Container(
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: p[index].value.rec/p[index].value.size,
                              backgroundColor: Color.fromARGB(255, 250, 250, 250),
                              color: Colors.blue,
                            ),
                          ),

                        ],
                      )),
                      Divider(indent: 10,),
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        child: Container(
                          color: Colors.white,
                          child: IconButton(
                            onPressed: ()async{
                              store.saveToDisk();
                              switch(p[index].value.state){
                                case FileState.init:
                                  // TODO: Handle this case.
                                  break;
                                case FileState.downloading:
                                  p[index].value.isolate!.pause((){
                                    store.downloadList[p[index].value.name]!.state=FileState.paused;
                                    store.downloadList.refresh();
                                  });
                                  break;
                                case FileState.paused:
                                  var t = DownloadIsolate(p[index].value.downloadUrl, startPos:store.downloadList[p[index].value.name]!.rec,size:store.downloadList[p[index].value.name]!.size);
                                  p[index].value.isolate=t;
                                  t.start(onInit_: (size) {
                                    store.downloadList[p[index].value.name]!.startTime=DateTime.now().millisecondsSinceEpoch;
                                    store.downloadList.refresh();
                                  }, onProcess_: (ok, tot) {
                                    if (store.downloadList[p[index].value.name]!.state != FileState.downloading) {
                                      store.downloadList[p[index].value.name]!.state = FileState.downloading;
                                    }
                                    store.downloadList[p[index].value.name]!.rec = ok;
                                    store.saveToDisk();
                                    store.downloadList.refresh();
                                  }, onDone_: (url) {
                                    store.downloadList[p[index].value.name]!.state = FileState.done;
                                    store.downloadList[p[index].value.name]!.url = url;
                                    store.saveToDisk();
                                    store.downloadList.refresh();
                                  });
                                  store.downloadList.refresh();
                                  break;
                                case FileState.done:
                                  var t=await OpenFile.open(p[index].value.url);
                                  break;
                              }
                            },
                            icon: p[index].value.state==FileState.downloading
                                    ? Icon(Icons.pause)
                                    : p[index].value.state==FileState.paused
                                      ? Icon(Icons.download)
                                      : p[index].value.state==FileState.done
                                        ? Icon(Icons.folder_open_outlined)
                                        : Icon(Icons.downloading),
                          ),
                        ),
                      )
                    ],
                  ),
                ));
          },
        )
            : Text("No File");
      }),
    );
  }
}

class UploadBox extends StatefulWidget {
  const UploadBox({Key? key}) : super(key: key);

  @override
  State<UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<UploadBox> {
  @override
  Widget build(BuildContext context) {
    final Store store = Get.find();
    final mediaSize=MediaQuery.of(context).size;
    return Container(
      child: Obx(() {
        return store.uploadList.isNotEmpty
            ? ListView.builder(
          shrinkWrap: true,
          itemCount: store.uploadList.length,
          itemBuilder: (BuildContext context, int index) {
            var p = store.uploadList.entries.toList();
            return SizedBox(
                height: 60,
                width: mediaSize.width,
                child: Container(
                  width: mediaSize.width,
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file,size: 40,),
                      Divider(indent: 8,),
                      Expanded(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p[index].value.name),
                                Text("${(p[index].value.rec*100/p[index].value.size).toStringAsFixed(2)}% ${p[index].value.rec==p[index].value.size?"":"("+getFormatDownloadSpeed(p[index].value)+")"}")
                              ],
                            ),
                          ),
                          Divider(
                            color: Colors.transparent,
                            height: 10,
                          ),
                          Container(
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: p[index].value.rec/p[index].value.size,
                              backgroundColor: Color.fromARGB(255, 250, 250, 250),
                              color: Colors.blue,
                            ),
                          ),

                        ],
                      )),
                      Divider(indent: 10,),
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        child: Container(
                          color: Colors.white,
                          child: IconButton(
                            onPressed: ()async{
                              store.saveToDisk();
                              if(p[index].value.state==FileState.downloading){
                                p[index].value.uploadIsolate!.pause((){
                                  print(123456);
                                  store.uploadList[p[index].value.name]!.state=FileState.paused;
                                  store.uploadList.refresh();
                                });
                              }else if(p[index].value.state==FileState.paused){
                                File newFile=File(p[index].value.downloadUrl);
                                final filename=p[index].value.name;
                                print(filename);
                                var t = UploadIsolate(newFile,p[index].value.uploadSavePath ,
                                    nowPart:store.uploadList[filename]!.nowPart,
                                    startPos:store.uploadList[p[index].value.name]!.rec,
                                    nowEtag:store.uploadList[filename]!.eTag );
                                p[index].value.uploadIsolate=t;
                                store.uploadList[filename]!.startTime=DateTime.now().millisecondsSinceEpoch;
                                t.start(store.token.value,uploadID_: store.uploadList[filename]!.uploadID, onProcess: (ok, size,nextPart,etag) {
                                  store.uploadList[filename]!.size = size;
                                  store.uploadList[filename]!.rec = ok;
                                  store.uploadList[filename]!.nowPart=nextPart;
                                  store.uploadList[filename]!.eTag[nextPart-1]=etag;
                                  store.uploadList[filename]!.state=FileState.downloading;
                                  store.saveToDisk();
                                  store.uploadList.refresh();
                                }, onFinish: () {
                                  store.uploadList[filename]!.state = FileState.done;
                                  store.saveToDisk();
                                  store.uploadList.refresh();
                                });

                                store.uploadList.refresh();
                              }
                            },
                            icon: p[index].value.state==FileState.downloading
                                ? Icon(Icons.pause)
                                : p[index].value.state==FileState.paused
                                ? Icon(Icons.download)
                                : p[index].value.state==FileState.done
                                ? Icon(Icons.check,color: Colors.green,)
                                : Icon(Icons.downloading),
                          ),
                        ),
                      )
                    ],
                  ),
                ));
          },
        )
            : Text("No File");
      }),
    );
  }
}
