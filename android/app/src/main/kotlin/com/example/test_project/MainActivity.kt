package com.example.test_project

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.tflite.TflitePlugin

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Automatically register plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine!!)

        // Initialize the Tflite Plugin
        TflitePlugin().registerWith(registrarFor("io.flutter.plugins.tflite.TflitePlugin"))
    }
}
