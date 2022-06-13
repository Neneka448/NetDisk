import 'dart:io';
import 'package:dio/dio.dart';

Future downloadWithChunks(
    url,
    savePath, {
      ProgressCallback? onReceiveProgress,
    }) async {
  const firstChunkSize = 1024;
  const maxChunk = 3;

  int total = 0;
  var dio = Dio();
  var progress = <int>[];

  createCallback(no) {
    return (int received, _) {
      progress[no] = received;
      if (onReceiveProgress != null && total != 0) {
        onReceiveProgress(progress.reduce((a, b) => a + b), total);
      }
    };
  }

  Future<Response> downloadChunk(url, start, end, no) async {
    progress.add(0);
    --end;
    return dio.download(
      url,
      savePath + "temp$no",
      onReceiveProgress: createCallback(no),
      options: Options(
        headers: {"range": "bytes=$start-$end"},
      ),
    );
  }

  Future mergeTempFiles(chunk) async {
    File f = File(savePath + "temp0");
    IOSink ioSink= f.openWrite(mode: FileMode.writeOnlyAppend);
    for (int i = 1; i < chunk; ++i) {
      File _f = File(savePath + "temp$i");
      await ioSink.addStream(_f.openRead());
      await _f.delete();
    }
    await ioSink.close();
    await f.rename(savePath);
  }

  Response response = await downloadChunk(url, 0, firstChunkSize, 0);
  if (response.statusCode == 206) {
    total = int.parse(
        response.headers.value(HttpHeaders.contentRangeHeader)!.split("/").last);
    int reserved = total -
        int.parse(response.headers.value(HttpHeaders.contentLengthHeader)!);
    int chunk = (reserved / firstChunkSize).ceil();
    if (chunk > 0) {
      int chunkSize = chunk==1?reserved:firstChunkSize;
      var futures = <Future>[];
      for (int i = 0; i < chunk; ++i) {
        int start = firstChunkSize + i * chunkSize;
        futures.add(downloadChunk(url, start, start + chunkSize, i + 1));
      }
      await Future.wait(futures);
    }
    await mergeTempFiles(chunk);
  }
}
