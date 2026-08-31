//
//  fx.mask.boxes.swift
//  aestesis_engine
//
//  Created by renan jegouzo on 31/08/2026.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxMaskBoxes: Fx {
    static let count = 40
    var boxes:[MaskBox] = []
    var eq: [Double] = [Double](repeating: 0.0, count: count)

    override init(parent: NodeUI) {
        super.init(parent: parent)
        for _ in 0..<Self.count {
            boxes.append(MaskBox())
        }
    }
    override func detach() {
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps: Double, audio: AudioAnalyzer.Info, input: Bitmap,
        output: Bitmap, level: Double,
        _ fn: @escaping () -> Void
    ) {
        guard let vp = viewport else {
            return
        }
        updateEq(audio: audio)
        let g = Graphics(image: output, clear: .black, viewport: vp)
        if level<1 {
            g.draw(
                rect: output.bounds, image: input,
                from: input.bounds.crop(output.bounds.ratio),
                color: Color(l:(1-level))
            )
        }
        for i in 0..<boxes.count {
            boxes[i].time += dtime * (0.01 + eq[i]) * 10
            let b = boxes[i]
            g.draw(
                rect: b.bound(from: output.bounds), image: input,
                from: b.bound(from: input.bounds.crop(output.bounds.ratio)),
                blend: .add, color: Color(l:0.5*level)
            )
        }
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    func updateEq(audio: AudioAnalyzer.Info) {
        var d = 4
        var j = 0
        for i in 0..<eq.count {
            var v = 0.0
            for _ in 0..<d {
                v += Double(audio.fft.amplitude[j])
                j += 1
            }
            d += 2
            eq[i] = eq[i] * 0.2 + v * 0.8
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct MaskBox {
    var pposition = Parameter2(complexity: 3)
    var size = ß.rnd * 0.3 + 0.15
    var ratio = ß.rnd * 3 + 0.2
    var time = ß.rnd * 10000
    var position: Point {
        return pposition.sin(time) * Point(0.5, 0.5) + Point(0.5, 0.5)
    }
    func bound(from: Rect) -> Rect {
        return Rect(center: from.origin + position * from.size, size: (from.size * size).crop(ratio))
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
