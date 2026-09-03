//
//  syn.frequency.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 09/02/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynFrequency: Syn {
    var t = ß.rnd * 10000
    override init(parent: NodeUI) {
        super.init(parent: parent)
    }
    override func detach() {
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps: Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let vp = viewport else { return }
        t -= dtime * Double(audio.peak)
        let g = Graphics(image: output, clear: .black, viewport: vp)
        let ffta = Array(audio.fft.amplitude[0...255])
        var vertices = [Vertice]()
        var center = output.bounds.center
        var r = output.bounds.size.length * 40
        let c = Color.white
        var i = 0
        for a in ffta {
            let vi = Double(i) / Double(ffta.count)
            let vr = Double(ffta[i]) * r
            let vr0 = vr * 0.1
            let rz = vi * Double.pi * 0.5
            let cc = c.with(a: 0.01)
            func vert(angle: Double) -> [Vertice] {
                return [
                    Vertice(
                        position: Vec3(center + Point(angle: angle - d, radius: vr0)),
                        color: cc),
                    Vertice(
                        position: Vec3(center + Point(angle: angle, radius: vr)), color: c),
                    Vertice(
                        position: Vec3(center + Point(angle: angle + d, radius: vr0)),
                        color: cc),
                ]
            }
            vertices.append(contentsOf: vert(angle: rz))
            vertices.append(contentsOf: vert(angle: Double.pi - rz))
            vertices.append(contentsOf: vert(angle: Double.pi + rz))
            vertices.append(contentsOf: vert(angle: -rz ))
            i += 1
        }
        g.draw(triangle: vertices, blend: .alpha)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
