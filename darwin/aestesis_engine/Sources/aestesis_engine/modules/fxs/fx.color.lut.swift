//
//  fx.color.pulse.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 14/05/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxColorLut: Fx {
    lazy var sprite: Bitmap = Bitmap(
        parent: self, path: "assets/Sprites/sprite-add.png", bundle: Bundle.aestesis)
    let size = 4
    var lut: Texture3D?
    var cval: Double = 0
    var particles: [Particle] = []
    override init(parent: NodeUI) {
        super.init(parent: parent)
        /*
        let s = Double(size - 1)
        var data: [UInt32] = []
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let c = Color(r: Double(z) / s, g: Double(y) / s, b: Double(x) / s)
                    data.append(c.bgra)
                }
            }
        }
         */
        lut = Texture3D(parent: self, size: size, renderTarget: true)
        //sprite = Bitmap(
        //    parent: self, path: "assets/Sprites/sprite-add.png", bundle: Bundle.aestesis)
        particles.append(Particle(color: .aeMagenta))
        particles.append(Particle(color: .aeOrange))
        particles.append(Particle(color: .aeViolet))     
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
        renderLut(time: time, audio: audio)
        let g = Graphics(image: output, viewport: vp)
        //let c = Color(a: 1, l: (1 - level) + e * 1.5 * level)
        g.draw(
            rect: output.bounds, image: input, from: input.bounds.crop(output.bounds.ratio),
            lut: lut)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    func renderLut(time: Double, audio: AudioAnalyzer.Info) {
        guard let vp = viewport, let lut = lut else {
            return
        }
        let pinfo = particles.map { $0.compute(time: time) }
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
        self.size = Parameter(complexity: 3)
        self.color = color
    }

    let position: Parameter3
    let size: Parameter
    let color: Color

    func compute(time: Double) -> Info {
        return Info(
            position: (position.sin(time) + 0.5), size: size.sin(time) * 0.5 + 0.5 + 0.5, color: color)
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
