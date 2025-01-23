import Foundation
import Speech

class SpeechRecognizer {
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    
    func checkPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        // 1. 检查是否已经在录音
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // 2. 创建音频引擎和录音请求
        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let audioEngine = audioEngine,
              let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer else {
            completion(.failure(NSError(domain: "SpeechRecognizer",
                                     code: -1,
                                     userInfo: [NSLocalizedDescriptionKey: "Speech recognition is not available"])))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 3. 配置音频会话
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0,
                               bufferSize: 1024,
                               format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            // 4. 开始识别
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    if result.isFinal {
                        completion(.success(text))
                    }
                }
            }
            
        } catch {
            completion(.failure(error))
        }
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        // 重置音频会话
        try? AVAudioSession.sharedInstance().setActive(false)
    }
} 