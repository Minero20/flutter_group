import 'package:flutter/material.dart';

class Tracker extends StatelessWidget {
  int data;

  Tracker({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        padding: EdgeInsets.all(65),
        child: Center(
          child: Text(
            '${data}',
            style: TextStyle(fontSize: 28),
          ),
        ),
        color: Colors.blue,
      ),
    );
  }
}
