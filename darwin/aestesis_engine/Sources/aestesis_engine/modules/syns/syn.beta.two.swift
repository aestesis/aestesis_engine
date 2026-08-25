//
//  syn.frequency.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 09/02/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynBetaTwo: Syn {
    var ffta: [Double] = [Double](repeating: 0, count: 256)
    override init(parent: NodeUI) {
        super.init(parent: parent)
    }
    override func detach() {
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps: Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        let g = Graphics(image: output, clear: Color(a: 1, l: 0))
        var si = 0
        for i in 0..<ffta.count {
            let ni = i / 18 + 1
            var v = 0.0
            for j in 0..<ni {
                v += Double(audio.fft.amplitude[si])
                si += 1
            }
            ffta[i] = ffta[i] * 0.2 + v * 0.8
        }
        let c = output.bounds.center
        var i = 0
        for a in ffta {
            let vi = Double(i) / Double(ffta.count)
            let color = Color(a: 0.1, h: vi, s: 0.5, b: 0.5)
            let sz = output.bounds.size * a * 20.0
            g.fill(rect: Rect(center: c, size: sz), blend: .add, color: color)
            i += 1
        }

        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
