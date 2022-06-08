import 'package:flutter/material.dart';
import 'package:netdisk/GlobalClass.dart';

Widget buildBottomSheetWidget(SharedItemInfo shared) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(26),topRight: Radius.circular(26)),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Text(shared.sharedName),
                Text(shared.sharedId),
                Text(getFormatTime(DateTime.fromMillisecondsSinceEpoch(shared.sharedTime),needYear: true)),
                Text(getFormatTime(DateTime.fromMillisecondsSinceEpoch(shared.expireTime),needYear: true))
              ],
            ),
          ),
        ),
      ),
      Container(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.green,
                        side: BorderSide.none,
                        primary: Color.fromARGB(255, 28, 88, 40)),
                    onPressed: () {

                    },
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Text(
                        "延长时间",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ))),
            Expanded(
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        side: BorderSide.none,
                        primary: Color.fromARGB(255, 26, 92, 120)),
                    onPressed: () {},
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Text(
                        "获取链接",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ))),
            Expanded(
                child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red, side: BorderSide.none),
              onPressed: () {},
              child: Container(
                height: 60,
                alignment: Alignment.center,
                child: Text(
                  "删除分享",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ))
          ],
        ),
      )
    ],
  );
}
