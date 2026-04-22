//
//  fx.color.rgb.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 14/05/2024.
//

import Foundation
import aestesis_alib

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxColorRGB: Fx {
    var eq = EQH()
    override init(parent: NodeUI) {
        super.init(parent: parent)
    }
    override func detach() {
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, input: Bitmap, output: Bitmap, level: Double,
        _ fn: @escaping () -> Void
    ) {
        eq.low = eq.low * 0.5 + Double(audio.eq.low) * 0.5
        eq.medium = eq.medium * 0.5 + Double(audio.eq.medium) * 0.5
        eq.high = eq.high * 0.5 + Double(audio.eq.high) * 0.5
        let g = EffectGraphics(image: output)
        let t = time
        let d = 2*ß.π/3
        let s = input.bounds.diagonal*0.05*level
        let ro = Point(angle: t, radius: s*eq.low*2)
        let bo = Point(angle: t+d, radius: s*eq.medium*4)
        let go = Point(angle: t+2*d, radius: s*eq.high*6)
        g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),redOffset:ro,greenOffset:go,blueOffset:bo)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
