import 'package:flutter/material.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  bool isLogin = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [
        isLogin ? const UserPageHasLogin() : const UserPageNotLogin(),
      ],
    ));
  }
}

class UserPageNotLogin extends StatefulWidget {
  const UserPageNotLogin({Key? key}) : super(key: key);

  @override
  State<UserPageNotLogin> createState() => _UserPageNotLoginState();
}

class _UserPageNotLoginState extends State<UserPageNotLogin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _account='';
  String _psw='';
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(hintText: "Account"),
                onSaved: (v)=>_account=v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(hintText: "Password"),
                onSaved: (v)=>_psw=v??'',
              )
            ],
          ),
        ),
        ElevatedButton(
            onPressed: () {
              _formKey.currentState?.save();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("$_account,$_psw"),
              ));
            },
            child: const Text("校验"))
      ]),
    );
  }
}

class UserPageHasLogin extends StatefulWidget {
  const UserPageHasLogin({Key? key}) : super(key: key);

  @override
  State<UserPageHasLogin> createState() => _UserPageHasLoginState();
}

class _UserPageHasLoginState extends State<UserPageHasLogin> {
  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      children: [
        Container(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              child: Icon(Icons.people),
            ),
            Container(
                child: const Text("Diana", style: TextStyle(fontSize: 20)),
                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0)),
          ],
        )),
        Container(),
        Container()
      ],
    );
  }
}
