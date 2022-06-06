import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../GlobalVariables.dart' show baseURl;


class File {
  final String fileName;
  final String fileSize;
  final String date;
  final String fileType;
  final String fileID;
  const File(
      {required this.fileName,
      required this.fileSize,
      required this.date,
      required this.fileType,
      required this.fileID
      });

  factory File.fromJson(Map<String, dynamic> json) {
    return File(
        fileName: json['file_name'],
        fileSize: json['file_size'],
        date: json['date'],
        fileType: json['file_type'],
        fileID: json['file_id']
    );
  }
}

class FileListTree{
  File file;
  FileListTree? parent;
  Map<String,FileListTree>? children;
  FileListTree(File f):file=f;
  void buildChildren(List<File> f){
    children={};
    for (var item in f) {
      children![item.fileID]=FileListTree(item);
      children![item.fileID]?.parent=this;
    }
  }
  bool hasChild(){
    if(children!=null){
      return children!.isNotEmpty;
    }else{
      return false;
    }
  }
  void removeChild(String fileID){
    if(hasChild()){
      children!.remove(fileID);
    }
  }
  FileListTree getChild(String fileID){
    if(children!.containsKey(fileID)){
      return children![fileID]!;
    }else{
      return this;
    }
  }
}
class FileListTreeVisitor{
  FileListTree visitee;
  FileListTreeVisitor(this.visitee);
  FileListTreeVisitor moveTo(String fileID){
    return FileListTreeVisitor(visitee.getChild(fileID));
  }
  FileListTreeVisitor buildChildren(List<File> f){
    visitee.buildChildren(f);
    return FileListTreeVisitor(visitee);
  }
  FileListTreeVisitor returnToParent(){
    if(visitee.file.fileType!="RootFile"){
      return FileListTreeVisitor(visitee.parent!);
    }
    return this;
  }
  File getFile(){
    return visitee.file;
  }
  List<File> getChildren(){
    if(visitee.hasChild()){
      List<File> res=[];
      visitee.children!.forEach((key, value) {
        res.add(value.file);
      });
      return res;
    }else{
      return [];
    }
  }
  void removeFile(String fileID){
    visitee.removeChild(fileID);
  }
  bool hasChild(){
    return visitee.hasChild();
  }
}

class FileList extends StatefulWidget {
  final Function backToParentCallback;
  const FileList({Key? key,required this.backToParentCallback}) : super(key: key);

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  FileListTree fileTree=FileListTree(const File(fileName: "_ROOT",fileID: "-1",fileType: "RootFile",fileSize: "0",date: "-1"));
  late FileListTreeVisitor visitor=FileListTreeVisitor(fileTree);
  void getFileListWhenInit() async {
    final res = await http
        .get(Uri.parse(baseURl+"/disk/list"));
    List<dynamic> t = jsonDecode(res.body);
    var files=t.map((ele) => File.fromJson(ele)).toList();
    setState(() {
      visitor=visitor.buildChildren(files);
    });
  }

  @override
  void initState() {
    super.initState();
    getFileListWhenInit();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    super.widget.backToParentCallback((){
      setState(() {
        visitor=visitor.returnToParent();
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    var itemWidget=visitor.getChildren().map((e) {
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
            side:BorderSide.none,
          ),
          onPressed: () {
            if(e.fileType=="folder"){
              setState(() {
                visitor=visitor.moveTo(e.fileID);
                if(!visitor.hasChild()){
                  http.get(Uri.parse(baseURl+"/disk/list/details")).then((res){
                    List<dynamic> t=jsonDecode(res.body);
                    var files=t.map((ele) => File.fromJson(ele)).toList();
                    setState(() {
                      visitor=visitor.buildChildren(files);
                    });
                  });
                }
              });
            }else if(e.fileType=="file"){
              Navigator.pushNamed(context, "/file",arguments: e);
            }
          },
          child: Flex(
            crossAxisAlignment: CrossAxisAlignment.center,
            direction: Axis.horizontal,
            children: [
              Container(
                margin:const EdgeInsets.only(right: 10),
                child: Icon(e.fileType=="file"?Icons.insert_drive_file_sharp:Icons.folder),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Text(
                    e.fileName,
                    style: const TextStyle(
                    color: Colors.black,
                      fontSize: 16
                  )),
                  Row(
                    children: [
                      Text(e.date,style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12
                      ),),
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: Text(e.fileType == "file"
                            ? "${fileSize.toStringAsFixed(2)}$fileSizeExt"
                            : "",style: const TextStyle(
                            color: Colors.grey,
                          fontSize: 12
                        )),
                      )
                    ],
                  )
                ],
              ),


            ],
          ));
    }).toList();
    
    return Container(
      child:itemWidget.isEmpty?const Text("no content"):ListView.builder(
        shrinkWrap: true,
        itemCount: itemWidget.length,
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
              height: 60,
              child:itemWidget[index]
          );
        },
      )
    );
  }
}
