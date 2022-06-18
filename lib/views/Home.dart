import 'dart:io' as io;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:netdisk/UploadIsolate.dart';
import 'package:netdisk/views/AccountSettings.dart';
import 'package:netdisk/views/DownloadList.dart';
import 'package:netdisk/views/FavoriteList.dart';
import 'package:netdisk/views/OtherSettings.dart';
import 'package:netdisk/views/RecycleList.dart';
import 'package:netdisk/views/UserInfoSettings.dart';
import 'package:netdisk/views/SharePage.dart';
import 'package:netdisk/views/User.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../GlobalClass.dart' show FileDescriptor, FileState, NavigatorKey, User, dem2Hex, hex2Dem;
import '../GlobalVariables.dart';
import 'FileDetail.dart';
import 'FileList.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../Store.dart' show Store;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class DiskRootApp extends StatelessWidget with WidgetsBindingObserver {
  const DiskRootApp({Key? key}) : super(key: key);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.inactive:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.paused:
        // TODO: Handle this case.
        break;
      case AppLifecycleState.detached:
        // TODO: Handle this case.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Store store = Get.put(Store());
    return GetMaterialApp(
      navigatorKey: NavigatorKey.key,
      title: 'Diana Disk',
      routes: {
        '/download': (BuildContext context) => const DownloadList(),
        '/recycle': (BuildContext context) => const RecycleList(),
        '/favorite': (BuildContext context) => const FavoriteList(),
        '/settings/userinfo': (BuildContext context) => const UserInfoSettingsPage(),
        '/settings/account': (BuildContext context) => const AccountSettingsPage(),
        '/settings/other': (BuildContext context) => const OtherSettingsPage()
      },
      supportedLocales: [Locale('en')],
      onGenerateRoute: (settings) {
        if (settings.name == '/file') {
          return MaterialPageRoute<File>(builder: (context) {
            return FileDetail(argv: settings.arguments as dynamic);
          });
        } else if (settings.name == "/") {
          return MaterialPageRoute<File>(builder: (context) {
            return DiskApp(initFile: settings.arguments == null ? null : (settings.arguments as dynamic)['file'],from:settings.arguments == null ? null : (settings.arguments as dynamic)['from']);
          });
        } else {
          return null;
        }
      },
      debugShowCheckedModeBanner: true,
    );
  }
}

class DiskApp extends StatefulWidget {
  final File? initFile;
  final String? from;
  const DiskApp({Key? key, this.initFile,this.from}) : super(key: key);

  @override
  State<DiskApp> createState() => _DiskAppState();
}

class _DiskAppState extends State<DiskApp> {
  late Function fileListGoBackCallBack;
  late Function shouldFileBottomSheetClose;
  int _currentIndex = 0;
  final Store store = Get.find();

  @override
  void initState() {
    // TODO: implement initState
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
            } else {
              preference.remove('token');
            }
          });
        }
      });
    }
    store.loadFromDisk();
  }

  void onBack(Function fn) {
    fileListGoBackCallBack = fn;
  }

  void onChangeNavi(Function fn) {
    shouldFileBottomSheetClose = fn;
  }
  bool isWrongCode=false;
  String newFolderName = "";
  String shareLink = "";
  String extractCode = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: (widget.from!=null&&widget.from=="share")?Container():Obx(() {
        return ((_currentIndex == 0) && (store.chooseMode.value == false))
            ? FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) {
                        return ClipRRect(
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white),
                            constraints: BoxConstraints(maxHeight: 200),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: BorderSide.none),
                                      onPressed: () async {
                                        var result = await FilePicker.platform.pickFiles(
                                          type: FileType.image
                                        );
                                        if (result != null) {
                                          io.File file = io.File(result.files.single.path!);
                                          String filename = result.files.single.path!.split(RegExp("/|\\\\")).last;
                                          UploadIsolate uploader = UploadIsolate(file, store.nowDir.value, nowEtag: {});
                                          String uploadID="";
                                          uploader.start(store.token.value, onInit: (uploadID_){
                                            uploadID=uploadID_;
                                          },onProcess: (ok, size,nextPart,etag) {
                                            if (store.uploadList[filename] == null) {
                                              store.uploadList[filename] = FileDescriptor(filename,
                                                  result.files.single.path!, DateTime.now().millisecondsSinceEpoch,0);
                                              store.uploadList[filename]!.state = FileState.downloading;
                                              store.uploadList[filename]!.uploadIsolate=uploader;
                                              store.uploadList[filename]!.uploadID=uploadID;
                                            }
                                            store.uploadList[filename]!.size = size;
                                            store.uploadList[filename]!.rec = ok;
                                            store.uploadList[filename]!.nowPart=nextPart;
                                            store.uploadList[filename]!.eTag[nextPart-1]=etag;
                                            store.saveToDisk();
                                            store.uploadList.refresh();
                                          }, onFinish: () {
                                            store.uploadList[filename]!.state = FileState.done;
                                            store.saveToDisk();
                                            store.uploadList.refresh();
                                          });
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size: 40,
                                          ),
                                          Text(
                                            "上传图片",
                                            style: TextStyle(color: Colors.black),
                                          )
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: BorderSide.none),
                                      onPressed: ()async {
                                        var result = await FilePicker.platform.pickFiles(
                                          type: FileType.audio
                                        );
                                        if (result != null) {
                                          io.File file = io.File(result.files.single.path!);
                                          String filename = result.files.single.path!.split(RegExp("/|\\\\")).last;
                                          UploadIsolate uploader = UploadIsolate(file, store.nowDir.value,nowEtag: {});
                                          String uploadID="";
                                          uploader.start(store.token.value,onInit: (uploadID_){
                                            uploadID=uploadID_;
                                          }, onProcess: (ok, size,nextPart,etag) {
                                            if (store.uploadList[filename] == null) {
                                              store.uploadList[filename] = FileDescriptor(filename,
                                                  result.files.single.path!, DateTime.now().millisecondsSinceEpoch,0);
                                              store.uploadList[filename]!.state = FileState.downloading;
                                              store.uploadList[filename]!.uploadIsolate=uploader;
                                              store.uploadList[filename]!.uploadID=uploadID;
                                            }
                                            store.uploadList[filename]!.size = size;
                                            store.uploadList[filename]!.rec = ok;
                                            store.uploadList[filename]!.nowPart=nextPart;
                                            store.uploadList[filename]!.eTag[nextPart-1]=etag;
                                            store.saveToDisk();
                                            store.uploadList.refresh();
                                          }, onFinish: () {
                                            store.uploadList[filename]!.state = FileState.done;
                                            store.saveToDisk();
                                            store.uploadList.refresh();
                                          });
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.video_collection,
                                            size: 40,
                                          ),
                                          Text(
                                            "上传视频",
                                            style: TextStyle(color: Colors.black),
                                          )
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: BorderSide.none),
                                      onPressed: () async {
                                        var result = await FilePicker.platform.pickFiles();
                                        if (result != null) {
                                          io.File file = io.File(result.files.single.path!);
                                          String filename = result.files.single.path!.split(RegExp("/|\\\\")).last;
                                          var nowPath=List<String>.from(store.nowDir);
                                          print(nowPath);
                                          UploadIsolate uploader = UploadIsolate(file, store.nowDir.value,nowEtag: {});
                                          String uploadID="";
                                          uploader.start(store.token.value,onInit: (uploadID_){
                                            uploadID=uploadID_;
                                          }, onProcess: (ok, size,nextPart,etag) {
                                            if (store.uploadList[filename] == null) {
                                              store.uploadList[filename] = FileDescriptor(filename,
                                                  result.files.single.path!, DateTime.now().millisecondsSinceEpoch,0);
                                              store.uploadList[filename]!.state = FileState.downloading;
                                              store.uploadList[filename]!.uploadSavePath=nowPath;
                                              store.uploadList[filename]!.uploadIsolate=uploader;
                                              store.uploadList[filename]!.uploadID=uploadID;
                                            }
                                            store.uploadList[filename]!.state = FileState.downloading;
                                            store.uploadList[filename]!.size = size;
                                            store.uploadList[filename]!.eTag[nextPart-1]=etag;
                                            store.uploadList[filename]!.rec = ok;
                                            store.uploadList[filename]!.nowPart=nextPart;
                                            store.saveToDisk();
                                            store.uploadList.refresh();
                                          }, onFinish: () {
                                            store.uploadList[filename]!.state = FileState.done;
                                            store.saveToDisk();
                                            store.uploadList.refresh();
                                          });
                                        }
                                      },
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.upload_file_outlined,
                                            size: 40,
                                          ),
                                          Text(
                                            "上传其他",
                                            style: TextStyle(color: Colors.black),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                Divider(
                                  height: 50,
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: BorderSide.none),
                                      onPressed: () async {
                                        showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) {
                                              return StatefulBuilder(builder: (context, setState) {
                                                return AnimatedPadding(
                                                  padding:
                                                      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                                  duration: Duration.zero,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.only(
                                                        topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                                    child: Container(
                                                      constraints: BoxConstraints(maxHeight: 100),
                                                      child: TextField(
                                                        decoration: InputDecoration(
                                                            hintText: "请输入文件夹名称",
                                                            filled: true,
                                                            fillColor: Colors.white),
                                                        onSubmitted: (v) async {
                                                          setState(() {
                                                            newFolderName = v;
                                                          });
                                                          await http.put(Uri.parse(remoteUrl +
                                                              '/passageOther/disk/${store.nowDir.join("/")}/$newFolderName/'));
                                                          Navigator.pop(context);
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              });
                                            });
                                      },
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.create_new_folder,
                                            size: 40,
                                          ),
                                          Text(
                                            "新建文件夹",
                                            style: TextStyle(color: Colors.black),
                                          )
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: BorderSide.none),
                                      onPressed: () async {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return Dialog(child: StatefulBuilder(builder: (context, setState) {
                                                return Container(
                                                  padding: EdgeInsets.all(10),
                                                  constraints: BoxConstraints(maxWidth: 200, maxHeight: 240),
                                                  child: Column(
                                                    children: [
                                                      Text("提取分享的文件"),
                                                      Divider(
                                                        height: 10,
                                                        color: Colors.black,
                                                      ),
                                                      TextField(
                                                        controller: TextEditingController(text: shareLink),
                                                        decoration: InputDecoration(
                                                          hintText: "请输入链接",
                                                          filled: true,
                                                          fillColor: Colors.white,
                                                        ),
                                                        onSubmitted: (v) async {
                                                          setState(() {
                                                            shareLink = v;
                                                            isWrongCode=false;
                                                          });
                                                          await http.put(Uri.parse(remoteUrl +
                                                              '/passageOther/disk/${store.nowDir.join("/")}/$newFolderName/'));
                                                          Navigator.pop(context);
                                                        },
                                                      ),
                                                      Divider(
                                                        height: 10,
                                                        color: Colors.transparent,
                                                      ),
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Text("提取码: "),
                                                          Container(
                                                            height: 50,
                                                            constraints: BoxConstraints(maxWidth: 200),
                                                            child: TextField(
                                                              controller: TextEditingController(
                                                                text: extractCode,
                                                              ),
                                                              decoration: InputDecoration(
                                                                  hintText: "请输入提取码",
                                                                  filled: true,
                                                                  fillColor: Colors.white,
                                                                contentPadding: EdgeInsets.only(top: 4,bottom: 2)
                                                              ),
                                                              onSubmitted: (v) async {
                                                                setState(() {
                                                                  extractCode = v;
                                                                  isWrongCode=false;
                                                                });
                                                                await http.put(Uri.parse(remoteUrl +
                                                                    '/passageOther/disk/${store.nowDir.join("/")}/$newFolderName/'));
                                                                Navigator.pop(context);
                                                              },
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                      Spacer(),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: [
                                                          OutlinedButton(
                                                              onPressed: () async {
                                                                var reg = RegExp(
                                                                    r"^Netdisk Shared Code: (.*) and extract code is (.*)\.$");
                                                                var p = await Clipboard.getData(Clipboard.kTextPlain);
                                                                if (p != null && p.text != null) {
                                                                  var t = reg.firstMatch(p.text!);
                                                                  if (t?.group(1) != null && t?.group(2) != null) {
                                                                    setState(() {
                                                                      extractCode = t!.group(2)!;
                                                                      shareLink = t.group(1)!;
                                                                      isWrongCode=false;
                                                                    });
                                                                  }
                                                                }
                                                              },
                                                              child: Text("从剪切板获取")),
                                                          Spacer(),
                                                          OutlinedButton(
                                                              onPressed: ()async {
                                                                var res=await http.get(Uri.parse(remoteUrl+'/passageOther/share/deCrypto/$shareLink'));
                                                                if(res.statusCode==200){
                                                                  var secretBox=jsonDecode(res.body);
                                                                  var mac=jsonDecode(secretBox['mac']);
                                                                  var newMac=<int>[];
                                                                  mac.forEach((v){newMac.add(v);});
                                                                  var nonce=jsonDecode(secretBox['nonce']);
                                                                  var newNonce=<int>[];
                                                                  nonce.forEach((v){newNonce.add(v);});
                                                                  var cipherText=jsonDecode(secretBox['cipherText']);
                                                                  var text=<int>[];
                                                                  cipherText.forEach((v){text.add(v);});
                                                                  var ans=<int>[];
                                                                  var deCryptor=SecretBox(text, nonce: newNonce, mac: Mac(newMac));
                                                                  var algo=AesCtr.with128bits(macAlgorithm: Hmac.sha256());
                                                                  if(extractCode.length<32){
                                                                    List<int>psw=List<int>.from(utf8.encode(extractCode));
                                                                    if(psw.length<16){
                                                                      while(psw.length<16){
                                                                        psw.add(0);
                                                                      }
                                                                    }else if(psw.length>16){
                                                                      psw=psw.sublist(0,15);
                                                                    }
                                                                    ans=await algo.decrypt(deCryptor, secretKey: await algo.newSecretKeyFromBytes(psw));
                                                                  }else{
                                                                    ans=await algo.decrypt(deCryptor, secretKey: await algo.newSecretKeyFromBytes(hex2Dem(extractCode)));
                                                                  }
                                                                  String truePath=utf8.decode(ans);
                                                                  var result=await http.get(Uri.parse(remoteUrl+'/?prefix=passageOther/share/files/$truePath/&delimiter=/'));
                                                                  if(result.statusCode!=200){
                                                                    showDialog(
                                                                      context: context,
                                                                      builder: (context){
                                                                        return AlertDialog(
                                                                          content: Text("提取码错误"),
                                                                        );
                                                                      }
                                                                    );
                                                                  }else{
                                                                    File sharedFile=File(fileName: "",fileSize: "",date: "", fileType: 'folder',fileID:"passageOther/share/files/$truePath/", lastModifiedTime: DateTime.now(),);
                                                                    Navigator.pushNamed(context,'/',arguments: {"file":sharedFile,"from":"share"});
                                                                  }
                                                                }
                                                              },
                                                              style: OutlinedButton.styleFrom(
                                                                  backgroundColor: Colors.blue),
                                                              child: Text(
                                                                "提取",
                                                                style: TextStyle(color: Colors.white),
                                                              )),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                );
                                              }));
                                            });
                                      },
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.link,
                                            size: 40,
                                          ),
                                          Text(
                                            "提取文件",
                                            style: TextStyle(color: Colors.black),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                },
                child: Icon(Icons.add),
              )
            : Container();
      }),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        toolbarTextStyle: const TextStyle(color: Colors.black),
        elevation: 0,
        title: (widget.from!=null&&widget.from=="share")
            ?Text(
              "来自分享",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ):_currentIndex == 0
            ? Text(
                "我的文件",
                style: TextStyle(color: Colors.black, fontSize: 16),
              )
            : _currentIndex == 1
                ? Text(
                    "我的分享",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  )
                : null,
        leading: Container(
            alignment: Alignment.center,
            child: BackButton(
              color: Colors.black,
              onPressed: () {
                fileListGoBackCallBack();
              },
            )),
        actions: [
          IconButton(
              icon: const Icon(
                Icons.download,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/download');
              })
        ],
      ),
      body: _currentIndex == 0
          ? Column(
              children: [
                const SizedBox(
                  width: double.infinity,
                  child: SearchBar(),
                ),
                const SizedBox(
                  width: double.infinity,
                  child: Filter(),
                ),
                Expanded(
                    child: FileList(
                  backToParentCallback: onBack,
                  onChangeNavi: onChangeNavi,
                  initFile: widget.initFile,
                      from: widget.from,
                )),
              ],
            )
          : _currentIndex == 1
              ? const SharePage()
              : const UserPage(),
      bottomNavigationBar: (widget.from!=null&&widget.from=="share")?null:BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: "文件",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share),
            label: "分享",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "我的",
          )
        ],
        currentIndex: _currentIndex,
        onTap: (int index) {
          if (index != _currentIndex) {
            shouldFileBottomSheetClose();
            setState(() {
              store.chooseMode.value = false;
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: SizedBox(
          height: 40,
          child: Theme(
            data: ThemeData(primaryColor: Colors.red),
            child: const TextField(
                decoration: InputDecoration(
              hintText: "搜索网盘文件",
              contentPadding: EdgeInsets.all(10),
              prefixIcon: Icon(Icons.search),
              fillColor: Color.fromARGB(255, 240, 240, 240),
              filled: true,
              focusColor: Color.fromARGB(255, 248, 248, 248),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15)), borderSide: BorderSide.none),
            )),
          ),
        ));
  }
}

class Filter extends StatefulWidget {
  const Filter({Key? key}) : super(key: key);

  @override
  State<Filter> createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(left: 16,top: 16,),
        child: Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: [
            const Icon(Icons.arrow_circle_up_sharp),
          ],
        ));
  }
}
