//
//  syn.trash.swift
//  flutter_alib
//
//  Created by renan jegouzo on 01/02/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynMental: Syn {
    var mental: WavesMental?
    var shadow: WavesShadow?
    override init(parent: NodeUI) {
        super.init(parent: parent)
        mental = WavesMental(parent: self, size: Size(1024, 576))
        shadow = WavesShadow(parent: self, size: Size(1024, 576))
    }
    override func detach() {
        mental?.detach()
        mental = nil
        shadow?.detach()
        shadow = nil
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let mental = mental, let omental = mental.output, let shadow = shadow,
              let oshadow = shadow.output
        else { return }
        mental.render(time, fps:fps, audio: audio) {}
        shadow.render(time, fps:fps, audio: audio) {
            let g = Graphics(image: output)
            g.draw(
                rect: output.bounds, image: oshadow, from: oshadow.bounds.crop(output.bounds.ratio),
                color: Color(a: 1, l: 0.6))
            g.draw(
                rect: output.bounds, image: omental, from: omental.bounds.crop(output.bounds.ratio),
                blend: .add, color: Color(a: 1, l: 0.5))
            g.onDone { [weak self] ok in
                guard let self = self, self.attached else { return }
                fn()
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
