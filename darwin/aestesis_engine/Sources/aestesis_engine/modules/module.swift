//
//  Module.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 16/10/2023.
//

import CoreImage
import Foundation
import simd
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
public class ModuleUI: NodeUI {
    var output: SynchronizedValue<SharedBitmap> = SynchronizedValue<SharedBitmap>()
    var assetOutputs: SynchronizedDictionnary<String, FlutterBitmap> = SynchronizedDictionnary<String, FlutterBitmap>()
    private let _textureCache:TextureCache
    override var textureCache:TextureCache? {
        return _textureCache
    }
    var composition: CompositionUI? {
        return self.ancestor() as CompositionUI?
    }
    var module: Module? {
        get {
            return composition!.composition[id]
        }
        set(m) {
            composition!.composition[id] = m
        }
    }
    var id: String
    var ratio: Double {
        return composition?.ratio ?? 16 / 9
    }
    init(parent: NodeUI, id: String) {
        self.id = id
        _textureCache = TextureCache(device: parent.viewport!.gpu.device!)
        super.init(parent: parent)
    }
    override public func detach() {
        output.value?.detach()
        output.value = nil
        for oo in assetOutputs.values {
            oo.detach()
        }
        assetOutputs.removeAll()
        textureCache?.flush()
        super.detach()
    }
    
    func update(settings: CompositionSettings) {
    }
    func update() {
    }
    func update(control: Control) {
    }
    func process(time: Double, dtime: Double, beat: Double, dbeat: Double, fps:Double, audio: AudioAnalyzer.Info){
    }
    
    static func create(parent: NodeUI, module: Module) -> ModuleUI {
        switch module.type {
        case .analog:
            return AnalogUI(parent: parent, id: module.id)
        case .camera:
            return CameraUI(parent: parent, id: module.id)
        case .fx:
            return FxUI(parent: parent, id: module.id)
        case .lut:
            return LutUI(parent: parent, id: module.id)
        case .player:
            return PlayerUI(parent: parent, id: module.id)
        case .shader:
            return ShaderUI(parent: parent, id: module.id)
        case .syn:
            return SynUI(parent: parent, id: module.id)
        }
    }
    
    func updateAssetOutput(assetId: String, bitmap: Bitmap, blend:BlendMode = .opaque, color:Color = .white) {
        bg { [weak self] in
            guard let self = self, self.attached else { return }
            let height = (90 * Device.screenScale).rounded()
            let ratio = self.composition?.ratio ?? 16 / 9
            let size =  Size(height * ratio, height)
            var ab:FlutterBitmap?
            if let b = self.assetOutputs[assetId], b.size==size {
                ab = b
            } else {
                ab = FlutterBitmap(parent: self, assetId: assetId, size: Size(height * ratio, height))
                self.assetOutputs[assetId] = ab
            }
            guard let ab = ab else { fatalError("should not happen") }
            let g = Graphics(image: ab)
            g.draw(rect: ab.bounds, image: bitmap, from: bitmap.bounds.crop(ratio), blend: blend, color: color)
            g.onDone { [weak self] ok in
                guard let self = self, self.attached else { return }
                switch ok {
                case .error(let message):
                    Debug.error("Module.updateAssetOutput(): \(message)")
                default:
                    ab.updated()
                }
            }
        }
    }
    
    func addAssetOutput(assetId:String) {
        let height = (90 * Device.screenScale).rounded()
        let ratio = self.composition?.ratio ?? 16 / 9
        assetOutputs[assetId] = FlutterBitmap(parent: self, assetId: assetId, size: Size(height * ratio, height))
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
