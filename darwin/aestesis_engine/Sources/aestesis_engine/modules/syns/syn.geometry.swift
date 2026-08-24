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
            Disco(parent: self)
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
        time: Double, dtime: Double, fps: Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        let g = Graphics(image: output, clear: Color(hex: "000020"))
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
class SimpleTriangleText: Reflex {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override init(parent: NodeUI) {
        super.init(parent: parent)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func detach() {
        super.detach()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func draw(
        graphics g: Graphics, rect: Rect, time: Double, audio: AudioAnalyzer.Info, power: Double
    ) {
        let path = Path()
        let paint = Paint(
            parent: self, mode: .fill, blend: .copy, color: .aeGreen)
        var p: [Point] = [Point](repeating: .zero, count: 3)
        let t = time * 0.1
        for i in 0..<3 {
            p[i] = Point(
                x: 0.5 * cos(2.0 * Double.pi * Double(i) / 3.0 + t) + 0.5,
                y: 0.5 * sin(2.0 * Double.pi * Double(i) / 3.0 + t) + 0.5 )
        }
        path.append(Path.Segment.moveTo(p[0] * rect.size))
        path.append(Path.Segment.lineTo(p[1] * rect.size))
        path.append(Path.Segment.lineTo(p[2] * rect.size))
        path.append(Path.Segment.close())
        g.draw(path, paint)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
