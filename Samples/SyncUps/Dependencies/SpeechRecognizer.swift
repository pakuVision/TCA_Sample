//
//  SpeechRecognizer.swift
//  TCASample
//
//  Created by boardguy.vision on 2025/11/24.
//

import ComposableArchitecture

// @pre-concurrency
// Speech프레임워크는 Swift Concurrency기준으로 완벽히 준비되지 않았으니 경고 없이 사용하도록 요청
// Speech - 오래된 Objective-C기반 API
// 아이폰에서 음성을 텍스트로 변환하는 기능을 제공
@preconcurrency import Speech


// @DependencyClient
// 이 클라이언트 기능을 TCA에서 의존성으로 쓴다는 뜻 / 테스트환경에서 Mock으로 바꿔쓸수 있도록 하는 선언
// 이것을 선언하므로서 과거의 일일이 구현해야 했던 아래 항목을 자동으로 생성해준다
// - DependencyKey
// - liveValue
// - testValue
// - previewValue

// 음성인식API는 아래의 성질을 갖는다
// - 비동기처리, 마이크권한, 네트워크가능성, 테스트환경에서 실행불가능, 여러에러발생 가능성
// 즉 테스트가 어려운 API
// 그래서 TCA는 권장한다

// ####### 외부 서비스는 모두 DependencyClient로 감싸라 ########

@DependencyClient
struct SpeechClient {
    // 권한 상태
    var authorizationStatus: @Sendable () -> SFSpeechRecognizerAuthorizationStatus = { .denied }
    
    // 권한 요청
    var requestAuthorization: @Sendable () async ->  SFSpeechRecognizerAuthorizationStatus = { .denied }
    
    // 음성인식 스트림을 시작
    var startTask: @Sendable (_ request: UncheckedSendable<SFSpeechAudioBufferRecognitionRequest>) async ->
    AsyncThrowingStream<SpeechRecognitionResult, Error> = { _ in .finished() }
}

extension SpeechClient: DependencyKey {
    
    // 실제 ios api를 호출하는 구현체 (구현부분)
    // TCA Dependency시스템에서
    // 처음 의존성을 읽어오는 시점에 단 한 번 생성되는 값이다.
    
    // liveValue는 computed Property.
    static var liveValue: SpeechClient {
        
        // actor Speech - 실제로 음성인식을 수행하는 "엔진"
        // Speech를 actor로 만든 이유는
        // 여러 Task에서 동시에 접근해도 안전해야 함
        // 음성인식은, 중단, 종료, 시작 등 상태관리가 복잡함
        // actor는 이 상태들을 thread-safe로 보호해줌
        let speech = Speech()
        
        // SpeechClient() 를 반환
        return SpeechClient(
            authorizationStatus: {
                SFSpeechRecognizer.authorizationStatus()
            },
            requestAuthorization: {
                await withUnsafeContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { status in
                        continuation.resume(returning: status)
                    }
                }
            },
            startTask: { request in
                await speech.startTask(request: request.value)
            })
    }
}


nonisolated
struct SpeechRecognitionResult: Equatable {
    var bestTranscription: Transcription
    var isfinal: Bool
    
    init(bestTranscription: Transcription, isfinal: Bool) {
        self.bestTranscription = bestTranscription
        self.isfinal = isfinal
    }
}

struct Transcription: Equatable {
    var formattedString: String
}

private actor Speech {
    private var audioEngine: AVAudioEngine? = nil
    private var recognitionTask: SFSpeechRecognitionTask? = nil
    private var recognitionContinutaion: AsyncThrowingStream<SpeechRecognitionResult, any Error>.Continuation?
    
    
    /**
    
     1. 비동기 스트림 (AsyncThrowingStream) 을 만들고
     2. 마이크 입력을 받아서
     3. SFSpeechRecognizer에 음성 데이터를 보내고
     4. 인식된 텍스트를 실시간으로 스트림에 yield 하고
     5. 스트림이 종료되면 오디오 엔진 정리 (clean-up)  을 수행함
     
     audioEngine - 마이크 입력을 받아 buffer로 전달
     
     recognitionTask - 음성 인식 작업 수행 (SFSpeechRecognizer)
     
     AsyncThrowingStream - 텍스트를 지속적으로 보내는 스트림
     
     Continuation - 스트림 값 전달 / 종료하는 통로
     
     
     **/
    
    
    func startTask(request: SFSpeechAudioBufferRecognitionRequest) -> AsyncThrowingStream<SpeechRecognitionResult, any Error> {
        
        // 1. 비동기 스트림 시작
        // continuation -  스트림에 데이터를 밀어 넣는 라이브 파이프라인
        AsyncThrowingStream { continuation in
            
            self.recognitionContinutaion = continuation
            
            // 오디오세션 설정
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                continuation.finish(throwing: error)
            }
            
            // 오디오 엔진 생성
            self.audioEngine = AVAudioEngine()
            
            // 일본어 음성 인식기 생성
            let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
            
            // 음성인식 Task 시작
            
            // request - 마이크에서 buffer가 들어올 리퀘스트
            
            self.recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
                switch (result, error) {
                case let (.some(result), _):
                    // result - 인식된 텍스트
                    let value = SpeechRecognitionResult(bestTranscription: .init(formattedString: result.bestTranscription.formattedString), isfinal: result.isFinal)
                    
                    // .yield - 이것을 이용해서 스트림에 데이터 전달
                    continuation.yield(value)
                case (_, .some):
                    // error 던져서 스트림 종료 시킴
                    continuation.finish(throwing: error)
                case (.none, .none):
                    fatalError("It should not be possible to have both a nil result and nil error!")
                }
            }
            
            // 스트림이 종료 될 때 clean-up을 수행
            // Self가 가지고 있는 audioEngine,recognitionTask의 강참조를 피해 복사해서캡처 사용
            // []클로저 캡처 리스트 에서 이 두값을 복사해서 캡쳐하는 이유
            // clean-up시점에서 actor의 내부의 상태가 바뀔 수 있으므로 안정적인 스냅샷 값을 사용하기 위함
            continuation.onTermination = { [audioEngine, recognitionTask] _ in
                _ = speechRecognizer
                audioEngine?.stop()
                audioEngine?.inputNode.removeTap(onBus: 0)
                recognitionTask?.finish()
            }
            
            // 오디오 엔진에서 마이크 입력을 받아 request로 전달
            audioEngine?.inputNode.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: audioEngine?.inputNode.outputFormat(forBus: 0)
            ) { buffer, time in
                request.append(buffer)
            }
            
            // 오디오엔진 준비 및 시작
            audioEngine?.prepare()
            do {
                try audioEngine?.start()
            } catch {
                continuation.finish(throwing: error)
            }
            
            // ↑  이 사이클이 계속 반복됨
        }
    }
}
