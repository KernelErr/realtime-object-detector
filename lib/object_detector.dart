import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class ObjectDetector extends ValueNotifier<List> {
  ObjectDetector._() : super(null);

  static CameraController _controller;

  static bool _isDetecting = false;
  static const platform = const MethodChannel('inf.link/paddlelite');

  static final ObjectDetector instance = ObjectDetector._();
  void init(CameraController controller) async {
    _controller = controller;
    _controller.initialize().then((_) {
      _controller.startImageStream((CameraImage image) {
        if (!_isDetecting) {
          _isDetecting = true;
          _runDetection(image);
        }
      });
    });
  }

  void _runDetection(CameraImage image) async {
    try {
      var inputImage = new Map();
      inputImage["planes"] = new List(image.planes.length);
      for (int i = 0; i < image.planes.length; i++) {
        var value = {};
        value["bytes"] = image.planes[i].bytes;
        value["bytesPerRow"] = image.planes[i].bytesPerRow;
        value["bytesPerPixel"] = image.planes[i].bytesPerPixel;
        value["height"] = image.planes[i].height;
        value["width"] = image.planes[i].width;
        inputImage["planes"][i] = value;
      }
      inputImage["height"] = image.height;
      inputImage["width"] = image.width;
      inputImage["rotation"] = 90;

      print("Run model.");
      var results = await platform.invokeMethod(
        'detectObject',
        inputImage,
      );
      value = results;

    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    suspend();
  }

  void suspend() {
    _controller?.dispose();
    _controller = null;
    value = null;
  }
}
