import 'package:flutter/material.dart';


class RecycleList extends StatefulWidget {
  const RecycleList({Key? key}) : super(key: key);

  @override
  State<RecycleList> createState() => _RecycleListState();
}

class _RecycleListState extends State<RecycleList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        toolbarTextStyle: const TextStyle(color: Colors.black),
        elevation: 0,
        leading: Container(
            alignment: Alignment.center,
            child: BackButton(
              color: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
            )),
      ),
      body: const Text("111"),
    );
  }
}
