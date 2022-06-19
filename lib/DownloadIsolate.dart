import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path_provider;

Map<String,int> fileMap={};

class DownloadIsolate {
  ReceivePort port = ReceivePort();
  late SendPort sender;
  late Isolate isolate;
  late File file;
  late Directory downloadDirectory;
  String url;
  late String fileName;
  late Function(int recChunk, int tot)? onProcess;
  late Function(int size)? onInit;
  late Function(String url) onDone;
  late Function? onPause;
  int startPos=0;
  int size=-1;
  bool isPaused=false;
  int chunkSize=102400;
  DownloadIsolate(this.url,{this.startPos=0,this.size=-1}) {
    fileName = url.split(RegExp("/|\\\\")).last;
    port.listen((message) async {
      String msg = message['msg'];
      switch (msg) {
        case "connect":
          sender = message['data'];
          sender.send({"msg": "ok", "data": file});
          break;
        case "shouldContinue":
          if(isPaused){
            sender.send({"msg":"pause"});
          }else{
            sender.send({"msg": "ok","chunkSize":chunkSize});
          }
          break;
        case "downloadFinished":
          var s=WidgetsFlutterBinding.ensureInitialized();
          if(Platform.isAndroid){
            var docDir=(await path_provider.getExternalStorageDirectory())!;
            await file.copy(docDir.path+'/$fileName');
            await file.delete();
            onDone(docDir.path+'/$fileName');
          }else{
            onDone(file.path);
          }
          port.close();
          break;
        case "init":
          if(onInit!=null){
            onInit!(message["data"]);
          }
          break;
        case "process":
          if(onProcess!=null){
            onProcess!(message["data"]["rec"],message["data"]["size"]);
          }
          break;
        case "paused":
          port.close();
          if(onPause!=null){
            onPause!();
          }
          break;
      }
    });
  }
  changeSpeed(int newChunkSize){
    chunkSize=newChunkSize;
  }
  start({Function(int recChunk, int tot)? onProcess_,Function(int size)? onInit_,Function(String url)? onDone_}) async {
    if(onProcess_!=null){
      onProcess=onProcess_;
    }
    if(onInit_!=null){
      onInit=onInit_;
    }
    if(onDone_!=null){
      onDone=onDone_;
    }
    if(Platform.isAndroid){
      final cacheDirectory=await path_provider.getTemporaryDirectory();
      downloadDirectory=await cacheDirectory.createTemp("downloads");
    }else if(Platform.isWindows){
      downloadDirectory=(await path_provider.getDownloadsDirectory())!;
    }
    if(Platform.isWindows){
      file=File(downloadDirectory.path+'\\$fileName');
    }else{
      file=File(downloadDirectory.path+'/$fileName');
    }
    isolate = await Isolate.spawn(downloadFunc,
        {"port": port.sendPort, "url": url, "file": file,"directory":downloadDirectory, "filename": fileName,"startPos":startPos,"startSize":size});
  }
  pause(Function? onPaused){
    onPause=onPaused;
    isPaused=true;
  }
}

downloadFunc(message)async {
  SendPort sender=message['port'];
  ReceivePort port=ReceivePort();
  String url=message['url'];
  File file=message['file'];
  Directory dir=message['directory'];
  String filename=message['filename'];
  int startPos=message['startPos'];
  sender.send({"msg":"connect","data":port.sendPort});
  var fio=await file.open(mode: FileMode.append);
  saveChunk(List<int> content)async{
    await fio.writeFrom(content);
  }
  int size=message['startSize'];
  int start=startPos;
  int chunkSize=100*1024;
  port.listen((message) async {
    String msg=message["msg"];
    switch(msg){
      case "ok":
        if(message["chunkSize"]!=null&&message["chunkSize"]!=0){
          chunkSize=message["chunkSize"];
        }
        await fio.setPosition(start);
        if(start==0){
          int end=chunkSize;
          var res=await http.get(Uri.parse(url),headers: {
            "Range":"bytes=$start-$end"
          });
          if(res.headers['content-range']==null){
            await saveChunk(res.bodyBytes);
            sender.send({"msg":"init","data":size});
            sender.send({"msg":"process","data":{"rec":size,"size":size}});
            port.close();
            fio.flushSync();
            fio.closeSync();
            Isolate.exit(sender,{"msg":"downloadFinished"});
          }
          size=int.parse(res.headers['content-range']!.split('/').last);
          var bytesRead=int.parse(res.headers['content-length']!);
          print(res.statusCode);
          await saveChunk(res.bodyBytes);
          start=start+bytesRead;
          fileMap[url]=start;
          sender.send({"msg":"init","data":size});
        }else{
          int end=start+chunkSize>=size?size-1:start+chunkSize-1;
          if(start>=size){
            print("ok");
            port.close();
            fio.flushSync();
            fio.closeSync();
            Isolate.exit(sender,{"msg":"downloadFinished"});
          }
          var res=await http.get(Uri.parse(url),headers: {
            "Range":"bytes=$start-$end"
          });
          print(res.statusCode);
          start=end+1;
          await saveChunk(res.bodyBytes);
          fileMap[url]=start;
          sender.send({"msg":"process","data":{"rec":start,"size":size}});
        }
        print(start);

        sender.send({"msg":"shouldContinue"});
        break;
      case "pause":
        port.close();
        Isolate.exit(sender,{"msg":"paused"});
    }
  });

}