package com.jarvanmo.flutter_oss

import android.os.Handler
import android.os.Looper
import com.alibaba.sdk.android.oss.ClientException
import com.alibaba.sdk.android.oss.OSS
import com.alibaba.sdk.android.oss.OSSClient
import com.alibaba.sdk.android.oss.ServiceException
import com.alibaba.sdk.android.oss.common.auth.OSSAuthCredentialsProvider
import com.alibaba.sdk.android.oss.model.PutObjectRequest
import com.alibaba.sdk.android.oss.model.PutObjectResult
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import kotlin.concurrent.thread


class FlutterOssPlugin(private val registrar: Registrar, private val methodChannel: MethodChannel) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "com.jarvanmo/flutter_oss")
            channel.setMethodCallHandler(FlutterOssPlugin(registrar, channel))
        }
    }

    val handler = Handler(Looper.getMainLooper())

    private val authCredentialsProviderCache: HashMap<String, OSSAuthCredentialsProvider> = hashMapOf()

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "FlutterOSS: uploadAsync") {
            uploadAsync(call, result)
        } else {
            result.notImplemented()
        }
    }

    private fun uploadAsync(call: MethodCall, result: Result) {
        val stsServer = call.argument<String?>("stsServer")
        stsServer?.let {
            val provider: OSSAuthCredentialsProvider?
            if (authCredentialsProviderCache.containsKey(stsServer)) {
                provider = authCredentialsProviderCache[it]
            } else {
                provider = OSSAuthCredentialsProvider(it)
                authCredentialsProviderCache[stsServer] = provider
            }

            startToUploadAsync(call, provider)
        }

        result.success(true)

    }

    private fun startToUploadAsync(call: MethodCall, provider: OSSAuthCredentialsProvider?) {

        val resultMethod = "FlutterOSS:uploadAsyncResult"
        val completerId = call.argument<String?>("completerId")

        if (provider == null) {
            methodChannel.invokeMethod(resultMethod, {
                "isSuccess" to false
                "completerId" to completerId
                "code" to -1
            })
            return
        }

        val context = registrar.activeContext().applicationContext
        val endpoint = call.argument<String?>("endpoint")
        val objectName = call.argument<String>("objectName")
        val filePath = call.argument<String>("filePath")
        

        thread {
            try {
                val oss: OSS = OSSClient(context, endpoint, provider)
                val put = PutObjectRequest(call.argument<String>("bucketName"), objectName, filePath)
                val result: PutObjectResult = oss.putObject(put)
                handler.post {
                    methodChannel.invokeMethod(resultMethod, mapOf(
                        "isSuccess" to true,
                        "completerId" to completerId,
                        "code" to 0,
                        "remotePath" to result.serverCallbackReturnBody
                    ))
                }

            } catch (clientExcepion: ClientException) { // 本地异常，如网络异常等。
                handler.post {
                    methodChannel.invokeMethod(resultMethod, mapOf(
                        "isSuccess" to false,
                        "completerId" to completerId,
                        "message" to clientExcepion.message,
                        "code" to -2
                    ))
                }
            } catch (serviceException: ServiceException) { // 服务异常。
                handler.post {
                    methodChannel.invokeMethod(resultMethod, mapOf(
                        "isSuccess" to false,
                        "completerId" to completerId,
                        "message" to serviceException.rawMessage,
                        "code" to -3
                        ))
                }
            }
        }

//        val task: OSSAsyncTask<*> = oss.asyncPutObject(put, object : OSSCompletedCallback<PutObjectRequest?, PutObjectResult> {
//            override fun onSuccess(request: PutObjectRequest?, result: PutObjectResult) {
//                Log.e("TAG","oss -> ${result.serverCallbackReturnBody}")
//                methodChannel.invokeMethod(resultMethod,{
//                    "isSuccess" to true
//                    "completerId" to completerId
//                    "code" to 0
//                    "remotePath" to result.serverCallbackReturnBody
//                })
//            }
//
//            override fun onFailure(request: PutObjectRequest?, clientExcepion: ClientException, serviceException: ServiceException?) { // 请求异常。
//                if (serviceException != null) { // 服务异常。
//                    methodChannel.invokeMethod(resultMethod,{
//                        "isSuccess" to false
//                        "completerId" to completerId
//                        "message" to serviceException.rawMessage
//                        "code" to -3
//                    })
//                }else{
//                    methodChannel.invokeMethod(resultMethod,{
//                        "isSuccess" to false
//                        "completerId" to completerId
//                        "message" to clientExcepion.message
//                        "code" to -2
//                    })
//                }
//            }
//        })


    }
}
