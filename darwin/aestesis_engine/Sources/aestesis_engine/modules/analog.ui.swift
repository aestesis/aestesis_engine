//
//  Analog.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 16/10/2023.
//

import Foundation
// filters: https://github.com/Profiteam/iOS-Swift-Demos/blob/master/MetalImageFilters/MetalImageFilters/ImageFilters.swift
// blend: https://medium.com/@s1ddok/combine-the-power-of-coregraphics-and-metal-by-sharing-resource-memory-eabb4c1be615

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class AnalogUI: ModuleUI {
    var genrandom:[String:Double] = [:]
    var image:Bitmap?
    var lut:LutManager?
    override init(parent: NodeUI, id: String) {
        super.init(parent: parent, id: id)
        if let composition = composition {
            output.value = FlutterBitmap(parent: self, assetId: id, size: composition.settings.size)
            image=Bitmap(parent: self, size: composition.settings.size)
            lut = LutManager(parent: self, size: 64)
        }
    }
    override func detach() {
        while lut?.processing ?? false {
            Thread.sleep(0.01)
        }
        lut?.detach()
        lut = nil
        image?.detach()
        image=nil
        super.detach()
    }
    func sources(composition: Composition) -> [Module] {
        var sources: [Module] = []
        for i in stride(
            from: composition.modules.firstIndex(where: { $0?.id == id })! - 1, through: 0, by: -1)
        {
            let m = composition.modules[i]!
            sources.append(m)
            if m.type.isMixer {
                break
            }
        }
        return sources.reversed()
    }
    func control(source: ModuleUI, control: AnalogSourceControl) -> Control? {
        return module![control.id(source: source.module!)]
    }
    override func update(settings: CompositionSettings) {
        if output.value!.size != settings.size {
            output.value = FlutterBitmap(parent: self, assetId: id,  size: settings.size)
            image?.detach()
            image=Bitmap(parent: self, size: settings.size)
        }
    }
    override func update() {
        let sources = sources(composition: composition!.composition)
        let assets = sources.map { Asset(id: $0.id, name: $0.name) }
        if module!.assets != assets {
            module!.assets = assets
            for id in assetOutputs.keys {
                if !assets.contains(where: { $0.id ==  id }) {
                    assetOutputs[id] = nil
                }
            }
            for a in assets {
                if !assetOutputs.keys.contains(where: { $0 == a.id}) {
                    addAssetOutput(assetId: a.id)
                }
            }
        }
        let mcontrols: [Control] = module!.controls!.compactMap { $0 }
        let controls =
        mcontrols.filter({ $0.id.split(".").count == 2 })
        + sources.map { AnalogSourceControl.controls(module: module!, source: $0) }.joined()
        let diff = controls.difference(from: mcontrols)
        if !diff.isEmpty {
            module!.controls = mcontrols.applying(diff)
            for i in 0..<module!.controls!.count {
                let control = module!.controls![i]
                if let c = mcontrols.first(where: { $0.id == control!.id}) {
                    module!.controls![i]?.setValue(from: c)
                }
            }
        }
    }
    override func process(time: Double, dtime: Double, beat: Double, dbeat: Double, fps:Double, audio: AudioAnalyzer.Info) {
        guard let composition=composition, let output=output.value, let image = image else { return }
        guard let zoom=module![AnalogControl.zoom.id]?.value,let blur=module![AnalogControl.blur.id]?.value  else { return }
        guard  let hue=module![AnalogControl.hue.id]?.value, let saturation=module![AnalogControl.saturation.id]?.value, let brightness=module![AnalogControl.brightness.id]?.value else { return }
        guard let white=module![AnalogControl.white.id]?.value else { return }
        let sources=sources(composition: composition.composition).map { composition.modules[$0.id] }.compactMap { $0 }
        processAssetOutputs(sources: sources)
        if blur>0 {
            image.gaussianBlur(sigma: spow(blur,3) * image.size.length*0.01 * 60 / fps)
        }
        let g = Graphics(image:image)
        if hue != 0 || saturation != 0 || brightness != 0  {
            lut!.update(hue: spow(hue,2)*0.1, saturation: spow(saturation,2)*0.1, brightness: spow(brightness,2)*0.1)
            g.draw(rect: image.bounds, image: image, lut: lut!.texture)
        }
        g.fill(rect: image.bounds, blend: white>=0 ? .add : .sub, color:Color(a:1,l:apow(white,3)))
        for source in sources {
            processSource(graphics:g,rect:output.bounds,source:source)
        }
        g.onDone { [weak self] ok in
            guard let self = self, self.attached else { return }
            switch ok {
            case .discarded:
                Debug.warning("Analog: discarded")
            case .error(let message):
                Debug.error("Analog: error \(message)")
            case .success:
                bg { [weak self] in
                    guard let self = self, self.attached else { return }
                    output.copy(source: image)
                    output.updated()
                    if zoom != 0, self.attached {
                        let z = 1 - spow(zoom,1.5) * 0.075 * 30 / fps
                        let b = image.copy()
                        let g = EffectGraphics(image: image)
                        g.draw(rect:image.bounds,image:b,zoom:z,rotation: sin(time)*0.00001)
                    }
                }
            }
        }
    }
    func processSource(graphics g:Graphics, rect:Rect, source:ModuleUI) {
        guard let input=source.output.value,
              let ccolor=control(source:source,control:.color),
              let copacity=control(source:source,control:.opacity),
              let cblend=control(source: source,control:.blendMode),
              let blend=ControlBlendMode(rawValue:Int(cblend.value)),
              let cgain=control(source:source,control:.gain),
              copacity.value > 0
        else {
            return
        }
        let color=(ccolor.color * gain(cgain)).with(a:pow(copacity.value,2))
        g.draw(rect:rect,image:input,from:input.bounds.crop(rect.ratio),blend:blend.blendMode,color:color)
    }
    
    func processAssetOutputs(sources:[ModuleUI]) {
        for source in sources {
            guard let image = source.output.value, let blend=control(source: source,control:.blendMode)?.blend, let ccolor = control(source: source, control: .color), let cgain = control(source: source, control: .gain) else { continue }
            if genrandom[source.id] != image.generandom {
                genrandom[source.id] = image.generandom
                updateAssetOutput(assetId: source.id, bitmap: image, blend: blend.isLuma ? .luma : .opaque, color: Color(rgb:ccolor.color.rgb*gain(cgain)))
            }
        }
    }
    
    func gain(_ cgain:Control) -> Double { return cgain.value<0 ? 1 + spow(cgain.value,2) : 1 + pow(cgain.value,2) * 10 }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
func spow(_ value:Double,_ power:Double) -> Double {
    if value<0 {
        return -pow(-value,power)
    }
    return pow(value,power)
}
func spow(_ value:Float,_ power:Float) -> Float {
    if value<0 {
        return -pow(-value,power)
    }
    return pow(value,power)
}
func apow(_ value:Double,_ power:Double) -> Double {
    if value<0 {
        return pow(-value,power)
    }
    return pow(value,power)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class LutManager : NodeUI {
    let size:Int
    var texture:Texture3D?
    var hue:Double = 0
    var saturation:Double = 0
    var brightness:Double = 0
    var processing:Bool = false
    override func detach() {
        texture?.detach()
        texture = nil
        super.detach()
    }
    init(parent:NodeUI,size:Int) {
        self.size=size
        super.init(parent:parent)
    }
    func update(hue:Double,saturation:Double,brightness:Double) {
        guard !processing else { return }
        guard self.hue != hue || self.saturation != saturation || self.brightness != brightness else { return }
        processing = true
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self=self, self.attached else { return }
            let lut = LUT(size: size, decal: HSBA(hue:hue,saturation:saturation,brightness:brightness))
            bg { [weak self] in
                guard let self=self, self.attached else { return }
                texture = lut.createTexture3D(parent: self)
                self.hue = hue
                self.saturation = saturation
                self.brightness = brightness
                processing = false
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
