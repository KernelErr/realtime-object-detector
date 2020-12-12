import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:realtimeod/object_detector.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  await WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  await _loadModel();
  runApp(ObjectDetectApp());
}

Future<Null> _loadModel() async {
  try {
    const platform = const MethodChannel('paddlelite');
    final String result = await platform.invokeMethod('loadModel');
    print(result);
  } on PlatformException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
}

class ObjectDetectApp extends StatefulWidget {
  @override
  _ObjectDetectAppState createState() => new _ObjectDetectAppState();
}

class _ObjectDetectAppState extends State<ObjectDetectApp>
    with WidgetsBindingObserver {
  final ObjectDetector detector = ObjectDetector.instance;
  CameraController controller;
  GlobalKey _keyCameraPreview = GlobalKey();
  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      detector.addListener(() {
        setState(() {});
      });
      detector.init(controller);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    controller?.dispose();
    detector.dispose();
    super.dispose();
  }

  @override
  void dispose() {
    controller?.dispose();
    detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        theme: ThemeData(primarySwatch: Colors.blueGrey),
        home: Scaffold(
            appBar: AppBar(
                title: Center(
                  child: Text('Object Detector'),
                )),
            body: new Center(
              child: Column(children: [
                _cameraPreviewWidget(detector.value),
              ]),
            )));
  }

  Widget _cameraPreviewWidget(List value) {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Loading Camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {

      return new Stack(alignment: FractionalOffset.center, children: <Widget>[
        new AspectRatio(
            key: _keyCameraPreview,
            aspectRatio: controller.value.aspectRatio,
            child: new CameraPreview(controller)),
        new Positioned.fill(
            child: new CustomPaint(
              painter: new DrawObjects(value, _keyCameraPreview),
            )),
      ]);
    }

  }
}

class DrawObjects extends CustomPainter {
  List values;
  GlobalKey<State<StatefulWidget>> keyCameraPreview;
  DrawObjects(this.values, this.keyCameraPreview);

  @override
  void paint(Canvas canvas, Size size) {
    print(values);
    if (values==null && values.isNotEmpty && values[0] == null) return;
    final RenderBox renderPreview =
    keyCameraPreview.currentContext.findRenderObject();
    final sizeRed = renderPreview.size;

    var ratioW = sizeRed.width / 608;
    var ratioH = sizeRed.height / 608;
    for (var value in values) {
      var index = value[0];
      Paint paint = new Paint();
      paint.color = Colors.red;
      paint.strokeWidth = 2;
      double x1 = value[2] * ratioW,
          x2 = value[4] * ratioW,
          y1 = value[3] * ratioH,
          y2 = value[5] * ratioH;
      TextSpan span = new TextSpan(
          style: new TextStyle(
              color: Colors.black,
              background: paint,
              fontWeight: FontWeight.bold,
              fontSize: 14),
          text: " " + value[1] + " " + (double.parse(value[6])*100).toStringAsFixed(2) +" % ");
      TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.left,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, new Offset(x1 + 1, y1 + 1));
      canvas.drawLine(new Offset(x1, y1), new Offset(x2, y1), paint);
      canvas.drawLine(new Offset(x1, y1), new Offset(x1, y2), paint);
      canvas.drawLine(new Offset(x1, y2), new Offset(x2, y2), paint);
      canvas.drawLine(new Offset(x2, y1), new Offset(x2, y2), paint);
    }

  }

  @override
  bool shouldRepaint(DrawObjects oldDelegate) {
    return true;
  }
}