//
//  syn.color.swift
//  flutter_alib
//
//  Created by renan jegouzo on 22/04/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynColor: Syn {
    var fft:[Double] = [Double](repeating: 0, count: 256)
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
        var c:Color = Color(a:1,l:0)
        for i in stride(from: 0, to: 255, by: 1) {
            fft[i] = (fft[i] + Double(audio.fft.amplitude[i])) * 0.5
            let a:Double = 1 + Double(i) / 32
            let h:Double = (Double(i)/256).truncatingRemainder(dividingBy: 1)
            let s:Double = 1
            let l:Double = fft[i]
            c = c + Color(a:1, h: h, s: s, l: l * a)
        }
        c = c * 0.1
        let g = Graphics(image: output, clear: c.saturated.with(a:1))
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
