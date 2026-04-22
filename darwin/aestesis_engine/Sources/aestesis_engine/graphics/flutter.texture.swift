//
//  flutter.texture.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 28/02/2024.
//

import Foundation
import FlutterMacOS

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class AEFlutterTexture : NSObject, FlutterTexture {
    var pixelBuffer: Unmanaged<CVPixelBuffer>?
    var id:Int64?
    init(image:SharedBitmap) {
        pixelBuffer = Unmanaged.passUnretained(image.pixelBuffer!)
        super.init()
        register()
    }
    func register() {
        self.id = AestesisEnginePlugin.instance.textures?.register(self)
    }
    func unregister() {
        if let id=id {
            AestesisEnginePlugin.instance.textures?.unregisterTexture(id)
        }
        pixelBuffer?.release()
        pixelBuffer = nil
        id = nil
    }
    deinit {
        pixelBuffer?.release()
        pixelBuffer = nil
        if id != nil {
            fatalError("release of registred AEFlutterTexture")
        }
    }
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if let pixelBuf = self.pixelBuffer?.takeUnretainedValue() {
            return Unmanaged.passRetained(pixelBuf)
        } else {
            return nil
        }
    }
    func onTextureUnregistered(texture:NSObject & FlutterTexture) {
        Debug.info("AEFlutterTexture unregistered")
    }
    func publish(moduleId:String,assetId:String) {
        guard let id=id else { return }
        AestesisEnginePlugin.message?.texture(asset: AssetTexture(moduleId: moduleId, assetId: assetId, textureId: id), completion: { _ in })
    }
    
    func updated() {
        guard let id=id else { return }
        AestesisEnginePlugin.instance.textures?.textureFrameAvailable(id)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
