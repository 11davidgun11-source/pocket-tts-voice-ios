#if canImport(SherpaOnnx)
import SherpaOnnx
#elseif canImport(SherpaOnnxShared)
import SherpaOnnxShared
#else
#error("SherpaOnnx module not found. Please check your SPM dependency configuration.")
#endif
import Foundation

/// Talks to the on-device voice model. Built once, kept in memory.
/// Voice clone needs only your audio sample. No written script of it.
final class TTSService {
    private var tts: SherpaOnnxOfflineTtsWrapper?
    private var modelKey = ""

    /// Build the engine for the downloaded files. Returns false on fail.
    func warmup(store: ModelStore, diag: DiagLog) -> Bool {
        let key = ModelStore.fileNames.joined()
        if tts != nil && modelKey == key {
            return true
        }
        diag.add("engine warmup start")
        let pocket = sherpaOnnxOfflineTtsPocketModelConfig(
            lmFlow: store.path(for: "lm_flow.int8.onnx"),
            lmMain: store.path(for: "lm_main.int8.onnx"),
            encoder: store.path(for: "encoder.onnx"),
            decoder: store.path(for: "decoder.int8.onnx"),
            textConditioner: store.path(for: "text_conditioner.onnx"),
            vocabJson: store.path(for: "vocab.json"),
            tokenScoresJson: store.path(for: "token_scores.json")
        )
        let modelConfig = sherpaOnnxOfflineTtsModelConfig(numThreads: 2, pocket: pocket)
        var ttsConfig = sherpaOnnxOfflineTtsConfig(model: modelConfig)
        tts = SherpaOnnxOfflineTtsWrapper(config: &ttsConfig)
        modelKey = key
        diag.add("engine warmup done")
        return true
    }

    /// Make speech. Saves a WAV file. Returns its URL or nil on fail.
    func speak(text: String, voiceWavPath: String, outURL: URL, diag: DiagLog) -> URL? {
        guard let tts = tts else {
            diag.add("speak failed: engine not built")
            return nil
        }
        let wave = SherpaOnnxWaveWrapper.readWave(filename: voiceWavPath)
        guard !wave.samples.isEmpty else {
            diag.add("speak failed: voice sample unreadable")
            return nil
        }
        diag.add("voice sample: \(wave.samples.count) samples at \(wave.sampleRate) Hz")

        var genConfig = SherpaOnnxGenerationConfigSwift()
        genConfig.speed = 1.0
        genConfig.referenceAudio = wave.samples
        genConfig.referenceSampleRate = wave.sampleRate
        genConfig.extra = ["max_reference_audio_len": 15.0]

        diag.add("generate start, text \(text.count) chars")
        let callback: TtsProgressCallbackWithArg = { _, _, _, _ in
            1 // keep going
        }
        let audio = tts.generateWithConfig(
            text: text, config: genConfig, callback: callback, arg: nil)
        guard audio.save(filename: outURL.path) == 1 else {
            diag.add("speak failed: save failed")
            return nil
        }
        diag.add("generate done: \(outURL.lastPathComponent)")
        return outURL
    }
}
