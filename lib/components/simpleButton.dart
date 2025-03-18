import 'package:flutter/material.dart';
import 'package:mapapp/components/myColorTheme.dart';

class SimpleButton extends StatelessWidget {
  final String text;
  final Icon icon;
  final VoidCallback onPressed;

  const SimpleButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: MyColortheme.backgroundColor,
        foregroundColor: MyColortheme.primaryColor,
      ),
      icon: icon,
      onPressed: onPressed,
      label: Text(text, style: TextStyle(color: Colors.white),),
    );
  }
}
