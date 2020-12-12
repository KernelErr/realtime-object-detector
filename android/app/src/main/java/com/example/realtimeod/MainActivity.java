package com.example.realtimeod;


import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.content.res.AssetManager;
import android.os.Handler;
import android.os.Looper;
import android.renderscript.RenderScript;
import android.os.Bundle;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.content.Context;
import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "paddlelite";
  private static boolean modalLoaded = false;
  protected static Predictor predictor = new Predictor();
  private RenderScript rs;

  // Model settings of object detection
  protected String modelPath = "models/fruit";
  protected String labelPath = "labels/fruit_label_list";
  protected int cpuThreadNum = 8;
  protected String cpuPowerMode = "LITE_POWER_FULL";
  protected String inputColorFormat = "RGB";
  protected long[] inputShape = new long[]{1, 3, 608, 608};
  protected float[] inputMean = new float[]{0.485f, 0.456f, 0.406f};
  protected float[] inputStd = new float[]{0.229f, 0.224f, 0.225f};
  protected float scoreThreshold = 0.5f;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    rs = RenderScript.create(this);
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                    (call, result) -> {
                      if (call.method.equals("loadModel")) {
                        loadModel(result);
                      } else if(call.method.equals("detectObject")){
                        HashMap image = call.arguments();
                        detectObject(image,result);
                      } else {
                        result.notImplemented();
                      }
                    }
            );
  }

  protected void loadModel(final Result result) {
    new Thread(new Runnable() {
      public void run() {
        try {
          predictor.init(MainActivity.this, modelPath, labelPath, cpuThreadNum,
                  cpuPowerMode,
                  inputColorFormat,
                  inputShape, inputMean,
                  inputStd, scoreThreshold,rs);
          modalLoaded=true;
          MethodResultWrapper resultWrapper = new MethodResultWrapper(result);
          resultWrapper.success("Modal Loaded Sucessfully");
        } catch (Exception e) {
          e.printStackTrace();
          MethodResultWrapper resultWrapper = new MethodResultWrapper(result);
          resultWrapper.error("Modal failed to loaded", e.getMessage(), null);
        }
      }
    }).start();
  }

  public  void detectObject(final HashMap image, final Result result) {
    new Thread(new Runnable() {
      public void run() {
        MethodResultWrapper resultWrapper = new MethodResultWrapper(result);
        if (!modalLoaded)
          resultWrapper.error("Model is not loaded", null, null);

        try {
          predictor.setInputImage(image);
          List<Object> prediction = predictor.runModel();
          resultWrapper.success(prediction);
        } catch (Exception e) {
          e.printStackTrace();
          resultWrapper.error("Running model failed", e.getMessage(), null);
        }
      }
    }).start();
  }

  private static class MethodResultWrapper implements MethodChannel.Result {
    private MethodChannel.Result methodResult;
    private Handler handler;

    MethodResultWrapper(MethodChannel.Result result) {
      methodResult = result;
      handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public void success(final Object result) {
      handler.post(new Runnable() {
        @Override
        public void run() {
          methodResult.success(result);
        }
      });
    }

    @Override
    public void error(final String errorCode, final String errorMessage, final Object errorDetails) {
      handler.post(new Runnable() {
        @Override
        public void run() {
          methodResult.error(errorCode, errorMessage, errorDetails);
        }
      });
    }

    @Override
    public void notImplemented() {
      handler.post(new Runnable() {
        @Override
        public void run() {
          methodResult.notImplemented();
        }
      });
    }
  }
}
