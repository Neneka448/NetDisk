import 'dart:io';
import 'dart:isolate';
import 'package:http/http.dart' as http;

class TransferUpload {
  ReceivePort port = ReceivePort();
  late SendPort sender;
  late Isolate isolate;
  File file;

  TransferUpload(this.file) {
    port.listen((message) {
      String msg = message['msg'];
      switch (msg) {
        case "connect":
          sender = message['data'];
          sender.send({"msg": "ok", "data": file});
          break;
        case "shouldContinue":
          sender.send({"msg":"ok"});
          break;
      }
    });
  }

  start({Function(int sentChunk, int tot)? onProcess}) async {
    String uploadID;
    var filename = file.path
        .split('/|\\')
        .last;
    var res = await http.post(Uri.parse("https://oss.rosmontis.top/passageOther/$filename?uploads"));
    uploadID = RegExp("<UploadId>(.*)<\/UploadId>").firstMatch(res.body)!.group(1)!;
    isolate = await Isolate.spawn(uploadFunc, {"port":port.sendPort,"file":file,"id":uploadID,"filename":filename,"onProcess":onProcess});
  }

}

uploadFunc(message) async {
  SendPort sendPort=message['port'];
  File file=message['file'];
  String filename=message['filename'];
  Function(int sentChunk, int tot)? onProcess=message['onProcess'];
  String uploadID=message['id'];
  var isoRecPort = ReceivePort();
  sendPort.send({"msg": "connect", "data": isoRecPort.sendPort});
  var fio = await file.open();
  var size = (await file.stat()).size;
  print(size);
  int nowPart = 1;
  int start = 0;
  int chunkSize = 1024 * 100;
  var check = {};
  isoRecPort.listen((message) async {
    String msg = message['msg'];
    switch (msg) {
      case "ok":
        chunkSize=size-start<chunkSize?size-start:chunkSize;
        await fio.setPosition(start);
        var buffer=await fio.read(chunkSize);
        print(start);
        if (start<size) {
          var res = await http.put(
              Uri.parse("https://oss.rosmontis.top/passageOther/$filename?partNumber=$nowPart&uploadId=$uploadID"),
              body: buffer);
          check[nowPart] = res.headers['etag'];
          if (onProcess != null) {
            onProcess(nowPart, size);
          }
          nowPart++;
          print(111);
          print("byteread$start");
          start += chunkSize;
          print("code${res.statusCode}");
          sendPort.send({"msg":"shouldContinue"});
        } else {
          String checker = "";
          checker = check.entries.toList().map((e) =>
          '''
              <Part>
              <PartNumber>${e.key}</PartNumber>
              <ETag>${e.value}</ETag>
              </Part>
              ''').join('\n');
          checker="<CompleteMultipartUpload>\n"+checker+"\n</CompleteMultipartUpload>";
          print(checker);
          var res = await http.post(
              Uri.parse("https://oss.rosmontis.top/passageOther/$filename?uploadId=$uploadID"), body: checker);
          print("complate${res.statusCode}");
        }
        break;
      case "":
        break;
    }
  });
}