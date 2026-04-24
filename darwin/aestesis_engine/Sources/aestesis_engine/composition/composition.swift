import AVFoundation
import Foundation
import aestesis_alib

#if os(iOS)
import UIKit
import Flutter
#else
import AppKit
import FlutterMacOS
#endif

// TODO: add NDI https://ndi.video/  (ethernet video cable)

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CompositionUI: NodeUI {
    let lock = Lock()
    var timer: Timer?
    var audioStream: Stream<Float>?
    let audioAnalyzer = AudioAnalyzer()
    var composition = Composition(id: UUID().uuidString, name: "Composition", modules: [])
    var settings = CompositionSettings(width: 1920, height: 1080, fps: 60)
    var modules: [String: ModuleUI] = [:]
    var compositionOutput:CompositionOutput?
    var frame: Int = 0
    var fps: Double = 60
    let startTime = ß.time
    var time: Double = 0
    var beat: Double = 0
    let bpm: Double = 120
    var ratio: Double {
        return settings.width / settings.height
    }
    var output:SharedBitmap? {
        guard !composition.modules.isEmpty, let module = composition.modules.last as? Module, let output = modules[module.id]?.output else { return nil }
        return output.value
    }
    init(parent: NodeUI) {
        var statFrame = 0
        super.init(parent: parent)
        EffectGraphics.initShareds(store: viewport!)
        viewport!.pulse.alive(self) {
            self.pulse()
        }
        timer = Timer(period: 0.1) { [weak self] in
            guard let self = self else { return }
            let fps = self.fps
            if statFrame % 10 == 0 {
                self.io {
                    let cpu = cpuUsage()
                    let stats = CompositionStatistics(fps: fps, cpu: cpu.user, gpu: 0, ram: memoryMbUsed())
                    stats.send()
                }
            }
            if self.settings.audioSettings != nil {
                let info = self.audioAnalyzer.info
                let level = AudioLevel(
                    peak: Double(info.peak),
                    eq: Equalizer(
                        low: Double(info.eq.low), mid: Double(info.eq.medium), high: Double(info.eq.high)))
                level.send()
            }
            statFrame += 1
        }
        compositionOutput = CompositionOutput(parent:self)
    }
    override func detach() {
        compositionOutput?.detach()
        timer?.stop()
        let modules = self.modules.values
        self.modules.removeAll()
        for m in modules {
            m.detach()
        }
        audioStream?.close()
        super.detach()
    }
    func pulse() {
        let time = ß.time - startTime
        let dtime = time - self.time
        let dbeat = dtime * bpm / 60
        beat += dbeat
        self.time = time
        fps = (1 / dtime) * 0.01 + fps * 0.99
        lock.sync {
            let audio = self.audioAnalyzer.info
            for m in self.composition.modules where m != nil {
                modules[m!.id]!.process(
                    time: time, dtime: dtime, beat: beat, dbeat: dbeat, fps: fps, audio: audio)
            }
        }
        frame += 1
        if let compositionOutput=compositionOutput, let output = output {
            compositionOutput.push(image:output)
        }
    }
    
    func sync(_ execute: () -> Void) {
        lock.sync {
            execute()
        }
    }
    func async(_ execute: @escaping () -> Void) {
        lock.async {
            execute()
        }
    }

    func update() {
        //Debug.info("update composition")
        for m in composition.modules where m != nil && modules[m!.id] == nil {
            let mui = ModuleUI.create(parent: self, module: m!)
            mui.update(settings: settings)
            modules[m!.id] = mui
        }
        for mui in modules.values where !composition.modules.contains(where: { $0?.id == mui.id }) {
            modules[mui.id] = nil
            _ = wait(0.1) {
                // wait background rendering over
                mui.detach()
            }
        }
        for mui in modules.values {
            mui.update()
        }
    }
    
    func update(module: Module) {
        modules[module.id]?.update()
    }
    
    func update(control: Control) {
        modules[control.moduleId]?.update(control: control)
    }
    
    func update(settings: CompositionSettings) {
        if !AudioSettings.equals(self.settings.audioSettings, settings.audioSettings) {
            DispatchQueue.main.async {
                if let audioStream = self.audioStream {
                    audioStream.close()
                    self.audioStream = nil
                }
                if let audioSettings = settings.audioSettings,
                   let device = aestesis_alib.AudioDevice.getDevice(name: audioSettings.deviceName)
                {
                    do {
                        self.audioStream = try device.open(
                            leftChannel: Int(audioSettings.leftChannel),
                            rightChannel: Int(audioSettings.rightChannel), fps: settings.fps)
                        self.audioStream!.onData.alive(self) { [weak self] in
                            if let self = self, let stream = self.audioStream {
                                let stereo = stream.read(stream.available)
                                let mono = stereoToMono(stereo: stereo)
                                self.bg {
                                    self.audioAnalyzer.feed(mono, offset: 0, count: mono.count)
                                }
                                self.compositionOutput?.push(pcm:stereo)
                            }
                        }
                        Debug.info("audio input started for device \(device.name)")
                        self.audioStream!.onClose.once {
                            Debug.info("audio input closed for device \(device.name)")
                            self.audioAnalyzer.clear()
                        }
                    } catch {
                        Debug.error("AudioInput error: \(error)")
                        self.audioAnalyzer.clear()
                    }
                }
            }
        }
        self.settings = settings
        for m in modules.values {
            m.update(settings: settings)
        }
        compositionOutput?.update(settings:settings)
    }
    
    func stereoToMono(stereo: [Float]) -> [Float] {
        var mono: [Float] = []
        var i = 0
        while i < stereo.count {
            mono.append((stereo[i] + stereo[i + 1]) * 0.5)
            i += 2
        }
        return mono
    }
    
    func startRecording(path: String) {
        compositionOutput?.startRecording(file: path)
    }
    
    func stopRecording() {
        compositionOutput?.stopRecording()
    }
    
    func preview(show:Bool) {
        compositionOutput?.preview(show: show)
    }
    
    func setAssetData(key:String,json:JSON) {
        
    }
    
    func getAssetData(key:String) -> JSON? {
        return nil
    }
    
    func setAssetDatas(json:JSON) {
        
    }
    func getAssetDatas() -> JSON? {
        return nil
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
enum AEError: Swift.Error {
    case previewError(error: String)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
