

import 'package:flutter/cupertino.dart';

class RawResponse<T>{
  final String status;
  final String desc;
  final T data;
  const RawResponse({required this.status,required this.desc,required this.data});
}

class Token{
  late String token;
  Token(this.token);
  factory Token.fromJson(Map<String, dynamic> json){
    return Token(json['token']);
  }
}

class User{
  late String name;
  late String id;
  late int maxSpace;
  late int usedSpace;
  User({required this.name,required this.id,required this.maxSpace,required this.usedSpace});
  factory User.fromJson(Map<String,dynamic> json){
    return User(name: json['user_name'], id: json['user_id'], maxSpace: json['max_space'], usedSpace: json['used_space']);
  }
}
class SharedItemInfo{
  late String sharedId;
  late int sharedTime;
  late int expireTime;
  late String sharedName;
  SharedItemInfo({required this.sharedName,required this.sharedId,required this.expireTime, required this.sharedTime});
  factory SharedItemInfo.fromJson(Map<String,dynamic> json){
    return SharedItemInfo(sharedName:json['share_name'],sharedId: json['share_id'], sharedTime: int.parse(json['share_time']), expireTime: int.parse(json['expire_time']));
  }
}

String formatSize(double fileSize){
  String fileSizeExt = "bit";
  if (fileSize < 8 * 1024) {
    fileSize /= 8;
    fileSizeExt = "B";
  } else if (fileSize < 8 * 1024 * 1024) {
    fileSizeExt = "KB";
    fileSize /= 8 * 1024;
  } else if (fileSize < 8 * 1024 * 1024 * 1024) {
    fileSizeExt = "MB";
    fileSize /= 8 * 1024 * 1024;
  } else {
    fileSizeExt = "GB";
    fileSize /= 8 * 1024 * 1024 * 1024;
  }

  return fileSize.toStringAsFixed(2)+fileSizeExt;
}

String getFormatTime(DateTime time,{bool needYear=false}){
  if(needYear){
    return "${time.year}-${time.month < 10 ? '0${time.month}' : time.month}-${time.day < 10 ? '0${time.day}' : time.day} ${time.hour < 10 ? '0${time.hour}' : time.hour}:${time.minute < 10 ? '0${time.minute}' : time.minute}";
  }else{
    return "${time.month < 10 ? '0${time.month}' : time.month}-${time.day < 10 ? '0${time.day}' : time.day} ${time.hour < 10 ? '0${time.hour}' : time.hour}:${time.minute < 10 ? '0${time.minute}' : time.minute}";
  }
}

class NavigatorKey{
  static final key=GlobalKey<NavigatorState>();
}