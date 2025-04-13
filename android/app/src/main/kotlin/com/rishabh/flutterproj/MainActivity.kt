package com.rishabh.flutterproj

import io.flutter.embedding.android.FlutterFragmentActivity
import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject


class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.rishabh.flutterproj/intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendResultBack") {
                val responseJson = call.argument<String>("response") ?: ""
                try {
                    val json = JSONObject(responseJson)
                    val txnId = json.optString("txnId", "")
                    val status = json.optString("status", "")

                    println("txnId ==> $txnId , status ==> $status")
                    val resultIntent = Intent().apply {
                        putExtra("txnId", txnId ?: "")
                        putExtra("Status", status ?: "")
}
            
            
                    // val resultIntent = Intent().apply {
                    //     putExtra("txnId", txnId)
                    //     putExtra("Status", status)
                    // }
            
                    println("Sending result back with txnId: $txnId and Status: $status")
                    setResult(Activity.RESULT_OK, resultIntent)
                    finish()
                    result.success("Result sent back successfully")
                } catch (e: Exception) {
                    println("Failed to parse response JSON: ${e.message}")
                    result.error("JSON_ERROR", "Failed to parse response", e.message)
                }
            }
        }
        
    }
}
