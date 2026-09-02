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
    lazy var palette: Bitmap = Bitmap(
        parent: self, size: Size(256, 3))
    var eq: [EQH] = [EQH](repeating: EQH(), count: 256)
    override init(parent: NodeUI) {
        super.init(parent: parent)
    }
    override func detach() {
        palette.detach()
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
        var pixels = [UInt32](repeating: 0, count: 256 * 3)
        for _ in 0..<4 {
            eq.removeFirst()
            eq.append(eq.last! * 0.5 + EQH(audio.eq) * 0.6)
        }
        let t = time * 0.01
        let tr = 0.0  // t.remainder(dividingBy: 1)
        let tg = 0.333  // (t+0.333).remainder(dividingBy: 1)
        let tb = 0.666  //(t+0.666).remainder(dividingBy: 1)
        let red = Color(h: tr, s: 1, b: 1)
        for x in 0..<256 {
            var v = (Double(x) / 255.0) * 0.5 + 0.5
            pixels[x] =
                (Color(h: tr, s: 1, b: v) * eq[x].low).saturated.with(a: 1).bgra
            pixels[x + 256] =
                (Color(h: tg, s: 1, b: v) * eq[x].medium).saturated.with(a: 1).bgra
            pixels[x + 512] =
                (Color(h: tb, s: 1, b: v) * eq[x].high).saturated.with(a: 1).bgra
        }
        palette.set(pixels: pixels)
        let g = EffectGraphics(image: output, viewport: vp)
        if level < 1 {
            g.draw(rect: output.bounds, image: input, from: input.bounds.crop(output.bounds.ratio))
            g.paletizeRgb(
                rect: output.bounds, source: input, from: input.bounds.crop(output.bounds.ratio),
                palette: palette, blend: .alpha, color: Color(a: level, l: 1))
        } else {
            g.paletizeRgb(
                rect: output.bounds, source: input, from: input.bounds.crop(output.bounds.ratio),
                palette: palette)
        }
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
