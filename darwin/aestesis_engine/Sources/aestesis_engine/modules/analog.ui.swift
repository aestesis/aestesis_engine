//
//  Analog.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 16/10/2023.
//

import Foundation
import Metal
import aestesis_alib

// filters: https://github.com/Profiteam/iOS-Swift-Demos/blob/master/MetalImageFilters/MetalImageFilters/ImageFilters.swift
// blend: https://medium.com/@s1ddok/combine-the-power-of-coregraphics-and-metal-by-sharing-resource-memory-eabb4c1be615

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class AnalogUI: ModuleUI, @unchecked Sendable {
    var genrandom: [String: Double] = [:]
    var images: [Bitmap] = []
    var lut: LutManager?
    var src: Bitmap {
        return images.first!
    }
    var dst: Bitmap {
        return images.last!
    }
    func swap() {
        images.swapAt(0, 1)
    }
    override init(parent: NodeUI, id: String) {
        super.init(parent: parent, id: id)
        if let composition = composition {
            output.value = FlutterBitmap(parent: self, assetId: id, size: composition.settings.size)
            for _ in 0..<2 {
                images.append(Bitmap(parent: self, size: composition.settings.size))
            }
            lut = LutManager(parent: self, size: 64)
        }
    }
    override func detach() {
        while lut?.processing ?? false {
            Thread.sleep(0.01)
        }
        lut?.detach()
        lut = nil
        for i in images {
            i.detach()
        }
        images.removeAll()
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
            output.value = FlutterBitmap(parent: self, assetId: id, size: settings.size)
            for i in images {
                i.detach()
            }
            images.removeAll()
            for _ in 0..<2 {
                images.append(Bitmap(parent: self, size: settings.size))
            }
        }
    }
    override func update() {
        let sources = sources(composition: composition!.composition)
        let assets = sources.map { Asset(id: $0.id, name: $0.name) }
        if module!.assets != assets {
            module!.assets = assets
            for id in assetOutputs.keys {
                if !assets.contains(where: { $0.id == id }) {
                    assetOutputs[id] = nil
                }
            }
            for a in assets {
                if !assetOutputs.keys.contains(where: { $0 == a.id }) {
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
                if let c = mcontrols.first(where: { $0.id == control!.id }) {
                    module!.controls![i] = c
                }
            }
        }
    }
    override func process(
        time: Double, dtime: Double, beat: Double, dbeat: Double, fps: Double,
        audio: AudioAnalyzer.Info
    ) {
        let stime = ß.time
        guard let composition = composition, let output = output.value, let viewport = viewport
        else {
            return
        }
        guard let zoom = module![AnalogControl.zoom.id]?.value,
            let blur = module![AnalogControl.blur.id]?.value
        else { return }
        guard let hue = module![AnalogControl.hue.id]?.value,
            let saturation = module![AnalogControl.saturation.id]?.value,
            let brightness = module![AnalogControl.brightness.id]?.value
        else { return }
        guard let white = module![AnalogControl.white.id]?.value else { return }
        let sources = sources(composition: composition.composition).map {
            composition.modules[$0.id]
        }.compactMap { $0 }
        processAssetOutputs(sources: sources)
        var fence: MTLFence?
        if true {
            let gs = Graphics(image: dst, viewport: viewport)
            for source in sources {
                processSource(graphics: gs, rect: dst.bounds, source: source)
            }
            fence = gs.update()
            swap()
        }

        if abs(zoom) > 0.005 {
            let z = 1 - spow(zoom, 1.5) * 0.075 * 30 / fps
            let g = EffectGraphics(image: dst, viewport: viewport)
            if let fence = fence {
                g.wait(fence: fence)
            }
            g.draw(
                rect: dst.bounds, image: src, zoom: z, rotation: sin(time) * 0.00001
            )
            fence = g.update()
            swap()
        }
        if let f = fence, blur > 0 {
            fence = dst.gaussianBlur(
                source: src, sigma: spow(blur, 3) * dst.size.length * 0.01 * 60 / fps, fence: f)
            swap()
        }
        if hue != 0 || saturation != 0 || brightness != 0 {
            lut!.update(
                hue: spow(hue, 2) * 0.1, saturation: spow(saturation, 2) * 0.1,
                brightness: spow(brightness, 2) * 0.1)
            let g = Graphics(image: dst)
            if let fence = fence {
                g.wait(fence: fence)
            }
            g.draw(rect: src.bounds, image: src, lut: lut!.texture)
            fence = g.update()
            swap()
        }
        if abs(white) > 0.005 {
            let g = Graphics(image: src)
            if let fence = fence {
                g.wait(fence: fence)
            }
            g.fill(
                rect: src.bounds, blend: white >= 0 ? .add : .sub,
                color: Color(a: 1, l: apow(white, 3)))
            fence = g.update()
        }
        if let fence = fence {
            _ = output.copy(source: src, fence: fence) {
                output.updated()
                composition.addModuleStatistics(
                    ModuleStatistics(id: self.id, usage: ß.time - stime))
            }
        }
        swap()
    }
    func processSource(graphics g: Graphics, rect: Rect, source: ModuleUI) {
        guard let input = source.output.value,
            let ccolor = control(source: source, control: .color),
            let copacity = control(source: source, control: .opacity),
            let cblend = control(source: source, control: .blendMode),
            let blend = ControlBlendMode(rawValue: Int(cblend.value)),
            let cgain = control(source: source, control: .gain),
            let cluma = control(source: source, control: .lumaKey),
            copacity.value > 0
        else {
            return
        }
        let color = (ccolor.color * gain(cgain)).with(a: pow(copacity.value, 2))
        g.draw(
            rect: rect, image: input, from: input.bounds.crop(rect.ratio), blend: blend.blendMode,
            color: color, lumaKey: spow(cluma.value, 2))
    }

    func processAssetOutputs(sources: [ModuleUI]) {
        for source in sources {
            guard let image = source.output.value,
                let blend = control(source: source, control: .blendMode)?.blend,
                let ccolor = control(source: source, control: .color),
                let cgain = control(source: source, control: .gain),
                let cluma = control(source: source, control: .lumaKey)
            else { continue }
            if genrandom[source.id] != image.generandom {
                genrandom[source.id] = image.generandom
                updateAssetOutput(
                    assetId: source.id, bitmap: image, blend: blend.isLuma ? .luma : .opaque,
                    color: Color(rgb: ccolor.color.rgb * gain(cgain)), lumaKey: spow(cluma.value, 2)
                )
            }
        }
    }

    func gain(_ cgain: Control) -> Double {
        return cgain.value < 0 ? 1 + spow(cgain.value, 2) : 1 + pow(cgain.value, 2) * 10
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
func spow(_ value: Double, _ power: Double) -> Double {
    if value < 0 {
        return -pow(-value, power)
    }
    return pow(value, power)
}
func spow(_ value: Float, _ power: Float) -> Float {
    if value < 0 {
        return -pow(-value, power)
    }
    return pow(value, power)
}
func apow(_ value: Double, _ power: Double) -> Double {
    if value < 0 {
        return pow(-value, power)
    }
    return pow(value, power)
}
func apow(_ value: Float, _ power: Float) -> Float {
    if value < 0 {
        return pow(-value, power)
    }
    return pow(value, power)
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class LutManager: NodeUI, @unchecked Sendable {
    var texture: Texture3D?
    var processing: Bool = false
    var hsv: Vec3 = .zero
    override func detach() {
        texture?.detach()
        texture = nil
        super.detach()
    }
    init(parent: NodeUI, size: Int) {
        super.init(parent: parent)
        texture = Texture3D(parent: self, size: size)
    }
    func update(hue: Double, saturation: Double, brightness: Double) {
        let hsv = Vec3(hue, saturation, brightness)
        guard !processing else { return }
        guard self.hsv != hsv else { return }
        guard self.attached, let texture = texture else { return }
        processing = true
        do {
            try texture.fill(
                hsv: hsv,
                fn: { result in
                    self.processing = false
                    switch result {
                    case .discarded:
                        Debug.info("Texture3D.fill() discarded")
                    case .error(let message):
                        Debug.info("Texture3D.fill() error \(message)")
                    case .success:
                        self.hsv = hsv
                    }
                })
        } catch {
            Debug.info(error.localizedDescription)
            processing = false
        }
    }

}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
