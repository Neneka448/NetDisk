import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:netdisk/Download.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml2json/xml2json.dart';
import '../DownloadIsolate.dart';
import '../GlobalVariables.dart' show baseURl, remoteUrl;
import '../GlobalClass.dart'
    show FileDescriptor, FileState, NavigatorKey, SharedItemInfo, User, dem2Hex, formatSize, getFileFromXML, getFormatTime;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../Store.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'dart:math';

class File {
  final String fileName;
  final String fileSize;
  final String date;
  final String fileType;
  final String fileID;
  final DateTime lastModifiedTime;
  var deleteFlag = false;

  File(
      {required this.fileName,
      required this.fileSize,
      required this.date,
      required this.fileType,
      required this.fileID,
      required this.lastModifiedTime});

  delete() {
    deleteFlag = true;
  }

  factory File.fromJson(Map<String, dynamic> json) {
    return File(
        fileName: json['file_name'],
        fileSize: json['file_size'],
        date: json['date'],
        fileType: json['file_type'],
        fileID: json['file_id'],
        lastModifiedTime: DateTime.fromMillisecondsSinceEpoch(int.parse(json['last_modified_time'])));
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
      if (item.deleteFlag == true) {
        continue;
      }
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

  String getFilePathToRoot(String fileID, String token) {
    // var s = <String>[];
    // var now = FileListTreeVisitor(visitee.getChild(fileID));
    // while (!now.isRootFile()) {
    //   s.add(now.visitee.file.fileName);
    //   now = now.returnToParent();
    // }
    // return s.reversed.join("<");
    return fileID.replaceAll(RegExp('.*/$token/'), "/");
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
  final File? initFile;
  final String? from;
  const FileList({Key? key, required this.backToParentCallback, required this.onChangeNavi, this.initFile,this.from})
      : super(key: key);

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  bool chooseMode = false;
  final Store store = Get.find();
  var chosenMap = <String, bool>{};
  var shareFileValidDays = 30;
  var shareFilePsw = '';
  List<File> files = [];

  FileListTree fileTree = FileListTree(File(
      fileName: "_ROOT",
      fileID: "-1",
      fileType: "RootFile",
      fileSize: "0",
      date: "-1",
      lastModifiedTime: DateTime.fromMillisecondsSinceEpoch(0)));
  late FileListTreeVisitor visitor = FileListTreeVisitor(fileTree);

  void getFileListWhenInit() async {
    store.nowDir.value = [store.token.value];
    if (widget.initFile != null) {
      final res = await http.get(Uri.parse(remoteUrl + "/?prefix=${widget.initFile!.fileID}&delimiter=/"));
      if (res.statusCode == 200) {
        var transformer = Xml2Json();
        transformer.parse(res.body);
        var json = jsonDecode(transformer.toParker());
        if (json['ListBucketResult']['CommonPrefixes'] != null) {
          if (json['ListBucketResult']['CommonPrefixes'] is! List) {
            var ele = json['ListBucketResult']['CommonPrefixes'];
            final filename = ele['Prefix'].replaceAll(RegExp(r"/$"), "").split('/');
            files.add(
              File(
                  fileName: filename.last,
                  fileID: ele['Prefix'],
                  fileSize: "0",
                  date: "0",
                  fileType: 'folder',
                  lastModifiedTime: DateTime.now()),
            );
          } else {
            json['ListBucketResult']['CommonPrefixes'].forEach((ele) {
              final filename = ele['Prefix'].replaceAll(RegExp(r"/$"), "").split('/');
              files.add(
                File(
                    fileName: filename.last,
                    fileID: ele['Prefix'],
                    fileSize: "0",
                    date: "0",
                    fileType: 'folder',
                    lastModifiedTime: DateTime.now()),
              );
            });
          }
        }
        if (json['ListBucketResult']['Contents'] != null) {
          if (json['ListBucketResult']['Contents'] is! List) {
            var ele = json['ListBucketResult']['Contents'];
            final filename = ele['Key'].replaceAll(RegExp(r"/$"), "").split('/');
            print(filename);
            files.add(File(
              fileName: filename.last,
              fileID: ele['Key'],
              fileSize: ele['Size'],
              date: DateTime.parse(ele['LastModified']).millisecondsSinceEpoch.toString(),
              fileType: 'file',
              lastModifiedTime: DateTime.parse(ele['LastModified']),
            ));
          } else {
            json['ListBucketResult']['Contents'].forEach((ele) {
              if (ele['Key'].endsWith('/')) {
                return;
              }
              final filename = ele['Key'].replaceAll(RegExp(r"/$"), "").split('/');
              print(filename);
              files.add(File(
                fileName: filename.last,
                fileID: ele['Key'],
                fileSize: ele['Size'],
                date: DateTime.parse(ele['LastModified']).millisecondsSinceEpoch.toString(),
                fileType: 'file',
                lastModifiedTime: DateTime.parse(ele['LastModified']),
              ));
            });
          }
        }
        setState(() {
          visitor = visitor.buildChildren(files);
        });
      }
      // files = t.map((ele) => File.fromJson(ele)).toList();
      // setState(() {
      //   visitor = visitor.buildChildren(files);
      // });
    } else {
      final res = await http.get(Uri.parse(remoteUrl + "/?prefix=passageOther/disk/${store.token.value}/&delimiter=/"));
      if (res.statusCode == 200) {
        var transformer = Xml2Json();
        transformer.parse(utf8.decode(res.bodyBytes));
        var json = jsonDecode(transformer.toParker());
        if (json['ListBucketResult']['CommonPrefixes'] != null) {
          if (json['ListBucketResult']['CommonPrefixes'] is! List) {
            var ele = json['ListBucketResult']['CommonPrefixes'];
            final filename = ele['Prefix'].replaceAll(RegExp(r"/$"), "").split('/');
            print(filename);
            files.add(
              File(
                  fileName: filename.last,
                  fileID: ele['Prefix'],
                  fileSize: "0",
                  date: "0",
                  fileType: 'folder',
                  lastModifiedTime: DateTime.now()),
            );
          } else {
            json['ListBucketResult']['CommonPrefixes'].forEach((ele) {
              final filename = ele['Prefix'].replaceAll(RegExp(r"/$"), "").split('/');
              print(filename);
              files.add(
                File(
                    fileName: filename.last,
                    fileID: ele['Prefix'],
                    fileSize: "0",
                    date: "0",
                    fileType: 'folder',
                    lastModifiedTime: DateTime.now()),
              );
            });
          }
        }
        if (json['ListBucketResult']['Contents'] != null) {
          if (json['ListBucketResult']['Contents'] is! List) {
            var ele = json['ListBucketResult']['Contents'];
            final filename = ele['Key'].replaceAll(RegExp(r"/$"), "").split('/');
            print(filename);
            files.add(File(
              fileName: filename.last,
              fileID: ele['Key'],
              fileSize: ele['Size'],
              date: DateTime.parse(ele['LastModified']).millisecondsSinceEpoch.toString(),
              fileType: 'file',
              lastModifiedTime: DateTime.parse(ele['LastModified']),
            ));
          } else {
            json['ListBucketResult']['Contents'].forEach((ele) {
              if (ele['Key'].endsWith('/')) {
                return;
              }
              final filename = ele['Key'].replaceAll(RegExp(r"/$"), "").split('/');
              print(ele['Key']);
              files.add(File(
                fileName: filename.last,
                fileID: ele['Key'],
                fileSize: ele['Size'],
                date: DateTime.parse(ele['LastModified']).millisecondsSinceEpoch.toString(),
                fileType: 'file',
                lastModifiedTime: DateTime.parse(ele['LastModified']),
              ));
            });
          }
        }
        setState(() {
          visitor = visitor.buildChildren(files);
        });
      }
      final shares=await http.get(Uri.parse(remoteUrl + "/passageOther/share/user/${store.token.value}"));
      store.shareList.value=List<String>.from(jsonDecode(shares.body));
      store.shareList.refresh();
    }
  }

  @override
  void initState() {
    super.initState();
    if (store.loginState.value == false) {
      SharedPreferences.getInstance().then((preference) {
        var token = preference.getString('token');
        if (token != null) {
          http.get(Uri.parse(remoteUrl + "/passageOther/user/$token")).then((response) {
            if (response.statusCode == 200) {
              store.token.value = token;
              store.changeLoginState(true);
              http
                  .get(Uri.parse(
                      "https://img-passage.oss-cn-hangzhou.aliyuncs.com/passageOther/user/${store.token.value}"))
                  .then((res) {
                dynamic rawData = jsonDecode(res.body);
                store.setUser(User.fromJson(rawData));
                store.user.refresh();
              });
              getFileListWhenInit();
            } else {
              preference.remove('token');
            }
          });
        }
      });
    } else {
      getFileListWhenInit();
    }
    widget.onChangeNavi(() {
      if (chooseMode == true) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    widget.onChangeNavi(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    super.widget.backToParentCallback(() {
      if (chooseMode) {
        setState(() {
          store.chooseMode.value = false;
          chooseMode = false;

        });
        Navigator.pop(context);
      } else {
        if(widget.from=='share'){
          if(visitor.isRootFile()){
            Navigator.pop(context);
          }else{
            setState(() {
              visitor = visitor.returnToParent();
            });
          }
        }else{
          if (store.nowDir.length > 1) {
            store.nowDir.remove(store.nowDir.last);
            store.nowDir.refresh();
          }
          setState(() {
            visitor = visitor.returnToParent();
          });
        }


      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var itemWidget = visitor.getChildren().map((e) {
      double fileSize = double.parse(e.fileSize);
      return OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
          ),
          onLongPress: () {
            setState(() {
              store.chooseMode.value = true;
              chooseMode = true;
              chosenMap[e.fileID] = true;
            });
            //TODO: BottomSheet
            showBottomSheet(
                enableDrag: false,
                backgroundColor: Colors.blue,
                context: context,
                builder: (BuildContext context) {
                  return SizedBox(
                    height: 70,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide.none, primary: Color(0x2B196322)),
                                onPressed: () async {
                                  final url = remoteUrl + '/' + e.fileID;
                                  var t = DownloadIsolate(url);
                                  t.start(onInit_: (size) {
                                    store.downloadList[e.fileName] =
                                        FileDescriptor(e.fileName, url, DateTime.now().millisecondsSinceEpoch,0);
                                    store.downloadList[e.fileName]!.size = size;
                                    store.downloadList[e.fileName]!.isolate=t;
                                    store.downloadList.refresh();
                                  }, onProcess_: (ok, tot) {
                                    if (store.downloadList[e.fileName]!.state != FileState.downloading) {
                                      store.downloadList[e.fileName]!.state = FileState.downloading;
                                    }
                                    store.downloadList[e.fileName]!.rec = ok;
                                    store.saveToDisk();
                                    store.downloadList.refresh();
                                  }, onDone_: (url) {
                                    store.downloadList[e.fileName]!.state = FileState.done;
                                    store.downloadList[e.fileName]!.url = url;
                                    store.saveToDisk();
                                    store.downloadList.refresh();
                                  });
                                },
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
                                ))),
                        (widget.from!=null&&widget.from=="share")?Container():Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide.none, primary: Color(0x2B196322)),
                                onPressed: () {
                                  //TODO: shareDialog
                                  showDialog(
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(builder: (context, setState) {
                                        return Dialog(
                                          child: Container(
                                            width: 200,
                                            height: 230,
                                            padding: EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 16),
                                            decoration: BoxDecoration(
                                                color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  child: Text(
                                                    "分享",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                Divider(
                                                  height: 16,
                                                ),
                                                Row(
                                                  children: [
                                                    Column(
                                                      children: [
                                                        Container(
                                                          width: 50,
                                                          height: 50,
                                                          decoration: BoxDecoration(
                                                              color: Color.fromARGB(255, 240, 240, 240),
                                                              shape: BoxShape.circle),
                                                          child: IconButton(
                                                            icon: Icon(Icons.link),
                                                            onPressed: () async {
                                                              final chosenIDs = chosenMap.keys.toList();
                                                              var fileSet = <String>[];
                                                              var shareFiles=<String>[];
                                                              for (var element in chosenIDs) {
                                                                var child = visitor.visitee.getChild(element);
                                                                if (child.file.fileType == 'file') {
                                                                  fileSet.add(element);
                                                                  shareFiles.add(child.file.fileName);
                                                                } else if (child.file.fileType == 'folder') {
                                                                  var fileRes = await http.get(Uri.parse(
                                                                      remoteUrl + '/?prefix=${child.file.fileID}'));
                                                                  var files = getFileFromXML(fileRes.body);
                                                                  for (var i in files) {
                                                                    if (i.fileID.endsWith('/') == false) {
                                                                      fileSet.add(i.fileID);
                                                                      shareFiles.add(i.fileName);
                                                                    }
                                                                  }
                                                                }
                                                              }
                                                              String shareUuid = md5
                                                                  .convert(utf8.encode(fileSet.join(",") +
                                                                      DateTime.now().microsecondsSinceEpoch.toString()))
                                                                  .toString();
                                                              var res = <String>[];
                                                              String prefix = store.nowDir.join("/");
                                                              for (var i in fileSet) {
                                                                final relAdd = RegExp('(?<=$prefix/)(.*)\$')
                                                                    .firstMatch(i)!
                                                                    .group(1);
                                                                var symlinkRes = await http.put(
                                                                    Uri.parse(remoteUrl +
                                                                        '/passageOther/share/files/$shareUuid/$relAdd?symlink'),
                                                                    headers: {"x-oss-symlink-target": i});
                                                                if (symlinkRes.statusCode == 200) {
                                                                  res.add(
                                                                      'passageOther/share/${store.token.value}/$shareUuid/$relAdd');
                                                                }
                                                              }
                                                              final algo = crypto.AesCtr.with128bits(
                                                                  macAlgorithm: crypto.Hmac.sha256());
                                                              var randomPsw =
                                                                  crypto.SecretKeyData.random(length: 16).bytes;
                                                              var secretKey =
                                                                  await algo.newSecretKeyFromBytes(randomPsw);
                                                              if (shareFilePsw != "") {
                                                                List<int> list=List.from(utf8.encode(shareFilePsw));
                                                                
                                                                if(list.length<16){
                                                                  while(list.length<16){
                                                                    list.add(0);
                                                                  }
                                                                }else if(list.length>16){
                                                                  list=list.sublist(0,15);
                                                                }
                                                                secretKey = await algo
                                                                    .newSecretKeyFromBytes(list);
                                                              }
                                                              final expireTime = DateTime.now().millisecondsSinceEpoch +
                                                                  shareFileValidDays * 24 * 60 * 60 * 1000;
                                                              var encryptedShareLink = await algo.encrypt(
                                                                  utf8.encode(shareUuid),
                                                                  secretKey: secretKey);
                                                              await http.put(
                                                                  Uri.parse(remoteUrl +
                                                                      '/passageOther/share/real/$shareUuid'),
                                                                  body: jsonEncode({
                                                                    "source": shareUuid,
                                                                    "psw": shareFilePsw == ""
                                                                        ? dem2Hex(randomPsw)
                                                                        : shareFilePsw,
                                                                    "expireDate": expireTime,
                                                                    "shareDate":DateTime.now().millisecondsSinceEpoch,
                                                                    "shareName":jsonEncode(shareFiles),
                                                                    "crypted": dem2Hex(encryptedShareLink.cipherText)
                                                                  }));
                                                              await http.put(
                                                                  Uri.parse(remoteUrl +
                                                                      '/passageOther/share/deCrypto/${dem2Hex(encryptedShareLink.cipherText)}'),
                                                                  body: jsonEncode({
                                                                    "mac": jsonEncode(encryptedShareLink.mac.bytes),
                                                                    "nonce": jsonEncode(encryptedShareLink.nonce),
                                                                    "cipherText":
                                                                        jsonEncode(encryptedShareLink.cipherText)
                                                                  }));
                                                              store.shareList.add(shareUuid);
                                                              store.shareList.refresh();
                                                              await http.put(
                                                                  Uri.parse(remoteUrl +
                                                                      '/passageOther/share/user/${store.token.value}'),
                                                                  body: jsonEncode(store.shareList));

                                                              Clipboard.setData(ClipboardData(
                                                                  text:
                                                                      "Netdisk Shared Code: ${dem2Hex(encryptedShareLink.cipherText)} and extract code is ${shareFilePsw == "" ? dem2Hex(randomPsw) : shareFilePsw}."));
                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                content: Text("已复制到剪切板"),
                                                                duration: Duration(milliseconds: 500),
                                                              ));
                                                              Navigator.pop(context);
                                                            },
                                                          ),
                                                        ),
                                                        Text(
                                                          "复制链接",
                                                          style: TextStyle(fontSize: 14, color: Colors.black),
                                                        )
                                                      ],
                                                    ),
                                                    Divider(
                                                      color: Colors.transparent,
                                                      indent: 10,
                                                    ),
                                                    Column(
                                                      children: [
                                                        Container(
                                                          width: 50,
                                                          height: 50,
                                                          decoration: BoxDecoration(
                                                              color: Color.fromARGB(255, 240, 240, 240),
                                                              shape: BoxShape.circle),
                                                          child: IconButton(
                                                            icon: Icon(Icons.share),
                                                            onPressed: () async {
                                                              final chosenIDs = chosenMap.keys.toList();
                                                              var fileSet = <String>[];
                                                              var shareFiles=<String>[];
                                                              for (var element in chosenIDs) {
                                                                var child = visitor.visitee.getChild(element);
                                                                if (child.file.fileType == 'file') {
                                                                  fileSet.add(element);
                                                                  shareFiles.add(child.file.fileName);
                                                                } else if (child.file.fileType == 'folder') {
                                                                  var fileRes = await http.get(Uri.parse(
                                                                      remoteUrl + '/?prefix=${child.file.fileID}'));
                                                                  var files = getFileFromXML(fileRes.body);
                                                                  for (var i in files) {
                                                                    if (i.fileID.endsWith('/') == false) {
                                                                      fileSet.add(i.fileID);
                                                                      shareFiles.add(i.fileName);
                                                                    }
                                                                  }
                                                                }
                                                              }
                                                              String shareUuid = md5
                                                                  .convert(utf8.encode(fileSet.join(",") +
                                                                  DateTime.now().microsecondsSinceEpoch.toString()))
                                                                  .toString();
                                                              var res = <String>[];
                                                              String prefix = store.nowDir.join("/");
                                                              for (var i in fileSet) {
                                                                final relAdd = RegExp('(?<=$prefix/)(.*)\$')
                                                                    .firstMatch(i)!
                                                                    .group(1);
                                                                var symlinkRes = await http.put(
                                                                    Uri.parse(remoteUrl +
                                                                        '/passageOther/share/files/$shareUuid/$relAdd?symlink'),
                                                                    headers: {"x-oss-symlink-target": i});
                                                                if (symlinkRes.statusCode == 200) {
                                                                  res.add(
                                                                      'passageOther/share/${store.token.value}/$shareUuid/$relAdd');
                                                                }
                                                              }
                                                              final algo = crypto.AesCtr.with128bits(
                                                                  macAlgorithm: crypto.Hmac.sha256());
                                                              var randomPsw =
                                                                  crypto.SecretKeyData.random(length: 16).bytes;
                                                              var secretKey =
                                                              await algo.newSecretKeyFromBytes(randomPsw);
                                                              if (shareFilePsw != "") {
                                                                secretKey = await algo
                                                                    .newSecretKeyFromBytes(utf8.encode(shareFilePsw));
                                                              }
                                                              final expireTime = DateTime.now().millisecondsSinceEpoch +
                                                                  shareFileValidDays * 24 * 60 * 60 * 1000;
                                                              var encryptedShareLink = await algo.encrypt(
                                                                  utf8.encode(shareUuid),
                                                                  secretKey: secretKey);
                                                              await http.put(
                                                                  Uri.parse(remoteUrl +
                                                                      '/passageOther/share/real/$shareUuid'),
                                                                  body: jsonEncode({
                                                                    "source": shareUuid,
                                                                    "psw": shareFilePsw == ""
                                                                        ? dem2Hex(randomPsw)
                                                                        : shareFilePsw,
                                                                    "expireDate": expireTime,
                                                                    "shareDate":DateTime.now().millisecondsSinceEpoch,
                                                                    "shareName":shareFiles.join(","),
                                                                    "crypted": dem2Hex(encryptedShareLink.cipherText)
                                                                  }));
                                                              await http.put(
                                                                  Uri.parse(remoteUrl +
                                                                      '/passageOther/share/deCrypto/${dem2Hex(encryptedShareLink.cipherText)}'),
                                                                  body: jsonEncode({
                                                                    "mac": jsonEncode(encryptedShareLink.mac.bytes),
                                                                    "nonce": jsonEncode(encryptedShareLink.nonce),
                                                                    "cipherText":
                                                                    jsonEncode(encryptedShareLink.cipherText)
                                                                  }));
                                                              store.shareList.add(shareUuid);
                                                              store.shareList.refresh();
                                                              await http.put(
                                                                  Uri.parse(remoteUrl +
                                                                      '/passageOther/share/user/${store.token.value}'),
                                                                  body: jsonEncode(store.shareList));
                                                              Share.share(
                                                                  "Netdisk Shared Code: $encryptedShareLink and extract code is ${shareFilePsw == "" ? dem2Hex(randomPsw) : shareFilePsw}.");
                                                              Navigator.pop(context);
                                                            },
                                                          ),
                                                        ),
                                                        Text(
                                                          "其他应用",
                                                          style: TextStyle(fontSize: 14, color: Colors.black),
                                                        )
                                                      ],
                                                    )
                                                  ],
                                                ),
                                                OutlinedButton(
                                                    style: OutlinedButton.styleFrom(
                                                      side: BorderSide.none,
                                                      backgroundColor: Color.fromARGB(255, 240, 240, 240),
                                                    ),
                                                    onPressed: () {
                                                      showModalBottomSheet(
                                                          context: context,
                                                          backgroundColor: Colors.transparent,
                                                          builder: (
                                                            BuildContext context,
                                                          ) {
                                                            return Container(
                                                              height: 300,
                                                              child: ClipRRect(
                                                                  borderRadius: BorderRadius.only(
                                                                      topLeft: Radius.circular(16),
                                                                      topRight: Radius.circular(16)),
                                                                  child: Container(
                                                                    color: Colors.white,
                                                                    child: Column(
                                                                      children: [
                                                                        Container(
                                                                          child: Text("有效期设置"),
                                                                        ),
                                                                        Divider(),
                                                                        Expanded(
                                                                            child: OutlinedButton(
                                                                                style: OutlinedButton.styleFrom(
                                                                                    side: BorderSide.none),
                                                                                onPressed: () {
                                                                                  setState(() {
                                                                                    shareFileValidDays = 7;
                                                                                    Navigator.pop(context);
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  width: double.infinity,
                                                                                  child: Row(
                                                                                    mainAxisAlignment:
                                                                                        MainAxisAlignment.spaceBetween,
                                                                                    children: [
                                                                                      RichText(
                                                                                          text: TextSpan(children: [
                                                                                        TextSpan(
                                                                                            text: "7",
                                                                                            style: TextStyle(
                                                                                                color: Colors.blue,
                                                                                                fontWeight:
                                                                                                    FontWeight.bold)),
                                                                                        TextSpan(
                                                                                            text: "天内有效",
                                                                                            style: TextStyle(
                                                                                                color: Colors.black))
                                                                                      ])),
                                                                                      Icon(Icons.check,
                                                                                          color: shareFileValidDays == 7
                                                                                              ? Colors.blue
                                                                                              : Colors.transparent)
                                                                                    ],
                                                                                  ),
                                                                                ))),
                                                                        Expanded(
                                                                            child: OutlinedButton(
                                                                                style: OutlinedButton.styleFrom(
                                                                                    side: BorderSide.none),
                                                                                onPressed: () {
                                                                                  setState(() {
                                                                                    shareFileValidDays = 14;
                                                                                    Navigator.pop(context);
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                    width: double.infinity,
                                                                                    child: Row(
                                                                                      mainAxisAlignment:
                                                                                          MainAxisAlignment
                                                                                              .spaceBetween,
                                                                                      children: [
                                                                                        RichText(
                                                                                            text: TextSpan(children: [
                                                                                          TextSpan(
                                                                                              text: "14",
                                                                                              style: TextStyle(
                                                                                                  color: Colors.blue,
                                                                                                  fontWeight:
                                                                                                      FontWeight.bold)),
                                                                                          TextSpan(
                                                                                              text: "天内有效",
                                                                                              style: TextStyle(
                                                                                                  color: Colors.black))
                                                                                        ])),
                                                                                        Icon(Icons.check,
                                                                                            color: shareFileValidDays ==
                                                                                                    14
                                                                                                ? Colors.blue
                                                                                                : Colors.transparent)
                                                                                      ],
                                                                                    )))),
                                                                        Expanded(
                                                                          child: OutlinedButton(
                                                                              style: OutlinedButton.styleFrom(
                                                                                  side: BorderSide.none),
                                                                              onPressed: () {
                                                                                setState(() {
                                                                                  shareFileValidDays = 30;
                                                                                  Navigator.pop(context);
                                                                                });
                                                                              },
                                                                              child: Container(
                                                                                width: double.infinity,
                                                                                child: Row(
                                                                                  mainAxisAlignment:
                                                                                      MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    RichText(
                                                                                        text: TextSpan(children: [
                                                                                      TextSpan(
                                                                                          text: "30",
                                                                                          style: TextStyle(
                                                                                              color: Colors.blue,
                                                                                              fontWeight:
                                                                                                  FontWeight.bold)),
                                                                                      TextSpan(
                                                                                          text: "天内有效",
                                                                                          style: TextStyle(
                                                                                              color: Colors.black))
                                                                                    ])),
                                                                                    Icon(Icons.check,
                                                                                        color: shareFileValidDays == 30
                                                                                            ? Colors.blue
                                                                                            : Colors.transparent)
                                                                                  ],
                                                                                ),
                                                                              )),
                                                                        ),
                                                                        Expanded(
                                                                          child: OutlinedButton(
                                                                              style: OutlinedButton.styleFrom(
                                                                                  side: BorderSide.none),
                                                                              onPressed: () {
                                                                                setState(() {
                                                                                  shareFileValidDays = 36500;
                                                                                  Navigator.pop(context);
                                                                                });
                                                                              },
                                                                              child: Container(
                                                                                width: double.infinity,
                                                                                child: Row(
                                                                                  mainAxisAlignment:
                                                                                      MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Column(
                                                                                      mainAxisAlignment:
                                                                                          MainAxisAlignment.center,
                                                                                      crossAxisAlignment:
                                                                                          CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Text(
                                                                                          "永久有效",
                                                                                          style: TextStyle(
                                                                                              fontWeight:
                                                                                                  FontWeight.bold,
                                                                                              color: Colors.black),
                                                                                        ),
                                                                                        Text(
                                                                                          "在手动取消前，分享持续有效",
                                                                                          style: TextStyle(
                                                                                              fontSize: 14,
                                                                                              color: Colors.grey),
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                    Icon(Icons.check,
                                                                                        color:
                                                                                            shareFileValidDays == 36500
                                                                                                ? Colors.blue
                                                                                                : Colors.transparent)
                                                                                  ],
                                                                                ),
                                                                              )),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  )),
                                                            );
                                                          });
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        RichText(
                                                            text: TextSpan(children: [
                                                          TextSpan(
                                                              text:
                                                                  "${shareFileValidDays == 36500 ? "永久" : shareFileValidDays} ",
                                                              style: TextStyle(
                                                                  color: Colors.blue, fontWeight: FontWeight.bold)),
                                                          TextSpan(
                                                              text: "${shareFileValidDays == 36500 ? "" : "天内"}有效",
                                                              style: TextStyle(color: Colors.black))
                                                        ])),
                                                        Text(
                                                          ">",
                                                          style: TextStyle(color: Colors.grey),
                                                        )
                                                      ],
                                                    )),
                                                Container(
                                                  constraints: BoxConstraints(maxHeight: 40),
                                                  child: TextField(
                                                    decoration: const InputDecoration(
                                                        hintText: "设置提取码(不设置时自动生成)",
                                                        fillColor: Color.fromARGB(255, 240, 240, 240),
                                                        filled: true,
                                                        focusColor: Color.fromARGB(255, 248, 248, 248),
                                                        border: OutlineInputBorder(borderSide: BorderSide.none),
                                                        contentPadding: EdgeInsets.only(left: 10, top: 10, bottom: 10)),
                                                    onChanged: (v) => setState(() {
                                                      shareFilePsw = v;
                                                    }),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                                    },
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: "111",
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.share, color: Colors.white),
                                    Text("分享", style: TextStyle(color: Colors.white)),
                                  ],
                                ))),
                        (widget.from!=null&&widget.from=="share")?Container():Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: BorderSide.none, primary: Color(0x2B196322)),
                                onPressed: () {
                                  final chosenIDs = chosenMap.keys.toList();
                                  http
                                      .post(Uri.parse(baseURl + '/favorite/add'),
                                          headers: {
                                            "Authorization": "Basic ${base64Encode(utf8.encode(store.token.value))}"
                                          },
                                          body: jsonEncode({"ids": chosenIDs}))
                                      .then((v) {
                                    final data = jsonDecode(v.body)["data"]["result"];
                                    setState(() {
                                      Navigator.pop(context);
                                      chooseMode = false;
                                    });
                                    if (data == 'ok') {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text("收藏成功"),
                                        duration: Duration(milliseconds: 500),
                                      ));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text("收藏失败"),
                                        duration: Duration(milliseconds: 500),
                                      ));
                                    }
                                  });
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star_outlined,
                                      color: Colors.white,
                                    ),
                                    Text("收藏", style: TextStyle(color: Colors.white)),
                                  ],
                                ))),
                        (widget.from!=null&&widget.from=="share")?Container():Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide.none, primary: Color(0x2B196322), backgroundColor: Colors.red),
                                onPressed: () async{
                                  final chosenIDs = chosenMap.keys.toList();
                                  var res=await http.delete(Uri.parse(remoteUrl+'/'+e.fileID));
                                  setState(() {
                                    for (final item in chosenIDs) {
                                      visitor.visitee.getChild(item).file.delete();
                                    }
                                    visitor = visitor.buildChildren(files);
                                    chooseMode = false;
                                    Navigator.pop(context);
                                  });
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                    Text("删除", style: TextStyle(color: Colors.white)),
                                  ],
                                ))),
                        Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    side: BorderSide.none, primary: Color(0x2B196322), backgroundColor: Colors.blue),
                                onPressed: () {
                                  //TODO: 转存
                                  final chosenIDs = chosenMap.keys.toList();
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                    Text("转存", style: TextStyle(color: Colors.white)),
                                  ],
                                ))),
                        // Expanded(child: OutlinedButton(
                        //     style: OutlinedButton.styleFrom(side: BorderSide.none,primary: Color(0x2B196322)),
                        //     onPressed: () {},
                        //     child: Column(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Icon(
                        //           Icons.more_horiz,
                        //           color: Colors.white,
                        //         ),
                        //         Text("更多", style: TextStyle(color: Colors.white))
                        //       ],
                        //     )))
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
                  store.nowDir.add(e.fileName);

                  if (!visitor.hasChild()) {
                    http
                        .get(Uri.parse(remoteUrl + "/?prefix=passageOther/disk/${store.nowDir.join('/')}/&delimiter=/"))
                        .then((res) {
                      if (res.statusCode == 200) {
                        var transformer = Xml2Json();
                        files = [];
                        transformer.parse(res.body);
                        var json = jsonDecode(transformer.toParker());
                        if (json['ListBucketResult']['CommonPrefixes'] != null) {
                          if (json['ListBucketResult']['CommonPrefixes'] is! List) {
                            var ele = json['ListBucketResult']['CommonPrefixes'];
                            final filename = ele['Prefix'].replaceAll(RegExp(r"/$"), "").split('/');
                            files.add(
                              File(
                                  fileName: filename.last,
                                  fileID: ele['Prefix'],
                                  fileSize: "0",
                                  date: "0",
                                  fileType: 'folder',
                                  lastModifiedTime: DateTime.now()),
                            );
                          } else {
                            json['ListBucketResult']['CommonPrefixes'].forEach((ele) {
                              final filename = ele['Prefix'].replaceAll(RegExp(r"/$"), "").split('/');
                              files.add(
                                File(
                                    fileName: filename.last,
                                    fileID: ele['Prefix'],
                                    fileSize: "0",
                                    date: "0",
                                    fileType: 'folder',
                                    lastModifiedTime: DateTime.now()),
                              );
                            });
                          }
                        }
                        if (json['ListBucketResult']['Contents'] != null) {
                          if (json['ListBucketResult']['Contents'] is! List) {
                            var ele = json['ListBucketResult']['Contents'];
                            final filename = ele['Key'].replaceAll(RegExp(r"/$"), "").split('/');
                            files.add(File(
                              fileName: filename.last,
                              fileID: ele['Key'],
                              fileSize: ele['Size'],
                              date: DateTime.parse(ele['LastModified']).millisecondsSinceEpoch.toString(),
                              fileType: 'file',
                              lastModifiedTime: DateTime.parse(ele['LastModified']),
                            ));
                          } else {
                            json['ListBucketResult']['Contents'].forEach((ele) {
                              if ((ele['Key'] as String).endsWith('/')) {
                                return;
                              }
                              final filename = ele['Key'].replaceAll(RegExp(r"/$"), "").split('/');
                              files.add(File(
                                fileName: filename.last,
                                fileID: ele['Key'],
                                fileSize: ele['Size'],
                                date: DateTime.parse(ele['LastModified']).millisecondsSinceEpoch.toString(),
                                fileType: 'file',
                                lastModifiedTime: DateTime.parse(ele['LastModified']),
                              ));
                            });
                          }
                        }

                        store.nowDir.refresh();
                        setState(() {
                          visitor = visitor.buildChildren(files);
                        });
                      }
                    });
                  }
                });
              } else if (e.fileType == "file") {
                Navigator.pushNamed(context, "/file",
                    arguments: {'file': e, 'location': visitor.getFilePathToRoot(e.fileID, store.token.value)});
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
                    child: Icon(e.fileType == "file" ? Icons.insert_drive_file_sharp : Icons.folder),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(e.fileName, style: const TextStyle(color: Colors.black, fontSize: 16)),
                      e.fileType == "file"
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  getFormatTime(DateTime.fromMillisecondsSinceEpoch(int.parse(e.date)), needYear: true),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  child: Text(e.fileType == "file" ? formatSize(fileSize) : "",
                                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                )
                              ],
                            )
                          : Container()
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
              store.chooseMode.value = false;
              store.chooseMode.refresh();
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
