//
//  syn.radial.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 03/02/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynRadial: Syn {
    var fountain: WavesFountain?
    var shadow: WavesShadow?
    override init(parent: NodeUI) {
        super.init(parent: parent)
        fountain = WavesFountain(parent: self, size: Size(1024, 576))
        shadow = WavesShadow(parent: self, size: Size(1024, 576))
    }
    override func detach() {
        fountain?.detach()
        fountain = nil
        shadow?.detach()
        shadow = nil
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let fountain = fountain, let ofountain = fountain.output, let shadow = shadow,
              let oshadow = shadow.output
        else { return }
        fountain.render(time, fps:fps, audio: audio) {}
        shadow.render(time, fps:fps, audio: audio) { [weak self] in
            guard let self=self, self.attached, output.attached else { return }
            let g = Graphics(image: output)
            g.draw(
                rect: output.bounds, image: oshadow, from: oshadow.bounds.crop(output.bounds.ratio),
                color: Color(a: 1, l: 0.6))
            g.draw(
                rect: output.bounds, image: ofountain, from: ofountain.bounds.crop(output.bounds.ratio),
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
