//
//  fx.ui.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 25/04/2024.
//

import Foundation
import aestesis_alib

#if os(iOS)
    import UIKit
    import Flutter
#else
    import AppKit
    import FlutterMacOS
#endif

// // liquid simulation: https://andrewkchan.dev/posts/fire.html

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct FxInfo: Hashable {
    static let all: [FxInfo] = [
        FxInfo(name: "Color cycle", create: { FxColorCycle(parent: $0) }),
        FxInfo(name: "Color EQ", create: { FxColorEq(parent: $0) }),
        FxInfo(name: "Color pulse", create: { FxColorPulse(parent: $0) }),
        FxInfo(name: "Color RGB", create: { FxColorRGB(parent: $0) }),
        FxInfo(name: "Dynamic drop", create: { FxDynamicDrop(parent: $0) }),
        FxInfo(name: "Dynamic pulse", create: { FxDynamicPulse(parent: $0) }),
        FxInfo(name: "Dynamic punch", create: { FxDynamicPunch(parent: $0) }),
        FxInfo(name: "Dynamic square", create: { FxDynamicSquare(parent: $0) }),
        FxInfo(name: "Dynamic twirl", create: { FxDynamicTwirl(parent: $0) }),
        FxInfo(name: "Dynamic VHS", create: { FxDynamicVHS(parent: $0) }),
        FxInfo(name: "Test", create: { FxTest(parent: $0) }),
    ]
    let name: String
    let create: (_ parent: NodeUI) -> Fx
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    static func == (lhs: FxInfo, rhs: FxInfo) -> Bool {
        return lhs.name == rhs.name
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxUI: ModuleUI {
    static let assets: [Asset] = FxInfo.all.map { Asset(id: $0.name, name: $0.name) }
    var fxs: [FxInfo: Fx] = [:]
    var lastFxInfo: FxInfo?
    var level: Double = 0
    var source: ModuleUI? {
        guard let composition = composition else { return nil }
        let index = composition.composition.modules.firstIndex(where: { $0!.id == id })! - 1
        guard index >= 0 else { return nil }
        return composition.modules[composition.composition.modules[index]!.id]
    }
    override init(parent: NodeUI, id: String) {
        super.init(parent: parent, id: id)
        if let composition = composition {
            output.value = FlutterBitmap(parent: self, assetId: id, size: composition.settings.size)
            io {
                self.sendPreviews()
            }
        }
    }
    override func detach() {
        for fx in fxs.values {
            fx.detach()
        }
        super.detach()
    }
    override func update(settings: CompositionSettings) {
        if let o = output.value, o.size != settings.size {
            output.value = FlutterBitmap(parent: self, assetId: id, size: settings.size)
            for fx in fxs.values {
                fx.resize(size: settings.size)
            }
        }
    }
    override func update() {
        guard module != nil else { return }
        if module!.assets != FxUI.assets {
            module!.assets = FxUI.assets
            module![FxControl.asset.id]!.count = Int64(FxUI.assets.count)
            module![FxControl.asset.id]!.value = min(
                Double(FxUI.assets.count - 1), module![FxControl.asset.id]!.value)
        }
    }
    override func process(
        time: Double, dtime: Double, beat: Double, dbeat: Double, fps: Double,
        audio: AudioAnalyzer.Info
    ) {
        guard let casset = module![FxControl.asset.id] else { return }
        guard let clevel = module![FxControl.level.id] else { return }
        guard let input = source?.output.value else { return }
        let si = FxInfo.all[Int(casset.value)]
        if !fxs.has(key: si) {
            fxs[si] = si.create(self)
        }
        level = level * 0.5 + clevel.value * 0.5
        if si != lastFxInfo {
            if let si = lastFxInfo, let image = assetOutputs[si.name], let cg = image.cgImage {
                bg { [weak self] in
                    self?.sendPreview(assetId: si.name, cgImage: cg, ratio: image.bounds.ratio)
                }
            }
            lastFxInfo = si
        }
        if let fx = fxs[si], let output = output.value {
            fx.process(
                dtime: dtime, fps: fps, audio: audio, input: input, output: output, level: level
            ) {
                output.updated()
                self.updateAssetOutput(assetId: si.name, bitmap: output)
            }
        }
    }
    func sendPreviews() {
        for si in SynInfo.all {
            guard assetOutputs[si.name] == nil else { continue }
            let b = Bitmap(
                parent: self, path: "assets/Syns/\(si.name).png", bundle: Bundle.aestesis)
            guard let cg = b.cgImage else { continue }
            sendPreview(assetId: si.name, cgImage: cg, ratio: b.size.ratio)
        }
    }
    func sendPreview(assetId: String, cgImage: CGImage, ratio: Double) {
        let height = Int(90 * Device.screenScale)
        let width = Int(Double(height) * ratio)
        var sizedImage: CGImage = cgImage
        if cgImage.height != height || cgImage.width != width {
            guard let sImage = cgImage.croppedResize(size: CGSize(width: width, height: height))
            else { return }
            sizedImage = sImage
        }
        let data = sizedImage.pngData()
        let preview = Preview(
            moduleId: id, assetId: assetId, width: Int64(sizedImage.width),
            height: Int64(sizedImage.height), data: FlutterStandardTypedData(bytes: data))
        preview.send()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Fx: NodeUI {
    var time: Double = ß.rnd * 10000
    init(parent: NodeUI) {
        super.init(parent: parent)
    }
    func process(
        dtime: Double, fps: Double, audio: AudioAnalyzer.Info, input: Bitmap, output: Bitmap,
        level: Double, _ fn: @escaping () -> Void
    ) {
        time += dtime
        render(
            time: time, dtime: dtime, fps: fps, audio: audio, input: input, output: output,
            level: level, fn)
    }
    func resize(size: Size) {}
    func render(
        time: Double, dtime: Double, fps: Double, audio: AudioAnalyzer.Info, input: Bitmap,
        output: Bitmap, level: Double, _ fn: @escaping () -> Void
    ) {}
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxRenderer: Fx, RendererProtocol {
    var renderer: Renderer?
    var db: NodeUI { return self }
    override init(parent: NodeUI) {
        super.init(parent: parent)
        renderer = Renderer(parent: self)
    }
    override func detach() {
        renderer?.detach()
        renderer = nil
        super.detach()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
