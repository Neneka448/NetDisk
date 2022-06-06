import 'package:get/get.dart';
import 'GlobalClass.dart' show User;
class Store extends GetxController{
  var loginState = false.obs;
  var token = ''.obs;
  var user=User(name: '', id: '', maxSpace: 1, usedSpace: 0).obs;
  changeLoginState(bool newState)=>loginState.value=newState;
  setUser(User _user)=>user.value=_user;
}