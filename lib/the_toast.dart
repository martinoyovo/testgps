
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

theToast(String text, BuildContext context) {
  return Toast.show(
      text,
      context,
      gravity: Toast.BOTTOM,
      backgroundColor: Colors.black,
      duration: Toast.LENGTH_LONG,
      backgroundRadius: 5);
}