//
//  syn.frequency.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 09/02/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynFrequency: Syn {
    override init(parent: NodeUI) {
        super.init(parent: parent)
    }
    override func detach() {
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        let g = Graphics(image: output, clear: Color(a: 1, l: 0.1))
        let ffta = Array(audio.fft.amplitude[0...255])
        let dx:Double = Double(output.size.width) / Double(ffta.count)
        var x:Double = 0
        let y = output.bounds.center.y
        
        var i = 0
        for a in ffta {
            let cf = Double(i)/Double(ffta.count)
            let c = Color.aeOrange.lerp(to: .aeGreen, coef: cf)
            let vy = y * Double(a*10)
            let vx = Double(a*100)
            g.fill(rect:Rect(x-vx,y-vy,10+vx*2,vy*2),blend: .add, color:(c * 0.7).with(a:1))
            x += dx
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
