import 'dart:io';
import 'dart:isolate';
import 'package:http/http.dart' as http;

import 'GlobalVariables.dart';

class UploadIsolate {
  ReceivePort port = ReceivePort();
  late SendPort sender;
  late Isolate isolate;
  late String nowDir;
  Function? onPaused;
  bool isPaused=false;
  int startPos=0;
  int nowPart=1;
  File file;
  Function(int sentChunk, int tot,int nextPart,String eTag)? onProcess;
  Function? onFinish;
  Map<int,String> nowEtag;
  int chunkSize=102400;
  UploadIsolate(this.file,List<String> dir,{this.startPos=0,this.nowPart=1,required this.nowEtag}) {
    nowDir=dir.join('/');
    port.listen((message) {
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
            sender.send({"msg":"ok","chunkSize":chunkSize});
          }
          break;
        case "process":
          if(onProcess!=null){
            onProcess!(message['data']['ok'],message['data']['size'],message['data']['nextPart'],message['data']['eTag']);
          }
          break;
        case "uploadComplete":
          if(onFinish!=null){
            onFinish!();
          }
          break;
        case "paused":
          port.close();
          if(onPaused!=null){
            onPaused!();
          }
      }
    });
  }
  changeSpeed(int newChunkSize){
    chunkSize=newChunkSize;
  }
  start(String id, {Function(String uploadID)? onInit,Function(int sentChunk, int tot,int nextPart,String eTag)? onProcess,Function? onFinish,String? uploadID_}) async {
    this.onProcess=onProcess;
    this.onFinish=onFinish;
    String uploadID;
    var filename = file.path
        .split(RegExp("/|\\\\"))
        .last;
    if(uploadID_!=null){
      uploadID=uploadID_;
    }else{
      var res = await http.post(Uri.parse(remoteUrl+"/passageOther/disk/$nowDir/$filename?uploads"));
      uploadID = RegExp("<UploadId>(.*)<\/UploadId>").firstMatch(res.body)!.group(1)!;
    }
    if(onInit!=null){
      onInit(uploadID);
    }
    isolate = await Isolate.spawn(uploadFunc, {"port":port.sendPort,"file":file,"id":uploadID,"filename":filename,"userid":id,"dir":nowDir,"startPos":startPos,"nowPart":nowPart,"etag":nowEtag});
  }
  pause(Function? onPaused){
    this.onPaused=onPaused;
    isPaused=true;
  }
}

uploadFunc(message) async {
  SendPort sendPort=message['port'];
  File file=message['file'];
  String filename=message['filename'];
  String userid=message['userid'];
  String uploadID=message['id'];
  String dir=message['dir'];
  var isoRecPort = ReceivePort();
  sendPort.send({"msg": "connect", "data": isoRecPort.sendPort});
  var fio = await file.open();
  var size = (await file.stat()).size;
  int nowPart = message["nowPart"];
  int start = message["startPos"];
  int chunkSize = 1024 * 100;
  Map<int,String> check = message['etag'];
  isoRecPort.listen((message) async {
    String msg = message['msg'];
    switch (msg) {
      case "ok":
        if(message['chunkSize']!=null){
          chunkSize=message['chunkSize'];
        }
        chunkSize=size-start<chunkSize?size-start:chunkSize;
        await fio.setPosition(start);
        var buffer=await fio.read(chunkSize);
        if (start<size) {
          var res = await http.put(
              Uri.parse(remoteUrl+"/passageOther/disk/$dir/$filename?partNumber=$nowPart&uploadId=$uploadID"),
              body: buffer);
          check[nowPart]=res.headers['etag']!;
          nowPart++;
          start += chunkSize;
          sendPort.send({"msg":"process","data":{"ok":start,"size":size,"nextPart":nowPart,"eTag":res.headers['etag']}});
          sendPort.send({"msg":"shouldContinue"});

        } else {
          String checker = "";
          //TODO: 保存checker
          checker = check.entries.toList().map((e) =>
          '''
              <Part>
              <PartNumber>${e.key}</PartNumber>
              <ETag>${e.value}</ETag>
              </Part>
              ''').join('\n');
          checker="<CompleteMultipartUpload>\n"+checker+"\n</CompleteMultipartUpload>";
          print(remoteUrl+"/passageOther/disk/$dir/$filename?uploadId=$uploadID");
          var res = await http.post(
              Uri.parse(remoteUrl+"/passageOther/disk/$dir/$filename?uploadId=$uploadID"), body: checker);
          print(res.statusCode);
          Isolate.exit(sendPort,{"msg":"uploadComplete"});

        }

        break;
      case "pause":
        Isolate.exit(sendPort,{"msg":"paused"});
    }
  });
}