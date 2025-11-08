import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier{
  String user_id = '';

  String get userid => user_id;

  void setUserid(String id){
    user_id = id;
    notifyListeners();
  }
}