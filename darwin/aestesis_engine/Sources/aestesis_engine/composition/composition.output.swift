//
//  composition.output.swift
//  flutter_alib
//
//  Created by renan jegouzo on 20/02/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CompositionOutput: NodeUI {
    let queue: DispatchQueue = DispatchQueue(label: "CompositionOutput", qos: .utility)
    var states: CompositionStates = CompositionStates(
        recording: false, streaming: false, previewing: false)
    {
        didSet {
            let st = states
            DispatchQueue.main.async {
                AestesisEnginePlugin.message?.states(states: st) { _ in }
            }
        }
    }
    var videoWriter: VideoWriter?
    var videoStreamer: VideoStreamer?
    var preview: CompositionPreview?
    var settings: CompositionSettings?
    
    override func detach() {
        videoWriter?.stop()
        videoStreamer?.stop()
        preview?.detach()
        videoWriter = nil
        videoStreamer = nil
        preview = nil
        super.detach()
    }
    
    func update(settings: CompositionSettings) {
        stopRecording()
        self.settings = settings
        preview?.ratio = settings.size.ratio
    }
    
    func error(message: String) {
        DispatchQueue.main.async {
            AestesisEnginePlugin.message?.message(level: .error, message: message) { _ in }
        }
    }
    
    func push(image: SharedBitmap) {
        if let videoWriter = videoWriter, videoWriter.status == .writing,
           let cvPixelBuffer = image.pixelBuffer
        {
            queue.async {
                videoWriter.write(pixels: cvPixelBuffer)
            }
        }
        if let preview = preview {
            preview.push(image: image)
        }
    }
    
    func push(pcm: [Float]) {
        if let videoWriter = videoWriter, videoWriter.status == .writing, !pcm.isEmpty {
            queue.async {
                videoWriter.write(pcm: pcm)
            }
        }
    }
    
    func preview(show: Bool) {
        self.preview?.detach()
        self.preview = nil
        if show {
            self.preview = CompositionPreview(parent: self, ratio: settings?.size.ratio ?? 16/9)
            self.preview!.onClose.once { [weak self] in
                guard let self = self else { return }
                preview?.detach()
                preview = nil
                queue.async {
                    self.states.previewing = false
                }
            }
        } else {
            self.preview?.detach()
            self.preview = nil
        }
        queue.async {
            self.states.previewing = show
        }
    }
    
    func startRecording(file: String) {
        guard let settings = settings else {
            Debug.error(Error("composition.output: no settings"))
            return
        }
        let url = URL(filePath: file).checkFile(strategy: .rename)
        let options: [VideoWriter.Option] = settings.audioSettings == nil ? [.video] : [.audio, .video]
        queue.async {
            do {
                self.videoWriter = try VideoWriter(
                    url: url, size: settings.size, fps: settings.fps, options: options)
            } catch {
                self.error(message: error.localizedDescription)
                return
            }
            self.videoWriter!.onChanged.alive(self) { state in
                self.states.recording = state == .writing
                switch state {
                case .failed(let e): self.error(message: e.localizedDescription)
                default: break
                }
            }
            if self.videoWriter!.start() {
                Debug.info("VideoWriter started, status: \(self.videoWriter!.status)")
            } else {
                let status = self.videoWriter!.status
                Debug.info("VideoWriter failed to start, status: \(self.videoWriter!.status)")
                self.videoWriter!.close()
                self.videoWriter = nil
                self.error(message: status.description)
            }
        }
    }
    
    func stopRecording() {
        queue.async {
            self.videoWriter?.stop()
            self.videoWriter?.close()
            self.videoWriter = nil
        }
    }
    
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
