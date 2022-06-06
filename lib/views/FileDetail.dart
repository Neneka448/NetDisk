import 'package:flutter/material.dart';
import 'package:netdisk/views/FileList.dart';
import '../GlobalClass.dart' show formatSize;

class FileDetail extends StatefulWidget {
  final File file;

  const FileDetail({Key? key, required this.file}) : super(key: key);

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
          padding: EdgeInsets.only(top: 40),
          child: Column(
            children: [
              const Icon(
                Icons.file_copy,
                size: 60,
              ),
              const Divider(
                height: 20,
                color: Colors.transparent,
              ),
              Text(
                widget.file.fileName,
                style: const TextStyle(fontSize: 20),
              ),
              Text(formatSize(double.parse(widget.file.fileSize))),
              const Divider(
                height: 20,
                color: Colors.transparent,
              ),
              Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () {
                            print(1);
                          },
                          child: const Text("下载"))),
                  ElevatedButton(
                      onPressed: () {
                        print(1);
                      },
                      child: const Text("分享")),
                  ElevatedButton(
                      onPressed: () {
                        print(1);
                      },
                      child: const Text("删除")),
                ],
              ),
            ],
          ),
        ));
  }
}
