//
//  syn.equinox.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 02/02/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynEquinox: Syn {
    var kiss: WavesKiss?
    var memo: WavesMemorium?
    override init(parent: NodeUI) {
        super.init(parent: parent)
        kiss = WavesKiss(parent: self, size: Size(1024, 576))
        memo = WavesMemorium(parent: parent, size: Size(1024, 576))
    }
    override func detach() {
        kiss?.detach()
        memo?.detach()
        kiss = nil
        memo = nil
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let kiss = kiss, let memo = memo else { return }
        kiss.render(time, fps:fps, audio: audio) {}
        memo.render(time, fps:fps, audio: audio) {
            guard let okiss = kiss.output, let omemo = memo.output else { return }
            let g = Graphics(image: output)
            g.draw(
                rect: output.bounds, image: okiss, from: okiss.bounds.crop(output.bounds.ratio),
                color: Color(a: 1, l: 0.6))
            g.draw(
                rect: output.bounds, image: omemo, from: omemo.bounds.crop(output.bounds.ratio),
                blend: .difference, color: Color(a: 1, l: 0.6))
            g.onDone { [weak self] ok in
                guard let self = self, self.attached else { return }
                fn()
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
