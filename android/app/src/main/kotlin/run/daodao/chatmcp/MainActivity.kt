package run.daodao.chatmcp

import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Contents
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.LogSeverity
import com.google.ai.edge.litertlm.SamplerConfig
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
    private val channelName = "echo.local_gemma"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private var engine: Engine? = null
    private var conversation: Conversation? = null
    private var loadedModelPath: String? = null
    private var activeJob: Job? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Engine.setNativeMinLogSeverity(LogSeverity.ERROR)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(statusMap())
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath").orEmpty()
                    scope.launch {
                        runCatching { loadModel(modelPath) }
                            .onSuccess { result.success(null) }
                            .onFailure { result.error("load_failed", it.message, null) }
                    }
                }
                "generate" -> {
                    val modelPath = call.argument<String>("modelPath").orEmpty()
                    val prompt = call.argument<String>("prompt").orEmpty()
                    val maxTokens = call.argument<Int>("maxTokens") ?: 512
                    val temperature = call.argument<Double>("temperature") ?: 0.7
                    activeJob?.cancel()
                    activeJob = scope.launch {
                        runCatching { generate(modelPath, prompt, maxTokens, temperature) }
                            .onSuccess { result.success(it) }
                            .onFailure { result.error("generate_failed", it.message, null) }
                    }
                }
                "cancel" -> {
                    activeJob?.cancel()
                    runCatching { conversation?.cancelProcess() }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        activeJob?.cancel()
        closeModel()
        scope.cancel()
        super.onDestroy()
    }

    private fun statusMap(): Map<String, Any?> {
        val path = loadedModelPath
        return mapOf(
            "supported" to true,
            "ready" to (engine?.isInitialized() == true && !path.isNullOrBlank()),
            "modelPath" to path,
            "message" to if (path.isNullOrBlank()) "No LiteRT-LM model loaded." else "LiteRT-LM model loaded."
        )
    }

    private suspend fun loadModel(modelPath: String) = withContext(Dispatchers.Default) {
        require(modelPath.isNotBlank()) { "Model path is empty." }
        val modelFile = File(modelPath)
        require(modelFile.exists()) { "Model file does not exist: $modelPath" }
        require(modelFile.extension.equals("litertlm", ignoreCase = true)) { "Expected a .litertlm model file." }

        if (loadedModelPath == modelPath && engine?.isInitialized() == true) return@withContext

        closeModel()

        val config = EngineConfig(
            modelPath = modelPath,
            backend = Backend.CPU(),
            maxNumTokens = 2048,
            cacheDir = cacheDir.absolutePath,
        )
        val nextEngine = Engine(config)
        nextEngine.initialize()
        engine = nextEngine
        loadedModelPath = modelPath
    }

    private suspend fun generate(
        modelPath: String,
        prompt: String,
        maxTokens: Int,
        temperature: Double,
    ): String = withContext(Dispatchers.Default) {
        require(prompt.isNotBlank()) { "Prompt is empty." }
        loadModel(modelPath)

        conversation?.close()
        val currentEngine = requireNotNull(engine) { "Engine is not initialized." }
        val config = ConversationConfig(
            systemInstruction = Contents.of("You are Echo running locally on this Android device."),
            samplerConfig = SamplerConfig(
                topK = 40,
                topP = 0.95,
                temperature = temperature.coerceIn(0.0, 2.0),
            ),
        )
        val currentConversation = currentEngine.createConversation(config)
        conversation = currentConversation

        val output = StringBuilder()
        currentConversation.sendMessageAsync(
            prompt,
            extraContext = mapOf(
                "max_tokens" to maxTokens,
                "runtime" to "echo_android_litert_lm",
            ),
        ).collect { message ->
            output.append(message.toString())
        }
        output.toString()
    }

    private fun closeModel() {
        runCatching { conversation?.close() }
        conversation = null
        runCatching { engine?.close() }
        engine = null
        loadedModelPath = null
    }
}
