// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'asset_bundle.dart';
import 'message_codecs.dart';

// We use .bin as the extension since it is well-known to represent
// data in some arbitrary binary format.
const String _kAssetManifestFilename = 'AssetManifest.bin';

// We use the same bin file for the web, but re-encoded as JSON(base64(bytes))
// so it can be downloaded by even the dumbest of browsers.
// See https://github.com/flutter/flutter/issues/128456
const String _kAssetManifestWebFilename = 'AssetManifest.bin.json';

/// Contains details about available assets and their variants.
/// See [Resolution-aware image assets](https://docs.flutter.dev/ui/assets-and-images#resolution-aware)
/// to learn about asset variants and how to declare them.
abstract class AssetManifest {
  /// Loads asset manifest data from an [AssetBundle] object and creates an
  /// [AssetManifest] object from that data.
  static Future<AssetManifest> loadFromAssetBundle(AssetBundle bundle) {
    // The AssetManifest file contains binary data.
    //
    // On the web, the build process wraps this binary data in json+base64 so
    // it can be transmitted over the network without special configuration
    // (see #131382).
    if (kIsWeb) {
      // On the web, the AssetManifest is downloaded as a String, then
      // json+base64-decoded to get to the binary data.
      return bundle.loadStructuredData(_kAssetManifestWebFilename,
          (String jsonData) async {
        // Decode the manifest JSON file to the underlying BIN, and convert to ByteData.
        final ByteData message = ByteData.sublistView(
            base64.decode(json.decode(jsonData) as String));
        // Now we can keep operating as usual.
        return _AssetManifestBin.fromStandardMessageCodecMessage(message);
      });
    }
    // On every other platform, the binary file contents are used directly.
    return bundle.loadStructuredBinaryData(_kAssetManifestFilename,
        _AssetManifestBin.fromStandardMessageCodecMessage);
  }

  /// Lists the keys of all main assets. This does not include assets
  /// that are variants of other assets.
  ///
  /// The logical key maps to the path of an asset specified in the pubspec.yaml
  /// file at build time.
  ///
  /// See [Specifying assets](https://docs.flutter.dev/development/ui/assets-and-images#specifying-assets)
  /// and [Loading assets](https://docs.flutter.dev/development/ui/assets-and-images#loading-assets)
  /// for more information.
  List<String> listAssets();

  /// Retrieves metadata about an asset and its variants. Returns null if the
  /// key was not found in the asset manifest.
  ///
  /// This method considers a main asset to be a variant of itself. The returned
  /// list will include it if it exists.
  List<AssetMetadata>? getAssetVariants(String key);
}

// Lazily parses the binary asset manifest into a data structure that's easier to work
// with.
//
// The binary asset manifest is a map of asset keys to a list of objects
// representing the asset's variants.
//
// The entries with each variant object are:
//  - "asset": the location of this variant to load it from.
//  - "dpr": The device-pixel-ratio that the asset is best-suited for.
//
// New fields could be added to this object schema to support new asset variation
// features, such as themes, locale/region support, reading directions, and so on.
class _AssetManifestBin implements AssetManifest {
  _AssetManifestBin(Map<Object?, Object?> standardMessageData)
      : _data = standardMessageData;

  factory _AssetManifestBin.fromStandardMessageCodecMessage(ByteData message) {
    final dynamic data = const StandardMessageCodec().decodeMessage(message);
    return _AssetManifestBin(data as Map<Object?, Object?>);
  }

  final Map<Object?, Object?> _data;
  final Map<String, List<AssetMetadata>> _typeCastedData =
      <String, List<AssetMetadata>>{};

  @override
  List<AssetMetadata>? getAssetVariants(String key) {
    // We lazily delay typecasting to prevent a performance hiccup when parsing
    // large asset manifests. This is important to keep an app's first asset
    // load fast.
    if (!_typeCastedData.containsKey(key)) {
      final Object? variantData = _data[key];
      if (variantData == null) {
        return null;
      }
      _typeCastedData[key] = ((_data[key] ?? <Object?>[]) as Iterable<Object?>)
          .cast<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> data) {
        final String asset = data['asset']! as String;
        final Object? dpr = data['dpr'];
        return AssetMetadata(
          key: data['asset']! as String,
          targetDevicePixelRatio: dpr as double?,
          main: key == asset,
        );
      }).toList();

      _data.remove(key);
    }

    return _typeCastedData[key]!;
  }

  @override
  List<String> listAssets() {
    return <String>[..._data.keys.cast<String>(), ..._typeCastedData.keys];
  }
}

/// Contains information about an asset.
@immutable
class AssetMetadata {
  /// Creates an object containing information about an asset.
  const AssetMetadata({
    required this.key,
    required this.targetDevicePixelRatio,
    required this.main,
  });

  /// The device pixel ratio that this asset is most ideal for. This is determined
  /// by the name of the parent folder of the asset file. For example, if the
  /// parent folder is named "3.0x", the target device pixel ratio of that
  /// asset will be interpreted as 3.
  ///
  /// This will be null if the parent folder name is not a ratio value followed
  /// by an "x".
  ///
  /// See [Resolution-aware image assets](https://docs.flutter.dev/development/ui/assets-and-images#resolution-aware)
  /// for more information.
  final double? targetDevicePixelRatio;

  /// The asset's key, which is the path to the asset specified in the pubspec.yaml
  /// file at build time.
  final String key;

  /// Whether or not this is a main asset. In other words, this is true if
  /// this asset is not a variant of another asset.
  final bool main;
}


// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter/cupertino.dart';
// // import 'package:provider/provider.dart';

// import 'home.dart';
// import 'tracker.dart';
// import 'setting.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   int data = 0;
//   int _selectedPage = 0;
//   late List<Widget> _pageOptions;
//   // var _pageOptions = [
//   //   Home(
//   //     data: 000,
//   //   ),
//   //   Tracker(
//   //     data: 002,
//   //   ),
//   //   Settings(
//   //     data: 003,
//   //   ),
//   // ];

//   final String formattedDate = DateFormat.yMMMMEEEEd().format(DateTime.now());

//   @override
//   void initState() {
//     super.initState();
//     _pageOptions = [
//       Home(data: data),
//       Tracker(data: data),
//       Settings(data: data),
//     ];
//   }

//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text(formattedDate),
//           actions: const [
//             Padding(
//               padding: EdgeInsets.only(right: 20.0),
//               child: Icon(
//                 CupertinoIcons.bell,
//                 color: Color.fromARGB(255, 0, 0, 0),
//                 size: 30,
//               ),
//             ),
//           ],
//         ),
//         body: _pageOptions[_selectedPage],
//         bottomNavigationBar: BottomNavigationBar(
//           currentIndex: _selectedPage,
//           onTap: (int index) {
//             setState(() {
//               _selectedPage = index;
//               data = index;
//             });
//           },
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//             BottomNavigationBarItem(
//                 icon: Icon(Icons.schedule), label: 'Tracker'),
//             BottomNavigationBarItem(
//                 icon: Icon(Icons.settings), label: 'Settings'),
//           ],
//           iconSize: 36,
//         ),
//       ),
//     );
//   }
// }

// // import 'dart:ffi';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:footer/footer.dart';




// // class _MyAppState extends State<MyApp> {

// //   @override
// //   Widget build(BuildContext context) {
// //     double baseWidth = 380;
// //     double fem = MediaQuery.of(context).size.width / baseWidth;
// //     double ffem = fem * 0.97;
// //     return MaterialApp(
// //       home: Scaffold(
// //         body: Container(
// //           decoration: const BoxDecoration(
// //             image: DecorationImage(
// //               image: AssetImage('image/Bwma.jpg'),
// //               fit: BoxFit.cover,
// //             ),
// //           ),

// //           child: Stack(
// //             children: [
// //               Container(
// //                 // homeHnV (3:14)
// //                 width:  430*fem,
// //                 height:  932*fem,
// //                 decoration:  BoxDecoration (
// //                   color:  const Color(0xfff6f6f6),
// //                   borderRadius:  BorderRadius.circular(40*fem),
// //                 ),
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // statusbariosc45 (10:1264)
// //                 padding:  EdgeInsets.fromLTRB(35*fem, 29*fem, 25.01*fem, 29*fem),
// //                 width:  double.infinity,
// //                 height:  78*fem,
// //                 decoration:  const BoxDecoration (
// //                   color:  Color(0xfff6f6f6),
// //                 ),
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // timev4m (33:126)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 255*fem, 0*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // clock3QH (33:127)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 6*fem, 0*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Text(
// //                 // hoursyYq (33:128)
// //                 '9',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //               SizedBox(
// //                 // autogroupbvjmvU5 (7sY9g5QZqxLi3UG5S7bvjm)
// //                 width:  17*fem,
// //                 height:  double.infinity,
// //                 child:
// //               Stack(
// //                 children:  [
// //               Positioned(
// //                 // UEh (33:129)
// //                 left:  0*fem,
// //                 top:  0*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  4*fem,
// //                 height:  20*fem,
// //                 child:
// //               Text(
// //                 ':',
// //                 style: GoogleFonts.dmSans (
// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // minutesnFP (33:130)
// //                 left:  3*fem,
// //                 top:  0*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  14*fem,
// //                 height:  20*fem,
// //                 child:
// //               Text(
// //                 '41',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // locationarrowsnd (33:131)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 0*fem),
// //                 width:  11.99*fem,
// //                 height:  11.99*fem,
// //                 child:
// //               Image.asset(
// //                 'assets/jitter-animation/images/wifi.png',
// //                 width:  11.99*fem,
// //                 height:  11.99*fem,
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // iconsyKs (10:1266)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 4*fem, 0*fem, 4*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // cellularsignalVp1 (10:1267)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 6*fem, 0*fem),
// //                 width:  18*fem,
// //                 height:  10*fem,
// //                 child:
// //               Image.asset(
// //                 '',
// //                 width:  18*fem,
// //                 height:  10*fem,
// //               ),
// //               ),
// //               Container(
// //                 // wifibs3 (10:1268)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 6*fem, 0*fem),
// //                 width:  16*fem,
// //                 height:  11.62*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  16*fem,
// //                 height:  11.62*fem,
// //               ),
// //               ),
// //               SizedBox(
// //                 // batteryWUD (10:1269)
// //                 width:  24*fem,
// //                 height:  12*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  24*fem,
// //                 height:  12*fem,
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // headerqWV (33:621)
// //                 margin:  EdgeInsets.fromLTRB(27*fem, 0*fem, 27*fem, 20*fem),
// //                 padding:  EdgeInsets.fromLTRB(0*fem, 0.5*fem, 3.75*fem, 0.5*fem),
// //                 width:  double.infinity,
// //                 height:  30*fem,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // date9GH (I33:621;33:607)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 61.75*fem, 0*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // saturdayGrh (I33:621;33:608)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 12*fem, 0*fem),
// //                 child:
// //               Text(
// //                 'Saturday',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  22*ffem,
// //                   fontWeight:  FontWeight.w700,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // february4th2023PwK (I33:621;33:609)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 1*fem, 0*fem, 0*fem),
// //                 child:
// //               Text(
// //                 'February 4th, 2023',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // belluuf (I33:621;33:610)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 0*fem),
// //                 width:  22.5*fem,
// //                 height:  25*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  22.5*fem,
// //                 height:  25*fem,
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // minicalendardam (28:136)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 20*fem),
// //                 width:  double.infinity,
// //                 height:  46*fem,
// //                 decoration:  const BoxDecoration (
// //                   color:  Color(0xfff6f6f6),
// //                 ),
// //                 child:
// //               Container(
// //                 // scrollmgy (18:180)
// //                 padding:  EdgeInsets.fromLTRB(8*fem, 5*fem, 0*fem, 5*fem),
// //                 width:  1182*fem,
// //                 height:  double.infinity,
// //                 decoration:  const BoxDecoration (
// //                   color:  Color(0xff3a276a),
// //                 ),
// //                 child:
// //               SizedBox(
// //                 // scrollJgu (18:181)
// //                 width:  double.infinity,
// //                 height:  double.infinity,
// //                 child:
// //               Stack(
// //                 children:  [
// //               Positioned(
// //                 // periodfGZ (18:182)
// //                 left:  711*fem,
// //                 top:  3*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  214*fem,
// //                 height:  30*fem,
// //                 child:
// //               Container(
// //                 decoration:  BoxDecoration (
// //                   borderRadius:  BorderRadius.circular(20*fem),
// //                   color:  const Color(0xffc8f0f0),
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // prevperiodpof (18:183)
// //                 left:  0*fem,
// //                 top:  3*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  89*fem,
// //                 height:  30*fem,
// //                 child:
// //               Container(
// //                 decoration:  BoxDecoration (
// //                   borderRadius:  BorderRadius.circular(20*fem),
// //                   color:  const Color(0xffc8f0f0),
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // date8ZT (18:184)
// //                 left:  139*fem,
// //                 top:  0*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  36*fem,
// //                 height:  36*fem,
// //                 child:
// //               Container(
// //                 decoration:  BoxDecoration (
// //                   borderRadius:  BorderRadius.circular(18*fem),
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // numberse21 (18:185)
// //                 left:  12*fem,
// //                 top:  5*fem,
// //                 child:
// //               SizedBox(
// //                 width:  1162*fem,
// //                 height:  27*fem,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // 6ub (18:186)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '01',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // pah (18:187)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 21*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '02',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // 97B (18:188)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '03',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // GSh (18:189)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '04',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // oSd (18:190)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 21*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '05',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // vn9 (18:191)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '06',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // TXB (18:192)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '07',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // zGD (18:193)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 21*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '08',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // v9s (18:194)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '09',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // FT3 (18:195)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '10',
// //                 style:  GoogleFonts.dmSans (
// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // ydw (18:196)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '11',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // 6yT (18:197)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '12',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // qg9 (18:198)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 19*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '13',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // NAH (21:241)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '14',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // tuK (18:199)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '15',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // 2Eq (18:200)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '16',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // x8V (18:201)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '17',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // gKP (18:202)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '18',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // cD3 (18:203)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '19',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // jHf (18:204)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 21*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '20',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // G2h (18:205)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '21',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // zjP (18:206)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 19*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '22',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // vsw (18:207)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '23',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // GB7 (18:208)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '24',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // bDP (18:209)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '25',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // KfB (18:210)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '26',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Container(
// //                 // eSZ (18:211)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 20*fem, 0*fem),
// //                 child:
// //               Text(
// //                 '27',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //               ),
// //               Text(
// //                 // BBb (18:212)
// //                 '28',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xffffffff),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               ),
// //               ),
// //               Container(
// //                 // colorcodesjD7 (28:134)
// //                 margin:  EdgeInsets.fromLTRB(81*fem, 0*fem, 82*fem, 32*fem),
// //                 width:  double.infinity,
// //                 height:  20*fem,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // currentdatecolorcodeFx9 (21:237)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 23*fem, 0*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // dot1nx5 (21:234)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 10*fem, 0*fem),
// //                 width:  11*fem,
// //                 height:  14.98*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  11*fem,
// //                 height:  14.98*fem,
// //               ),
// //               ),
// //               Text(
// //                 // currentdateumo (21:236)
// //                 'Current Date',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w500,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               SizedBox(
// //                 // periodcolorcodesfFB (21:238)
// //                 height:  double.infinity,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // dot11Zw (44:204)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 10*fem, 0*fem),
// //                 width:  11*fem,
// //                 height:  14.98*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  11*fem,
// //                 height:  14.98*fem,
// //               ),
// //               ),
// //               Text(
// //                 // perioddurationjF3 (21:235)
// //                 'Period Duration',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w500,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // tabslist5Ju (21:224)
// //                 padding:  EdgeInsets.fromLTRB(30*fem, 8*fem, 30*fem, 0*fem),
// //                 width:  double.infinity,
// //                 height:  560*fem,
// //                 child:
// //               SizedBox(
// //                 // listCPX (21:239)
// //                 width:  double.infinity,
// //                 height:  680*fem,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // tabonejPT (21:149)
// //                 padding:  EdgeInsets.fromLTRB(25*fem, 15*fem, 45*fem, 14*fem),
// //                 width:  double.infinity,
// //                 height:  120*fem,
// //                 decoration: BoxDecoration(
// //                 border: Border.all(
// //                   color: const Color(0xff000000),
// //                 ),
// //                 color: const Color(0xfffafafa),
// //                 borderRadius: BorderRadius.circular(20*fem),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: const Color(0x30000000),
// //                     offset: Offset(0*fem, 2*fem),
// //                     blurRadius: 4.5*fem,
// //                   ),
// //                 ],
// //                 ),
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // text1Pyo (28:139)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 41*fem, 0*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.start,
// //                 children:  [
// //               Container(
// //                 // title1j25 (21:126)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 25*fem),
// //                 width:  211*fem,
// //                 height:  46*fem,
// //                 decoration:  BoxDecoration (
// //                   borderRadius:  BorderRadius.circular(10*fem),
// //                 ),
// //                 child:
// //               Stack(
// //                 children:  [
// //               Positioned(
// //                 // thfebruaryEzR (21:127)
// //                 left:  0*fem,
// //                 top:  26*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  90*fem,
// //                 height:  20*fem,
// //                 child:
// //               Text(
// //                 '4th February',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // top8a1 (21:140)
// //                 left:  0*fem,
// //                 top:  0*fem,
// //                 child:
// //               Container(
// //                 width:  211*fem,
// //                 height:  27*fem,
// //                 decoration:  BoxDecoration (
// //                   borderRadius:  BorderRadius.circular(10*fem),
// //                 ),
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Text(
// //                 // nowSqb (21:135)
// //                 'Now',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //               SizedBox(
// //                 width:  8*fem,
// //               ),
// //               Container(
// //                 // arrowrightNz9 (21:136)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 3*fem, 0*fem, 0*fem),
// //                 width:  10*fem,
// //                 height:  10*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  10*fem,
// //                 height:  10*fem,
// //               ),
// //               ),
// //               SizedBox(
// //                 width:  8*fem,
// //               ),
// //               Text(
// //                 // follicularphaseHLR (21:128)
// //                 'Follicular phase',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Text(
// //                 // note12J1 (21:129)
// //                 'Tap to see next period start date',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // notification1mWV (21:148)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 22*fem, 0*fem, 9*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // vectoru6u (21:146)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 8*fem),
// //                 width:  27.43*fem,
// //                 height:  32*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  27.43*fem,
// //                 height:  32*fem,
// //               ),
// //               ),
// //               Text(
// //                 // nowpUm (21:147)
// //                 'Now',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff86d8dc),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               SizedBox(
// //                 height:  20*fem,
// //               ),
// //               Container(
// //                 // tabtwoMDo (18:235)
// //                 padding:  EdgeInsets.fromLTRB(25*fem, 15*fem, 22*fem, 14*fem),
// //                 width:  double.infinity,
// //                 height:  120*fem,
// //                 decoration: BoxDecoration(
// //                 border: Border.all(
// //                   color: const Color(0xff000000),
// //                 ),
// //                 color: const Color(0xfffafafa),
// //                 borderRadius: BorderRadius.circular(20*fem),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: const Color(0x30000000),
// //                     offset: Offset(0*fem, 2*fem),
// //                     blurRadius: 4.5*fem,
// //                   ),
// //                 ],
// //                 ),
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // text2pt5 (28:140)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 43*fem, 0*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.start,
// //                 children:  [
// //               Container(
// //                 // title3mHX (18:233)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 25*fem),
// //                 width:  109*fem,
// //                 height:  46*fem,
// //                 child:
// //               Stack(
// //                 children:  [
// //               Positioned(
// //                 // nextperiodHmf (18:221)
// //                 left:  0*fem,
// //                 top:  0*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  109*fem,
// //                 height:  27*fem,
// //                 child:
// //               Text(
// //                 'Next period',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // thfebruaryCNq (18:222)
// //                 left:  0*fem,
// //                 top:  26*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  95*fem,
// //                 height:  20*fem,
// //                 child:
// //               Text(
// //                 '19th February',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Text(
// //                 // note3Jwf (18:229)
// //                 'Your last period lasted 5 days',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // notification3fXK (18:234)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 12*fem, 0*fem, 13*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // icon1LH (18:228)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 6*fem),
// //                 width:  40*fem,
// //                 height:  40*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  40*fem,
// //                 height:  40*fem,
// //               ),
// //               ),
// //               Text(
// //                 // in3weeksKbs (18:224)
// //                 'In 3 Weeks',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff86d8dc),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               SizedBox(
// //                 height:  20*fem,
// //               ),
// //               Container(
// //                 // tabthreerLu (21:123)
// //                 padding:  EdgeInsets.fromLTRB(25*fem, 15*fem, 28*fem, 14*fem),
// //                 width:  double.infinity,
// //                 height:  120*fem,
// //                 decoration: BoxDecoration(
// //                   border: Border.all(
// //                     color: const Color(0xff000000),
// //                   ),
// //                   color: const Color(0xfffafafa),
// //                   borderRadius: BorderRadius.circular(20*fem),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: const Color(0x30000000),
// //                       offset: Offset(0*fem, 2*fem),
// //                       blurRadius: 4.5*fem,
// //                     ),
// //                   ],
// //                   ),
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // text3XT3 (28:141)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 68*fem, 0*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.start,
// //                 children:  [
// //               Container(
// //                 // title23wB (21:122)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 25*fem),
// //                 width:  141*fem,
// //                 height:  46*fem,
// //                 child:
// //               Stack(
// //                 children:  [
// //               Positioned(
// //                 // thfebruaryaRK (21:108)
// //                 left:  0*fem,
// //                 top:  26*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  95*fem,
// //                 height:  20*fem,
// //                 child:
// //               Text(
// //                 '14th February',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // valentinesday68m (21:107)
// //                 left:  0*fem,
// //                 top:  0*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  141*fem,
// //                 height:  27*fem,
// //                 child:
// //               Text(
// //                 'Valentine’s Day',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Text(
// //                 // note2yiM (21:109)
// //                 'Tap to view your Calendar',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // notification2vdb (21:121)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 18*fem, 0*fem, 9.84*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // icon2GBf (21:120)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 6*fem),
// //                 width:  42.04*fem,
// //                 height:  37.16*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  42.04*fem,
// //                 height:  37.16*fem,
// //               ),
// //               ),
// //               Text(
// //                 // in10daysNVb (21:119)
// //                 'In 10 Days',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff86d8dc),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               SizedBox(
// //                 height:  20*fem,
// //               ),
// //               Container(
// //                 // tabfouruEd (21:189)
// //                 padding:  EdgeInsets.fromLTRB(25*fem, 14*fem, 27*fem, 14*fem),
// //                 width:  double.infinity,
// //                 height:  120*fem,
// //                 decoration: BoxDecoration(
// //                   border: Border.all(
// //                     color: const Color(0xff000000),
// //                   ),
// //                   color: const Color(0xfffafafa),
// //                   borderRadius: BorderRadius.circular(20*fem),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: const Color(0x30000000),
// //                       offset: Offset(0*fem, 2*fem),
// //                       blurRadius: 4.5*fem,
// //                     ),
// //                   ],
// //                   ),
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // text4ART (28:142)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 47*fem, 0*fem),
// //                 height:  double.infinity,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.start,
// //                 children:  [
// //               Container(
// //                 // title6pu (21:192)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 10*fem),
// //                 width:  121*fem,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.start,
// //                 children:  [
// //               SizedBox(
// //                 // autogroupvwb13EM (7sY8gGjYuVNxGxEekVvwb1)
// //                 width:  double.infinity,
// //                 height:  46*fem,
// //                 child:
// //               Stack(
// //                 children:  [
// //               Positioned(
// //                 // pedometerCN9 (21:193)
// //                 left:  0*fem,
// //                 top:  0*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  102*fem,
// //                 height:  27*fem,
// //                 child:
// //               Text(
// //                 'Pedometer',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // stepstodayhJu (21:194)
// //                 left:  0*fem,
// //                 top:  26*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  121*fem,
// //                 height:  20*fem,
// //                 child:
// //               Text(
// //                 '3,213 steps today',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Text(
// //                 // kmnLM (21:218)
// //                 '1.2 km',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  12*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Text(
// //                 // note4jWV (21:191)
// //                 'Synced to Google Fit',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Container(
// //                 // notification4Uys (21:195)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 3*fem, 0*fem, 0*fem),
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.end,
// //                 children:  [
// //               Container(
// //                 // vectorpnq (21:223)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 0*fem),
// //                 width:  42*fem,
// //                 height:  49*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  42*fem,
// //                 height:  49*fem,
// //               ),
// //               ),
// //               Container(
// //                 // youhavealmostreachedyourgoalMG (21:208)
// //                 constraints:  BoxConstraints (
// //                   maxWidth:  125*fem,
// //                 ),
// //                 child:
// //               Text(
// //                 'You have almost reached your goal',
// //                 textAlign:  TextAlign.right,
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                 ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               SizedBox(
// //                 height:  20*fem,
// //               ),
// //               Container(
// //                 // tabfiveqhw (21:154)
// //                 width:  double.infinity,
// //                 height:  120*fem,
// //                 decoration: BoxDecoration(
// //                   border: Border.all(
// //                     color: const Color(0xff000000),
// //                   ),
// //                   color: const Color(0xfffafafa),
// //                   borderRadius: BorderRadius.circular(20*fem),
// //                   boxShadow: [
// //                     BoxShadow(
// //                       color: const Color(0x30000000),
// //                       offset: Offset(0*fem, 2*fem),
// //                       blurRadius: 4.5*fem,
// //                     ),
// //                   ],
// //                   ),
// //                 child:
// //               Stack(
// //                 children:  [
// //               Positioned(
// //                 // text5Lub (28:143)
// //                 left:  25*fem,
// //                 top:  15*fem,
// //                 child:
// //               SizedBox(
// //                 width:  304*fem,
// //                 height:  91*fem,
// //                 child:
// //               Column(
// //                 crossAxisAlignment:  CrossAxisAlignment.start,
// //                 children:  [
// //               Container(
// //                 // titleGHT (21:150)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 0*fem, 25*fem),
// //                 width:  199*fem,
// //                 height:  46*fem,
// //                 child:
// //               Stack(
// //                 children:  [
// //               Positioned(
// //                 // symptomsandmoodQ8m (21:151)
// //                 left:  0*fem,
// //                 top:  0*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  199*fem,
// //                 height:  27*fem,
// //                 child:
// //               Text(
// //                 'Symptoms and Mood',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  20*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff000000),
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // tellmehowyoufeeltpd (21:152)
// //                 left:  0*fem,
// //                 top:  26*fem,
// //                 child:
// //               Align(
// //                 child:
// //               SizedBox(
// //                 width:  140*fem,
// //                 height:  20*fem,
// //                 child:
// //               Text(
// //                 'Tell me how you feel',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                 ),
// //               ),
// //               ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               Text(
// //                 // note5CKX (21:153)
// //                 'You can also record any unusual symptoms ',
// //                 style:  GoogleFonts.dmSans (

// //                   fontSize:  15*ffem,
// //                   fontWeight:  FontWeight.w400,
// //                   height:  1.3025*ffem/fem,
// //                   color:  const Color(0xff3a276a),
// //                 ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               ),
// //               Positioned(
// //                 // notification5MCR (21:169)
// //                 left:  283*fem,
// //                 top:  45*fem,
// //                 child:
// //               Container(
// //                 padding:  EdgeInsets.fromLTRB(0*fem, 0*fem, 2.5*fem, 0*fem),
// //                 width:  60*fem,
// //                 height:  30*fem,
// //                 child:
// //               Row(
// //                 crossAxisAlignment:  CrossAxisAlignment.center,
// //                 children:  [
// //               Container(
// //                 // smileFob (21:155)
// //                 margin:  EdgeInsets.fromLTRB(0*fem, 0*fem, 2.5*fem, 0*fem),
// //                 width:  30*fem,
// //                 height:  30*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  30*fem,
// //                 height:  30*fem,
// //               ),
// //               ),
// //               SizedBox(
// //                 // frownn2q (21:160)
// //                 width:  25*fem,
// //                 height:  25*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  25*fem,
// //                 height:  25*fem,
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //               ),
// //               SizedBox(
// //                 // navWjX (33:506)
// //                 width:  430*fem,
// //                 height:  126*fem,
// //                 child:
// //               Image.asset(
// //                 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@24,400,0,0',
// //                 width:  430*fem,
// //                 height:  126*fem,
// //               ),
// //               ),
// //                 ],
// //               ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
