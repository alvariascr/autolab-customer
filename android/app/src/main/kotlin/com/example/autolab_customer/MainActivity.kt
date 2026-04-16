package com.example.autolab_customer

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "AutolabMainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.i(TAG, "onCreate savedInstanceState=${savedInstanceState != null}")
        super.onCreate(savedInstanceState)
    }

    override fun onStart() {
        Log.i(TAG, "onStart")
        super.onStart()
    }

    override fun onResume() {
        Log.i(TAG, "onResume")
        super.onResume()
    }

    override fun onPause() {
        Log.i(TAG, "onPause")
        super.onPause()
    }

    override fun onStop() {
        Log.i(TAG, "onStop")
        super.onStop()
    }

    override fun onDestroy() {
        Log.i(TAG, "onDestroy isFinishing=$isFinishing isChangingConfigurations=$isChangingConfigurations")
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        Log.i(TAG, "onNewIntent action=${intent.action}")
        super.onNewIntent(intent)
    }
}
