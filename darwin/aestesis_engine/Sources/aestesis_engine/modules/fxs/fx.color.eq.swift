//
//  fx.color.eq.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 27/04/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxColorEq: Fx {
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
        let g = Graphics(image: output)
        eq.low = eq.low * 0.5 + Double(audio.eq.low) * 0.5
        eq.medium = eq.medium * 0.5 + Double(audio.eq.medium) * 0.5
        eq.high = eq.high * 0.5 + Double(audio.eq.high) * 0.5
        if level == 0 {
            g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio))
        } else {
            let c = Color(a:1,r:eq.low*2,g:eq.medium*4,b:eq.high*6).saturated
            if level == 1 {
                g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),color:Color(a:1,rgb:c.rgb*2))
            } else {
                let il = 1 - level
                g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),color:Color(a:1,l:il))
                g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),blend:.add, color:Color(a:1,rgb:c.rgb*2*level))
            }
        }
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
