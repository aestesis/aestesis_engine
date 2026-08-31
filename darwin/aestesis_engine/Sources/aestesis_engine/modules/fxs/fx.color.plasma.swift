//
//  fx.color.plasma.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 14/05/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxColorPlasma: Fx {
    lazy var sprite: Bitmap = Bitmap(
        parent: self, path: "assets/Sprites/sprite-add.png", bundle: Bundle.aestesis)
    let size = 16
    var lut: Texture3D?
    var particles: [Particle] = []
    var volume: [Double] = [Double](repeating: 0, count: 3)
    var eq: [Double] = []
    override init(parent: NodeUI) {
        super.init(parent: parent)
        lut = Texture3D(parent: self, size: size, renderTarget: true)
        let n = 8
        for i in 0..<8 {
            let v = Double(i) / Double(n)
            particles.append(Particle(color: Color(h: v, s: 0.5, l: 0.5)))
            eq.append(0.0)
        }
    }
    override func detach() {
        lut?.detach()
        lut = nil
        sprite.detach()
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
        updateEq(audio:audio)
        renderLut(dtime: dtime)
        let g = Graphics(image: output, viewport: vp)
        if level < 1 {
            g.draw(rect: output.bounds, image: input, from: input.bounds.crop(output.bounds.ratio))
        }
        g.draw(
            rect: output.bounds, image: input, from: input.bounds.crop(output.bounds.ratio),
            lut: lut, blend: .alpha, color: Color(a: level, rgb: Color.white.rgb))
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    func updateEq(audio:AudioAnalyzer.Info) {
        var d = 4
        var j = 0
        for i in 0..<eq.count {
            var v = 0.0
            for _ in 0..<d {
                v += Double(audio.fft.amplitude[j])
                j += 1
            }
            d *= 2
            eq[i] = eq[i] * 0.2 + v * 0.8
        }
    }
    func renderLut(dtime: Double) {
        guard let vp = viewport, let lut = lut else {
            return
        }
        var pinfo: [Particle.Info] = []
        for i in 0..<particles.count {
            pinfo.append(particles[i].compute(dtime: dtime, level: eq[i]))
        }
        let r = lut.size.z
        let size = Size(lut.size.x, lut.size.y)
        for z in 0..<Int(lut.size.z) {
            let zz = Double(z)
            let g = Graphics(texture: lut, depthPlane: z, clear: .black, viewport: vp)
            var i = 0
            for p in pinfo {
                let s = r * p.size
                if s > 0 {
                    g.draw(
                        rect: Rect(center: p.xy * size, size: Size(s, s)), image: sprite,
                        blend: .add, color: particles[i].color)
                }
                i += 1
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct Particle {
    internal init(color: Color) {
        self.position = Parameter3(complexity: 3)
        self.color = color
    }

    let position: Parameter3
    let color: Color
    var time: Double = 0.0

    mutating func compute(dtime: Double, level: Double) -> Info {
        let l = level * 5
        time += dtime * (0.01 + l)
        return Info(position: position.sin(time) * 0.6 + 0.5, size: 0.5, color: color)
    }

    struct Info {
        internal init(position: Vec3, size: Double, color: Color) {
            self.position = position
            self.size = size
            self.color = color
        }

        let position: Vec3
        let size: Double
        let color: Color

        var xy: Point {
            return Point(position.x, position.y)
        }
        var z: Double {
            return position.z
        }

    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
