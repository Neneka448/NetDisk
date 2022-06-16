import 'dart:convert';

import 'package:get/get.dart';
import 'GlobalClass.dart' show FileDescriptor, FileState, User;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
class Store extends GetxController{
  var chooseMode=false.obs;
  var nowDir=<String>[].obs;
  var loginState = false.obs;
  var token = ''.obs;
  var downloadList=<String,FileDescriptor>{}.obs;
  var uploadList=<String,FileDescriptor>{
  }.obs;
  var user=User(name: '', id: '', maxSpace: 1, usedSpace: 0,avatar: 'http://dummyimage.com/100x100',nickname:'').obs;
  changeLoginState(bool newState)=>loginState.value=newState;
  setUser(User _user)=>user.value=_user;
  saveToDisk()async{
    var doc=await getApplicationDocumentsDirectory();
    File downloadManifest=File(doc.path+'/netdisk.download.manifest');
    File uploadManifest=File(doc.path+'/netdisk.upload.manifest');
    var dmio=await downloadManifest.open(mode: FileMode.write);
    var umio=await uploadManifest.open(mode: FileMode.write);
    print(jsonEncode(uploadList.entries.toList().map((e){
      return [e.key,e.value.toJson()];
    }).toList()));
    await dmio.writeString(jsonEncode(downloadList.entries.toList().map((e){
          return [e.key,e.value.toJson()];
        }).toList()));
    await umio.writeString(jsonEncode(uploadList.entries.toList().map((e){
      return [e.key,e.value.toJson()];
    }).toList()));
  }
  loadFromDisk()async{
    var doc=await getApplicationDocumentsDirectory();
    File downloadManifest=File(doc.path+'/netdisk.download.manifest');
    File uploadManifest=File(doc.path+'/netdisk.upload.manifest');
    if(downloadManifest.existsSync()){
      var dmio=await downloadManifest.readAsString();
      var raw=jsonDecode(dmio) as List<dynamic>;
      var s=raw.map((e){
        return MapEntry<String,FileDescriptor>(e[0], FileDescriptor.fromJson(e[1]));
      });
      downloadList.value=Map.fromEntries(s);
      downloadList.forEach((key, value) {
        if(value.rec<value.size){
          value.state=FileState.paused;
        }else if(value.rec>=value.size){
          value.state=FileState.done;
        }
      });
    }
    if(uploadManifest.existsSync()){
      var umio=await uploadManifest.readAsString();
      var raw=jsonDecode(umio) as List<dynamic>;
      var s=raw.map((e){
        return MapEntry<String,FileDescriptor>(e[0], FileDescriptor.fromJson(e[1]));
      });
      uploadList.value=Map.fromEntries(s);
      uploadList.forEach((key, value) {
        if(value.rec<value.size){
          value.state=FileState.paused;
        }else if(value.rec>=value.size){
          value.state=FileState.done;
        }
      });
    }
  }
  clearManifest()async{
    var doc=await getApplicationDocumentsDirectory();
    File downloadManifest=File(doc.path+'/netdisk.download.manifest');
    File uploadManifest=File(doc.path+'/netdisk.upload.manifest');
    if(downloadManifest.existsSync()){
      downloadManifest.deleteSync();
    }
    if(uploadManifest.existsSync()){
      uploadManifest.deleteSync();
    }
  }
}