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
        for x in 0..<256 {
            var v = Double(x) / 255.0
            pixels[x] = Color(r: v, g: 0, b: 0).bgra
            pixels[x + 256] = Color(r: 0, g: v, b: 0).bgra
            pixels[x + 512] = Color(r: 0, g: 0, b: v).bgra
        }
        palette.set(pixels: pixels)
        let g = EffectGraphics(image: output, viewport: vp)
        g.paletizeRgb(
            rect: output.bounds, source: input, from: input.bounds.crop(output.bounds.ratio),
            palette: palette)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
