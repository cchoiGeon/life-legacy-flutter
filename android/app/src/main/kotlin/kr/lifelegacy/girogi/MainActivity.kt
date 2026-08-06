package kr.lifelegacy.girogi

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.TelephonyManager
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 전화번호 자동 입력용 네이티브 브리지.
 *
 * - getSimPhoneNumber: 전화 권한 하에 TelephonyManager.line1Number
 * - requestPhoneHint: Play Services Phone Number Hint (권한 불필요)
 */
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "kr.lifelegacy.girogi/phone"
    private var pendingHintResult: MethodChannel.Result? = null

    private val phoneHintLauncher =
        registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { activityResult ->
            val reply = pendingHintResult
            pendingHintResult = null
            if (reply == null) return@registerForActivityResult
            if (activityResult.resultCode != RESULT_OK) {
                reply.success(null)
                return@registerForActivityResult
            }
            try {
                val phone =
                    Identity.getSignInClient(this)
                        .getPhoneNumberFromIntent(activityResult.data)
                reply.success(phone)
            } catch (_: Exception) {
                reply.success(null)
            }
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimPhoneNumber" -> result.success(readSimPhoneNumber())
                    "requestPhoneHint" -> launchPhoneHint(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun readSimPhoneNumber(): String? {
        val hasNumbers =
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_NUMBERS) ==
                PackageManager.PERMISSION_GRANTED
        val hasState =
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) ==
                PackageManager.PERMISSION_GRANTED
        if (!hasNumbers && !hasState) return null

        return try {
            val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
            @Suppress("DEPRECATION")
            tm.line1Number?.takeIf { it.isNotBlank() }
        } catch (_: SecurityException) {
            null
        } catch (_: Exception) {
            null
        }
    }

    private fun launchPhoneHint(result: MethodChannel.Result) {
        if (pendingHintResult != null) {
            result.error("BUSY", "Already requesting phone hint", null)
            return
        }
        pendingHintResult = result
        val request = GetPhoneNumberHintIntentRequest.builder().build()
        Identity.getSignInClient(this)
            .getPhoneNumberHintIntent(request)
            .addOnSuccessListener { pendingIntent ->
                try {
                    phoneHintLauncher.launch(
                        androidx.activity.result.IntentSenderRequest.Builder(pendingIntent.intentSender)
                            .build(),
                    )
                } catch (_: Exception) {
                    pendingHintResult = null
                    result.success(null)
                }
            }
            .addOnFailureListener {
                pendingHintResult = null
                result.success(null)
            }
    }
}
