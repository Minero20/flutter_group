import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  int data;

  Settings({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        padding: EdgeInsets.all(65),
        color: Colors.red,
        child: Center(
          child: Text(
            '${data}',
            style: TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}
