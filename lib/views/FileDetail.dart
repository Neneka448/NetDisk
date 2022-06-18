import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:netdisk/views/FileList.dart';
import '../DownloadIsolate.dart';
import '../GlobalClass.dart' show FileDescriptor, FileState, formatSize, getFormatTime;
import '../GlobalVariables.dart';
import '../Store.dart';
import "package:http/http.dart" as http;
class FileDetail extends StatefulWidget {
  late final File file;
  late final String fileLocation;

  FileDetail({Key? key, required Map<dynamic, dynamic> argv})
      : super(key: key) {
    file = argv["file"];
    fileLocation = argv['location'];
  }

  @override
  State<FileDetail> createState() => _FileDetailState();
}

class _FileDetailState extends State<FileDetail> {
  bool isFileStared = false;
  Store store=Get.find();
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
          actions: [
            // IconButton(
            //   onPressed: () {
            //     setState(() {
            //       isFileStared = !isFileStared;
            //     });
            //   },
            //   icon: isFileStared
            //       ? const Icon(Icons.star)
            //       : const Icon(Icons.star_border),
            //   color: isFileStared ? Colors.yellow : Colors.grey,
            //   iconSize: 35,
            // )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file_rounded,
                          size: 60,
                        ),
                        Flexible(
                          child: Text(
                            widget.file.fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(style: const TextStyle(fontSize: 16),  children: [
                            const TextSpan(
                                text: "文件大小: ",
                                style: TextStyle(color: Colors.black)),
                            TextSpan(
                                text: formatSize(
                                    double.parse(widget.file.fileSize)),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black))
                          ]),
                        ),
                        RichText(
                          text:  TextSpan(style: TextStyle(fontSize: 16),children: [
                            TextSpan(
                                text: "文件类型: ",
                                style: TextStyle(color: Colors.black)),
                            TextSpan(
                                text: widget.file.fileName.split('.').last,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black))
                          ]),
                        ),
                        RichText(
                          text: TextSpan(style: const TextStyle(fontSize: 16),children: [
                            const TextSpan(
                                text: "文件位置: ",
                                style: TextStyle(color: Colors.black)),
                            TextSpan(
                                text: widget.fileLocation,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black))
                          ]),
                        ),
                        RichText(
                          text: TextSpan(style: const TextStyle(fontSize: 16),children: [
                            const TextSpan(
                                text: "上次修改时间: ",
                                style: const TextStyle(color: Colors.black)),
                            TextSpan(
                                text: getFormatTime(
                                    widget.file.lastModifiedTime,
                                    needYear: true),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black))
                          ]),
                        ),
                        RichText(
                          text: TextSpan(style: const TextStyle(fontSize: 16),children: [
                            const TextSpan(
                                text: "创建时间: ",
                                style: TextStyle(color: Colors.black)),
                            TextSpan(
                                text: getFormatTime(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(widget.file.date)),
                                    needYear: true),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black))
                          ]),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Container(
                    color: Colors.blue,
                    child: Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    primary: const Color(0x2540872E),
                                    side: BorderSide.none,
                                    backgroundColor: Colors.blue),
                                onPressed: () async {
                                  final url = remoteUrl + '/' + widget.file.fileID;
                                  var t = DownloadIsolate(url);
                                  t.start(onInit_: (size) {
                                    store.downloadList[ widget.file.fileName] =
                                        FileDescriptor( widget.file.fileName, url, DateTime.now().millisecondsSinceEpoch,0);
                                    store.downloadList[ widget.file.fileName]!.size = size;
                                    store.downloadList[ widget.file.fileName]!.isolate=t;
                                    store.downloadList.refresh();
                                  }, onProcess_: (ok, tot) {
                                    if (store.downloadList[ widget.file.fileName]!.state != FileState.downloading) {
                                      store.downloadList[ widget.file.fileName]!.state = FileState.downloading;
                                    }
                                    store.downloadList[ widget.file.fileName]!.rec = ok;
                                    store.saveToDisk();
                                    store.downloadList.refresh();
                                  }, onDone_: (url) {
                                    store.downloadList[ widget.file.fileName]!.state = FileState.done;
                                    store.downloadList[ widget.file.fileName]!.url = url;
                                    store.saveToDisk();
                                    store.downloadList.refresh();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text("开始下载"),
                                    duration: Duration(milliseconds: 500),
                                  ));
                                },
                                child: const Text("下载",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)))),
                        Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide.none,
                                    backgroundColor: Colors.red),
                                onPressed: () async{
                                  var resCopy=await http.put(Uri.parse(remoteUrl+'/passageOther/recycle/${store.token.value}/'+widget.file.fileName),
                                      headers:{"x-oss-copy-source":'/img-passage/${Uri.encodeComponent(widget.file.fileID)}'} );
                                  if(resCopy.statusCode==200){
                                    var res=await http.delete(Uri.parse(remoteUrl+'/'+Uri.encodeComponent(widget.file.fileID)));
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text(
                                  "删除",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ))),
                      ],
                    ),
                  ))
            ],
          ),
        ));
  }
}
