// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: CounterScreen(),
//     );
//   }
// }

// class CounterScreen extends StatefulWidget {
//   const CounterScreen({super.key});

//   @override
//   _CounterScreenState createState() => _CounterScreenState();
// }

// class _CounterScreenState extends State<CounterScreen> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   void _decrementCounter() {
//     setState(() {
//       _counter--;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     Color backgroundColor;
//     if (_counter >= 30) {
//       backgroundColor = Colors.red;
//     } else if (_counter >= 20) {
//       backgroundColor = Colors.orange;
//     } else if (_counter >= 10) {
//       backgroundColor = Colors.yellow;
//     } else {
//       backgroundColor = Colors.purple;
//     }

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         title: const Text('64160168'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             AnimatedOpacity(
//               opacity: _counter != 0 ? 1.0 : 0.0,
//               duration: Duration(milliseconds: 500),
//               child: Text(
//                 '$_counter',
//                 style: const TextStyle(
//                   fontSize: 48.0,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             SizedBox(height: 20.0),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 FloatingActionButton(
//                   onPressed: _decrementCounter,
//                   backgroundColor: Colors.blue,
//                   child: const Icon(Icons.remove),
//                 ),
//                 SizedBox(width: 20.0),
//                 FloatingActionButton(
//                   onPressed: _incrementCounter,
//                   backgroundColor: backgroundColor,
//                   child: const Icon(Icons.add),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
