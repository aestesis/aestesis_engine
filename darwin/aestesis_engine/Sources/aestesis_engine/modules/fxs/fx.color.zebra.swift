//
//  fx.color.zebra.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 14/05/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxColorZebra: Fx {
    lazy var sprite: Bitmap = Bitmap(
        parent: self, path: "assets/Sprites/sprite-add.png", bundle: Bundle.aestesis)
    let size = 16
    var lut: Texture3D?
    override init(parent: NodeUI) {
        super.init(parent: parent)
        lut = Texture3D(parent: self, size: size, renderTarget: true)
    }
    override func detach() {
        lut?.detach()
        lut = nil
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps: Double, audio: AudioAnalyzer.Info, input: Bitmap,
        output: Bitmap, level: Double,
        _ fn: @escaping () -> Void
    ) {
        guard let vp = viewport else {
            return
        }
        renderLut(dtime: dtime, level: level)
        let g = Graphics(image: output, viewport: vp)
        if level < 1 {
            g.draw(rect: output.bounds, image: input, from: input.bounds.crop(output.bounds.ratio))
        }
        g.draw(
            rect: output.bounds, image: input, from: input.bounds.crop(output.bounds.ratio),
            lut: lut, blend: .alpha, color: Color(a: level, rgb: Color.white.rgb))
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    var t = 0.0
    func renderLut(dtime: Double, level: Double) {
        guard let vp = viewport, let lut = lut else {
            return
        }
        // TODO: do someting
        let size = Size(lut.size.x, lut.size.y)
        t += dtime * 0.1
        let l = level
        let il = 1 - l
        let hr = t.truncatingRemainder(dividingBy: 1)
        let hg = (t + 0.333).truncatingRemainder(dividingBy: 1)
        let hb = (t + 0.666).truncatingRemainder(dividingBy: 1)
        let red: Color = Color.red * il + Color(a: 1, h: hr, s: 1, b: 1) * l
        let green: Color = Color.green * il + Color(a: 1, h: hg, s: 1, b: 1) * l
        let blue: Color = Color.blue * il + Color(a: 1, h: hb, s: 1, b: 1) * l
        for z in 0..<Int(lut.size.z) {
            let zz = Double(z)
            let g = Graphics(texture: lut, depthPlane: z, clear: .black, viewport: vp)
            let b = blue * zz / (lut.size.z - 1)
            let colors = ColorRect(
                topLeft: b, topRight: (red + b).saturated,
                bottomRight: (red + green + b).saturated,
                bottomLeft: (green + b).saturated)
            g.fill(rect: Rect(o: .zero, s: size), colors: colors)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
