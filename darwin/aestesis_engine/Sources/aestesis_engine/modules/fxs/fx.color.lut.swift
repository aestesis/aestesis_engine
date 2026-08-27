//
//  fx.color.pulse.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 14/05/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxColorLut: Fx {
    let size = 8
    var lut: Texture3D?
    var cval: Double = 0
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let s = Double(size-1)
        var data: [UInt32] = []
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let c = Color(r: Double(z) / s, g: Double(y) / s, b: Double(x) / s)
                    data.append(c.bgra)
                }
            }
        }
        lut = Texture3D(parent: self, size: size, pixels: data, renderTarget: true)
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
        renderLut(time: time, audio: audio)
        let g = Graphics(image: output, viewport: vp)
        //let c = Color(a: 1, l: (1 - level) + e * 1.5 * level)
        g.draw(
            rect: output.bounds, image: input, from: input.bounds.crop(output.bounds.ratio),
            lut: lut)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    func renderLut(time: Double, audio: AudioAnalyzer.Info) {
        guard let vp = viewport, let lut = lut else {
            return
        }
        let center = Point(lut.size.x, lut.size.y) * 0.5
        let colors : [Color] = [.aeGreen, .aeOrange]
        let rayon = center.x * 0.5
        var ic = 0
        for z in 0..<Int(lut.size.z) {
            let c = colors[ic]
            let g = Graphics(texture: lut, depthPlane: z, clear: c, viewport: vp)
            g.fill(
                rect: Rect(center: center, size: Size(rayon, rayon)), color: .aeMagenta)
            ic = (ic + 1) % colors.count
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
