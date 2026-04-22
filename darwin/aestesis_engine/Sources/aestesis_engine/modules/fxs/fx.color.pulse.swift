//
//  fx.color.pulse.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 14/05/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxColorPulse: Fx {
    var cval:Double = 0
    var e:Double = 0
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
        e = e * 0.8
        if audio.envelope>cval {
            cval = audio.envelope*1.001
            e = 1
        } else {
            cval *= 0.995
        }

        let g = Graphics(image: output)
        let c = Color(a:1,l:(1 - level) + e*1.5*level)
        g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),color:c)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
