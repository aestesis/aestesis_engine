//
//  SynMetaballs.swift
//  AestesisAlib
//
//  Created by renan jegouzo on 30/01/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynSunRa: Syn {
    var kiss: WavesKiss?
    var spline: WavesSpline?
    override init(parent: NodeUI) {
        super.init(parent: parent)
        kiss = WavesKiss(parent: self, size: Size(1024, 576))
        spline = WavesSpline(parent: parent, size: Size(1024, 576))
    }
    override func detach() {
        kiss?.detach()
        spline?.detach()
        kiss = nil
        spline = nil
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let kiss = kiss, let spline = spline else { return }
        kiss.render(time, fps:fps, audio: audio) {}
        spline.render(time, fps:fps, audio: audio) { [weak self] in
            guard let self=self, self.attached else { return }
            bg { [weak self] in
                guard let self=self, self.attached, output.attached else { return }
                guard let okiss = kiss.output, let ospline = spline.output else { return }
                let g = Graphics(image: output)
                g.fill(rect:output.bounds, blend: .sub, color: .white*0.3)
                g.draw(
                    rect: output.bounds, image: ospline, from: ospline.bounds.crop(output.bounds.ratio),
                    blend: .add, color: Color(a: 1, l: 0.5))
                g.draw(
                    rect: output.bounds, image: okiss, from: okiss.bounds.crop(output.bounds.ratio),
                    blend: .sub, color: Color(a: 1, l: 0.6))
                g.onDone { [weak self] ok in
                    guard let self = self, self.attached else { return }
                    fn()
                }
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
