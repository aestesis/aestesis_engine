//
//  lut.ui.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 13/03/2024.
//

import Foundation
import FlutterMacOS

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class LutUI: ModuleUI {
    var assets = SynchronizedDictionnary<String, LutAsset>()
    var previewSource:Bitmap?
    var source:ModuleUI? {
        guard let composition=composition else { return nil }
        let index = composition.composition.modules.firstIndex(where: { $0!.id == id })! - 1
        guard index>=0 else { return nil }
        return composition.modules[composition.composition.modules[index]!.id]
    }
    override init(parent: NodeUI, id: String) {
        super.init(parent: parent, id: id)
        if let composition = composition {
            output.value = FlutterBitmap(parent: self, assetId: id, size: composition.settings.size)
            self.io { [weak self] in
                guard let self=self, self.attached else { return }
                previewSource = Bitmap(parent:self,path:"Luts/true.color.png",bundle:Bundle(for: LutUI.self))
            }
        }
    }
    override func detach() {
        for a in assets.values {
            a.detach()
        }
        assets.removeAll()
        previewSource?.detach()
        previewSource = nil
        super.detach()
    }
    override func update(settings: CompositionSettings) {
        if output.value!.size != settings.size {
            output.value = FlutterBitmap(parent: self, assetId: id,  size: settings.size)
        }
    }
    override func update() {
        if module!.assets?.count != assets.count {
            for a in module!.assets! where !assets.has(key: a!.id) {
                let lut = LutAsset(parent: self, asset: a!)
                assets[a!.id] = lut
                lut.onTexture.once { [weak self] in
                    guard let self=self, self.attached else { return }
                    createPreview(lut: lut)
                }
            }
            let remove = assets.values.filter { pa in
                return !module!.assets!.contains(where: { $0!.id == pa.id })
            }
            for pa in remove {
                assets[pa.id]?.detach()
                assets[pa.id] = nil
                assetOutputs[pa.id] = nil
            }
        }
        module![LutControl.asset.id]!.count = Int64(assets.count)
        module![LutControl.asset.id]!.value = min(
            self.module![LutControl.asset.id]!.value,
            Double(self.module![LutControl.asset.id]!.count - 1))
    }
    
    override func process(time: Double, dtime: Double, beat: Double, dbeat: Double, fps:Double, audio: AudioAnalyzer.Info) {
        guard let source=source, let input=source.output.value, let output = output.value else { return }
        guard let control = module![LutControl.asset.id], control.count > 0 && control.value >= 0 && Int(control.value) < assets.count else { return }
        guard let asset = module!.assets![Int(control.value)], let lut = assets[asset.id] else { return }
        let g = Graphics(image:output)
        g.draw(rect: output.bounds, image: input, from: input.bounds.crop(output.bounds.ratio), lut: lut.texture)
        g.onDone { [weak self] _ in
            guard let self=self, self.attached else { return }
            output.updated()
        }
    }
    
    func createPreview(lut:LutAsset) {
        bg { [weak self] in
            guard let self=self, self.attached  else { return }
            guard let source=previewSource else {
                bg { [weak self] in
                    guard let self=self, self.attached  else { return }
                    createPreview(lut: lut)
                }
                return
            }
            let height = Int(90 * Device.screenScale)
            let width = Int(Double(height) * source.bounds.ratio)
            let image = Bitmap(parent:self, size:Size(width,height))
            let g = Graphics(image:image)
            g.draw(rect: image.bounds, image: source, from: source.bounds.crop(image.bounds.ratio), lut: lut.texture)
            g.onDone { [weak self] _ in
                guard let self=self, self.attached else { return }
                updateAssetOutput(assetId: lut.id,bitmap:image)
                urgent { [weak self] in
                    guard let self=self, self.attached else { return }
                    let data = image.pngData()
                    let preview = Preview(moduleId: id, assetId: lut.id, width: Int64(image.pixels.width),height: Int64(image.pixels.height), data: FlutterStandardTypedData(bytes: data))
                    preview.send()
                }
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class LutAsset : NodeUI {
    let onTexture = Event<Void>()
    let asset:Asset
    var id:String { return asset.id }
    var texture:Texture3D?
    init(parent: NodeUI, asset:Asset) {
        self.asset = asset
        super.init(parent:parent)
        if asset.uri != nil {
            zz { [weak self] in
                let url = Application.db.secureUrl(string: asset.uri!)!
                let lut = LUT(url: url)
                guard let self=self, self.attached, let lut=lut else {
                    if lut == nil {
                        // TODO: report error, if lut can't be read
                    }
                    return
                }
                urgent { [weak self] in
                    guard let self=self, self.attached else { return }
                    texture = lut.createTexture3D(parent: self)
                    onTexture.dispatch(())
                }
            }
        } else {
            zz {[weak self] in
                guard let self=self, self.attached else { return }
                onTexture.dispatch(())
            }
        }
    }
    override func detach() {
        texture?.detach()
        texture = nil
        super.detach()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
