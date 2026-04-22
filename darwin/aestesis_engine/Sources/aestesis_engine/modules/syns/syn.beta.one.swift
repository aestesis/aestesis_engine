//
//  syn.shadow.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 04/02/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynBetaOne: Syn {
    var eq = EQH()
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
        let r = output.size.ratio
        let g = Graphics(image: output, clear: Color(a: 1, l: 0.2))
        let l = output.size.height * 1.2
        eq.low = eq.low * 0.5 + Double(audio.eq.low) * 0.5
        eq.medium = eq.medium * 0.5 + Double(audio.eq.medium) * 0.5
        eq.high = eq.high * 0.5 + Double(audio.eq.high) * 0.5
        let sb = eq.low * l
        let sm = eq.medium * l
        let st = eq.high * l
        g.fill(
            rect: output.bounds.point(px: 0.5, py: 0.5).rect(w: sb * r, h: sb), blend: .add,
            color: Color(a: 1, l: 0.2))
        g.fill(
            rect: output.bounds.point(px: 0.5, py: 0.5).rect(w: st * r, h: st), blend: .add,
            color: Color(a: 1, l: 0.2))
        g.fill(
            rect: output.bounds.point(px: 0.5, py: 0.5).rect(w: sm * r, h: sm), blend: .add,
            color: Color(a: 1, l: 0.2))
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
