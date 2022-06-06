import 'package:flutter/material.dart';
import 'package:netdisk/views/DownloadList.dart';
import 'package:netdisk/views/FavoriteList.dart';
import 'package:netdisk/views/RecycleList.dart';
import 'package:netdisk/views/SharePage.dart';
import 'package:netdisk/views/User.dart';
import 'FileDetail.dart';
import 'FileList.dart';
import 'package:get/get.dart';
import '../Store.dart' show Store;

class DiskRootApp extends StatelessWidget {
  const DiskRootApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Store store=Get.put(Store());
    return GetMaterialApp(
      title: 'Diana Disk',
      routes: {
        '/': (BuildContext context) => const DiskApp(),
        '/download': (BuildContext context) => const DownloadList(),
        '/recycle':(BuildContext context) =>const RecycleList(),
        '/favorite':(BuildContext context) =>const FavoriteList()
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/file') {
          return MaterialPageRoute<File>(builder: (context) {
            return FileDetail(file: settings.arguments as File);
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
  const DiskApp({Key? key}) : super(key: key);

  @override
  State<DiskApp> createState() => _DiskAppState();
}

class _DiskAppState extends State<DiskApp> {
  late Function fileListGoBackCallBack;
  int _currentIndex = 0;

  void onBack(Function fn) {
    fileListGoBackCallBack = fn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        toolbarTextStyle: const TextStyle(color: Colors.black),
        elevation: 0,
        title: _currentIndex==0
            ? Text("我的文件",style: TextStyle(color: Colors.black,fontSize: 16),)
            : _currentIndex==1
              ? Text("我的分享",style: TextStyle(color:Colors.black,fontSize: 16),)
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
          setState(() {
            _currentIndex = index;
          });
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
            child:const TextField(

              decoration: InputDecoration(

                hintText: "搜索网盘文件",
                contentPadding: EdgeInsets.all(10),
                prefixIcon: Icon(Icons.search),
                fillColor: Color.fromARGB(255, 240, 240, 240),
                filled: true,
                focusColor: Color.fromARGB(255, 248, 248, 248),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide.none
                ),

              )
            ),
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
    return Padding(padding: const EdgeInsets.only(left:16),
    child:Flex(
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
    )
    );
  }
}
