//
//  Syn.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 28/01/2024.
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

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct SynInfo: Hashable {
    static let all: [SynInfo] = [
        SynInfo(name: "Beta one", create: { SynBetaOne(parent: $0) }),
        SynInfo(name: "Coastal waves", create: { SynCoastalWaves(parent: $0) }),
        SynInfo(name: "Color", create: { SynColor(parent: $0) }),
        SynInfo(name: "Cygnus", create: { SynCygnus(parent: $0) }),
        SynInfo(name: "Equinox", create: { SynEquinox(parent: $0) }),
        SynInfo(name: "Frequency", create: { SynFrequency(parent: $0) }),
        SynInfo(name: "Geometry", create: { SynGeometry(parent: $0) }),
        SynInfo(name: "Hanna", create: { SynHanna(parent: $0) }),
        SynInfo(name: "Jelly", create: { SynJelly(parent: $0) }),
        SynInfo(name: "Mental", create: { SynMental(parent: $0) }),
        SynInfo(name: "Moon water", create: { SynMoonWater(parent: $0) }),
        SynInfo(name: "Radial", create: { SynRadial(parent: $0) }),
        SynInfo(name: "Sagittarius", create: { SynSagittarius(parent: $0) }),
        SynInfo(name: "Scene", create: { SynScene(parent: $0) }),
        SynInfo(name: "Soundscape", create: { SynSoundscape(parent: $0) }),
        SynInfo(name: "Sun Ra", create: { SynSunRa(parent: $0) }),
    ]
    let name: String
    let create: (_ parent: NodeUI) -> Syn
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    static func == (lhs: SynInfo, rhs: SynInfo) -> Bool {
        return lhs.name == rhs.name
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynUI: ModuleUI {
    static let assets: [Asset] = SynInfo.all.map { Asset(id: $0.name, name: $0.name) }
    var syns: [SynInfo: Syn] = [:]
    var lastSynInfo: SynInfo?
    override init(parent: NodeUI, id: String) {
        super.init(parent: parent, id: id)
        if let composition = composition {
            output.value = FlutterBitmap(parent:self,assetId:id,size:composition.settings.size)
            io {
                self.sendPreviews()
            }
        }
    }
    override func detach() {
        for syn in syns.values {
            syn.detach()
        }
        super.detach()
    }
    override func update(settings: CompositionSettings) {
        if let o = output.value, o.size != settings.size {
            output.value = FlutterBitmap(parent:self,assetId:id,size:settings.size)
            for syn in syns.values {
                syn.resize(size: settings.size)
            }
        }
    }
    override func update() {
        guard module != nil else { return }
        if module!.assets != SynUI.assets {
            module!.assets = SynUI.assets
            module![SynControl.asset.id]!.count = Int64(SynUI.assets.count)
            module![SynControl.asset.id]!.value = min(
                Double(SynUI.assets.count - 1), module![SynControl.asset.id]!.value)
        }
    }
    override func process(
        time: Double, dtime: Double, beat: Double, dbeat: Double, fps:Double, audio: AudioAnalyzer.Info
    ) {
        guard let control = module![SynControl.asset.id] else { return }
        let si = SynInfo.all[Int(control.value)]
        if !syns.has(key: si) {
            syns[si] = si.create(self)
        }
        if si != lastSynInfo {
            if let si = lastSynInfo, let image = assetOutputs[si.name], let cg = image.cgImage {
                bg { [weak self] in
                    self?.sendPreview(assetId: si.name, cgImage: cg, ratio: image.bounds.ratio)
                }
            }
            lastSynInfo = si
        }
        if let syn = syns[si], let output = output.value {
            syn.process(dtime: dtime, fps:fps, audio: audio, output: output) {
                output.updated()
                self.updateAssetOutput(assetId: si.name, bitmap: output)
            }
        }
    }
    func sendPreviews() {
        for si in SynInfo.all {
            guard assetOutputs[si.name] == nil else { continue }
            let b = Bitmap(parent:self,path: "assets/Syns/\(si.name).png",bundle:Bundle(for: SynUI.self))
            guard let cg = b.cgImage else { continue }
            sendPreview(assetId:si.name,cgImage:cg,ratio:b.size.ratio)
        }
    }
    func sendPreview(assetId: String, cgImage: CGImage, ratio: Double) {
        let height = Int(90 * Device.screenScale)
        let width = Int(Double(height) * ratio)
        var sizedImage: CGImage = cgImage
        if cgImage.height != height || cgImage.width != width {
            guard let sImage = cgImage.croppedResize(size: CGSize(width: width, height: height)) else { return }
            sizedImage = sImage
        }
        let data = sizedImage.pngData()
        let preview = Preview(moduleId: id, assetId: assetId, width: Int64(sizedImage.width),height: Int64(sizedImage.height), data: FlutterStandardTypedData(bytes: data))
        preview.send()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Syn: NodeUI {
    var time: Double = ß.rnd * 10000
    init(parent: NodeUI) {
        super.init(parent: parent)
    }
    func process(dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap, _ fn: @escaping () -> Void){
        time += dtime
        render(time: time, dtime: dtime, fps:fps, audio: audio, output: output, fn)
    }
    func resize(size:Size) {}
    func render(time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,_ fn: @escaping () -> Void) {}
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynRenderer : Syn, RendererProtocol {
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
