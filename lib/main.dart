import 'package:flutter/material.dart';
import 'package:mapapp/components/myColorTheme.dart';
import 'package:mapapp/pages/homePage.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'SNCF - MapApp',
    theme: ThemeData(
      colorScheme: ColorScheme(
        primary: MyColortheme.violet,
        secondary: MyColortheme.secondaryColor,
        surface: MyColortheme.surfaceColor,
        background: MyColortheme.backgroundColor,
        error: MyColortheme.errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: MyColortheme.coolGray11,
        onBackground: MyColortheme.coolGray9,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      brightness: Brightness.light,
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme(
        primary: MyColortheme.primaryColor,
        secondary: MyColortheme.secondaryColor,
        surface: MyColortheme.surfaceColor,
        background: MyColortheme.backgroundColor,
        error: MyColortheme.errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: MyColortheme.coolGray3,
        onBackground: MyColortheme.coolGray1,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      primaryColor: MyColortheme.primaryColor,
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    themeMode: ThemeMode.dark, // Changer en ThemeMode.light si nécessaire
    home: const Homepage(),
    debugShowCheckedModeBanner: false,
  );
}
}
