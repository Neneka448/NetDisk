import 'dart:io' as io;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:netdisk/TransferIsolate.dart';
import 'package:netdisk/views/AccountSettings.dart';
import 'package:netdisk/views/DownloadList.dart';
import 'package:netdisk/views/FavoriteList.dart';
import 'package:netdisk/views/OtherSettings.dart';
import 'package:netdisk/views/RecycleList.dart';
import 'package:netdisk/views/UserInfoSettings.dart';
import 'package:netdisk/views/SharePage.dart';
import 'package:netdisk/views/User.dart';
import '../GlobalClass.dart' show NavigatorKey;
import 'FileDetail.dart';
import 'FileList.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../Store.dart' show Store;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
class DiskRootApp extends StatelessWidget {
  const DiskRootApp({Key? key}) : super(key: key);

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
        } else if(settings.name=="/"){
          return MaterialPageRoute<File>(builder: (context) {
            return DiskApp(initFile: settings.arguments==null?null:(settings.arguments as dynamic)['file']);
          });
        }else{
          return null;
        }
      },
      debugShowCheckedModeBanner: true,
    );
  }
}

class DiskApp extends StatefulWidget {
  final File? initFile;
  const DiskApp({Key? key,this.initFile}) : super(key: key);

  @override
  State<DiskApp> createState() => _DiskAppState();
}

class _DiskAppState extends State<DiskApp> {
  late Function fileListGoBackCallBack;
  late Function shouldFileBottomSheetClose;
  int _currentIndex = 0;

  void onBack(Function fn) {
    fileListGoBackCallBack = fn;
  }

  void onChangeNavi(Function fn) {
    shouldFileBottomSheetClose = fn;
  }

  @override
  Widget build(BuildContext context) {
    final Store store = Get.find();
    return Scaffold(
      floatingActionButton: Obx(() {
        return ((_currentIndex == 0) && (store.chooseMode.value == false))
            ? FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) {
                        return ClipRRect(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
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
                                      onPressed: () {

                                      },
                                      child: Column(
                                        children: [Icon(Icons.image_outlined,size: 40,), Text("上传图片",style: TextStyle(color: Colors.black),)],
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: BorderSide.none),
                                      onPressed: () {

                                      },
                                      child: Column(
                                        children: [Icon(Icons.text_snippet,size: 40,), Text("上传文档",style: TextStyle(color: Colors.black),)],
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: BorderSide.none),
                                      onPressed: ()async {
                                        var result=await FilePicker.platform.pickFiles();
                                        if(result!=null){
                                          io.File file=io.File(result.files.single.path!);
                                          TransferUpload uploader=TransferUpload(file);
                                          uploader.start();
                                        }
                                      },
                                      child: Column(
                                        children: [Icon(Icons.upload_file_outlined,size: 40,), Text("上传其他",style: TextStyle(color: Colors.black),)],
                                      ),
                                    )
                                  ],
                                ),
                                Divider(height: 50,),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: BorderSide.none),
                                      onPressed: () {
                                      },
                                      child: Column(
                                        children: [Icon(Icons.create_new_folder,size: 40,), Text("新建文件夹",style: TextStyle(color: Colors.black),)],
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
        title: _currentIndex == 0
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
                )),
              ],
            )
          : _currentIndex == 1
              ? const SharePage()
              : const UserPage(),
      bottomNavigationBar: BottomNavigationBar(
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
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)), borderSide: BorderSide.none),
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
        padding: const EdgeInsets.only(left: 16),
        child: Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: [
            const Icon(Icons.arrow_circle_up_sharp),
            ButtonBar(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.filter)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
              ],
            )
          ],
        ));
  }
}
