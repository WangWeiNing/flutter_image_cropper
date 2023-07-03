import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_cropper/src/controller.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as image_lib;
import 'package:path_provider/path_provider.dart';

import 'src/cropper.dart';
import 'src/converter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String imagePath = "";
  late Future _future;
  ui.Image? _resultImage;

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {


    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _build(context)
          ],
        ),
      ),
    );
  }

  Widget _build(BuildContext context) {
    if(_resultImage != null){
      return Container(
        width: 400,
        height: 600,
        child: RawImage(
          image: _resultImage,
          width: 564,
          height: 875,
        ),
      );
    }

    _future = _loadImageFromAsset("assets/raw.jpg");
    return FutureBuilder(
      future: _future,
      builder:(context, snapshot) {

        if(snapshot.hasError){
          return Text(snapshot.error.toString());
        }

        if(!snapshot.hasData){
          return const Text("Loading image");
        }
        var controller = CropperController();
        var myCropper = ImageCropper(
            image: snapshot.data!,
            controller: controller,
            viewSize: const Size(392.7, 500),
            aspectRatio: 768 / 1024,
            onCropped: (image_lib.Image image) async {
              var uiImage = await ImageConverter.imageToUiImage(image);
              saveImage(image);
              setState(()=>_resultImage = uiImage
              );
            },
          );
        return Container(
          width: 400,
          height: 600,
          color: Colors.red,
          child: Column(
            children: [
              SizedBox(width: 400, height: 500, child: myCropper,),
              ElevatedButton(onPressed: () => controller.crop(), child: const Text("Crop"))
            ],
          ),
        );

      },
    );
  }

  Future saveImage(image_lib.Image image) async {
    await ImageConverter.imageToFile("C://D/result.png", image);
  }
  

  Future<String> getFilePath(String assetPath) async {
    //
    var byteData = await rootBundle.load(assetPath);
    var directory = await getApplicationDocumentsDirectory();
    var tempPath = "${directory.path}/$assetPath";
    var file = File(tempPath)..create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List(),
        mode: FileMode.write, flush: true);
    return tempPath;
  }

  Future<Uint8List> getFileData(String assetPath) async {
    var byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }

  Future<ui.Image> _loadImageFromAsset(String assetPath) async {
    var buffer = await getFileData(assetPath);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(buffer, completer.complete);
    return completer.future;
  }
}
