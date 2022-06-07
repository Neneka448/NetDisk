import 'package:flutter/material.dart';
import 'package:netdisk/views/FileList.dart';
import '../GlobalClass.dart' show formatSize, getFormatTime;

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
            IconButton(
              onPressed: () {
                setState(() {
                  isFileStared = !isFileStared;
                });
              },
              icon: isFileStared
                  ? const Icon(Icons.star)
                  : const Icon(Icons.star_border),
              color: isFileStared ? Colors.yellow : Colors.grey,
              iconSize: 35,
            )
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
                          text: const TextSpan(style: TextStyle(fontSize: 16),children: [
                            TextSpan(
                                text: "文件类型: ",
                                style: TextStyle(color: Colors.black)),
                            TextSpan(
                                text: "unknown",
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
                                onPressed: () {
                                  print(1);
                                },
                                child: const Text("下载",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)))),
                        Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    primary: const Color(0x2540872E),
                                    side: BorderSide.none,
                                    backgroundColor: Colors.blue),
                                onPressed: () {
                                  print(1);
                                },
                                child: const Text("分享",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)))),
                        Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide.none,
                                    backgroundColor: Colors.red),
                                onPressed: () {
                                  print(1);
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
