import 'dart:js';

import 'package:administration_tool/screens/authorization.dart';
import 'package:administration_tool/screens/chapter.dart';
import 'package:administration_tool/screens/character.dart';
import 'package:administration_tool/screens/main_page.dart';
import 'package:administration_tool/screens/registration.dart';
import 'package:administration_tool/screens/tree.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/register',
    routes: {
      '/register': (context) => const RegistrationPage(),
      '/login': (context) => const LoginPage(),
      // '/chapter': (context) => const ChapterScreen(
      //   chapterTitle: 'Глава 1', // передайте нужное название главы
      // ),
    },
  ));
}

