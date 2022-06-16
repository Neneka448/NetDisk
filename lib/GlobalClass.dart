import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:netdisk/views/FileList.dart';
import 'package:xml2json/xml2json.dart';

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
  late String avatar;
  late String nickname;
  User({required this.name,required this.id,required this.maxSpace,required this.usedSpace,required this.avatar,required this.nickname});
  factory User.fromJson(Map<String,dynamic> json){
    return User(name: json['user_name'], id: json['user_id'], maxSpace: json['max_space'],
        usedSpace: json['used_space'],
        avatar: json['avatar'],nickname: json['nickname']);
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
String getFormatDownloadSpeed(FileDescriptor file){
  String ext="B/s";
  double realSpeed=file.rec*1000/(DateTime.now().millisecondsSinceEpoch-file.startTime);
  if(realSpeed>=1024&&realSpeed<1024*1024){
    ext="KB/s";
    realSpeed/=1024;
  }else if(realSpeed>=1024*1024&&realSpeed<1024*1024*1024){
    ext="MB/s";
    realSpeed/=1024*1024;
  }else if(realSpeed>=1024*1024*1024){
    ext="GB/s";
    realSpeed/=1024*1024*1024;
  }
  return realSpeed.toStringAsFixed(2)+ext;
}
class NavigatorKey{
  static final key=GlobalKey<NavigatorState>();
}

enum FileState{
  init,
  downloading,
  paused,
  done
}

class FileDescriptor{
  String name;
  String downloadUrl;
  int rec=0;
  int size=1;
  int startTime=1;
  String url="";
  FileState state=FileState.init;
  FileDescriptor(this.name,this.downloadUrl,this.startTime);
  toJson(){
    return {
      "name":name,
      "downloadUrl":downloadUrl,
      "rec":rec,
      "size":size,
      "url":url,
    };
  }
  factory FileDescriptor.fromJson(Map<String,dynamic>json){
    var temp=FileDescriptor(json['name']!, json['downloadUrl']!, DateTime.now().millisecondsSinceEpoch);
    temp.size=json['size']!;
    temp.rec=json['rec']!;
    temp.url=json['url'];
    if(temp.rec<temp.size){
      temp.state=FileState.paused;
    }else{
      temp.state=FileState.done;
    }
    return temp;
  }
}


List<File> getFileFromXML(String xml){
  var transformer=Xml2Json();
  var files=<File>[];
  transformer.parse(xml);
  var json = jsonDecode(transformer.toParker());
  if(json['ListBucketResult']['CommonPrefixes']!=null){
    if(json['ListBucketResult']['CommonPrefixes'] is! List){
      var ele=json['ListBucketResult']['CommonPrefixes'];
      final filename=ele['Prefix'].replaceAll(RegExp(r"/$"),"").split('/');
      files.add(File(fileName: filename.last, fileID: ele['Prefix'], fileSize: "0", date: "0", fileType: 'folder', lastModifiedTime: DateTime.now()),);
    }else{
      json['ListBucketResult']['CommonPrefixes'].forEach((ele){
        final filename=ele['Prefix'].replaceAll(RegExp(r"/$"),"").split('/');
        files.add(File(fileName: filename.last, fileID: ele['Prefix'], fileSize: "0", date: "0", fileType: 'folder', lastModifiedTime: DateTime.now()),);
      });
    }
  }
  if(json['ListBucketResult']['Contents']!=null){
    if(json['ListBucketResult']['Contents'] is! List){
      var ele=json['ListBucketResult']['Contents'];
      print(ele);
      final filename=ele['Key'].replaceAll(RegExp(r"/$"),"").split('/');
      files.add(File(fileName: filename.last, fileID: ele['Key'], fileSize: ele['Size'], date: DateTime.parse(ele['LastModified']).millisecondsSinceEpoch.toString(), fileType: 'file', lastModifiedTime: DateTime.parse(ele['LastModified']),));
    }else{
      print(json['ListBucketResult']['Contents']);
      json['ListBucketResult']['Contents'].forEach((ele){
        if(ele['Key'].endsWith('/')){
          return;
        }
        final filename=ele['Key'].replaceAll(RegExp(r"/$"),"").split('/');
        files.add(File(fileName: filename.last, fileID: ele['Key'], fileSize: ele['Size'], date: DateTime.parse(ele['LastModified']).millisecondsSinceEpoch.toString(), fileType: 'file', lastModifiedTime: DateTime.parse(ele['LastModified']),));
      });
    }
  }
  return files;
}
const map64=['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q',
  'R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
  'w','x','y','z','+','='];
String dem2Hex(List<int> dem){
  const map=['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'];
  String res='';
  int cnt=0;
  for(var i in dem){
    int h0=i%16;
    int h1=i~/16;
    res+=map[h1]+map[h0];
  }
  return res;
}