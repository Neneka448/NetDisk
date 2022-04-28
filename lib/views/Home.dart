import 'package:flutter/material.dart';
import 'package:netdisk/views/User.dart';
import 'FileList.dart';

class DiskApp extends StatefulWidget {
  const DiskApp({Key? key}) : super(key: key);

  @override
  State<DiskApp> createState() => _DiskAppState();
}

class _DiskAppState extends State<DiskApp> {
  late Function fileListGoBackCallBack;
  int _currentIndex=0;
  void onBack(Function fn) {
    fileListGoBackCallBack = fn;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diana Disk',
      home:Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 250, 250, 250),
          toolbarTextStyle: const TextStyle(color: Colors.black),
          elevation: 0,
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
                  print(1);
                })
          ],
        ),
        body: _currentIndex==0
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
            : const UserPage(),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: "文件",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: "我的",
            )
          ],
          currentIndex:_currentIndex,
          onTap: (int index){
            setState(() {
              _currentIndex=index;
            });
          },
        ),
      ),
      debugShowCheckedModeBanner: true,
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
    return const TextField(
      decoration: InputDecoration(
        labelText: "搜索网盘文件1",
        prefixIcon: Icon(Icons.search),
      ),
    );
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
    return Flex(
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
    );
  }
}
