//
//  syn.progress.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 04/02/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynGeometry: Syn {
    var reflex: [Reflex] = []
    override init(parent: NodeUI) {
        super.init(parent: parent)
        reflex = [
            Triad(parent: self),
            Potatoes(parent: self),
            BarColor(parent: self),
            Shades(parent: self),
            Disco(parent: self),
        ]
        
    }
    override func detach() {
        for r in reflex {
            r.detach()
        }
        reflex.removeAll()
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        let g = Graphics(image: output, clear: Color(hex:"000020"))
        for r in reflex {
            r.draw(graphics: g, rect: output.bounds, time: time, audio: audio, power: 1)
        }
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
