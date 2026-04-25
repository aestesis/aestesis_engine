//
//  costal.waves.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 10/02/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynCoastalWaves: Syn {
    var ghost: Bitmap?
    var line: Bitmap?
    var sprite: Bitmap?
    var eq = [EQ]()
    var eq0: EQ = EQ()
    var peaks = [Double]()
    var peak = 0.0
    var particles = [Particle]()
    override init(parent: NodeUI) {
        super.init(parent: parent)
        io {
            self.sprite = Bitmap(
                parent: self, path: "assets/Sprites/sprite-blanc.png",
                bundle: Bundle.aestesis
            self.ghost = Bitmap(
                parent: self, path: "assets/ghosts/ghost-01.png", bundle: Bundle.aestesis
            )
            self.line = Bitmap(parent: self, size: Size(512, 1))
        }
    }
    override func detach() {
        ghost?.detach()
        line?.detach()
        sprite?.detach()
        self.ghost = nil
        self.line = nil
        self.sprite = nil
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps: Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        let g = Graphics(image: output)

        process(audio: audio)

        drawLines(g: g, size: output.size)
        drawGhostBass(g: g, size: output.size)
        drawGhostTreeble(g: g, size: output.size)
        drawGhostMedium(g: g, size: output.size)
        drawSprite(g: g, size: output.size, audio: audio)

        g.onDone { [weak self] ok in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    func process(audio: AudioAnalyzer.Info) {
        eq0 = eq0 * 0.9 + audio.eq * 0.2
        eq.enqueue(EQ(low: eq0.low * 1.5, medium: eq0.medium * 2, high: eq0.high * 3))
        if eq.count > 16 {
            let _ = eq.dequeue()
        }
        peak = peak * 0.9 + Double(audio.peak) * 0.1
        peaks.enqueue(Double(audio.peak))
        if peaks.count > 64 {
            let _ = peaks.dequeue()
        }
    }
    func drawSprite(g: Graphics, size: Size, audio: AudioAnalyzer.Info) {
        guard let sprite = sprite else { return }
        let center = Rect(origin: .zero, size: size).center
        let pm = size.length / 1200
        let life = 3.0
        let t = ß.time
        let ot = ß.time - life
        while particles.count > 0 && particles[0].birth < ot {
            let _ = particles.dequeue()
        }
        var imax: Int = 0
        var max: Float = 0
        for i in 0..<256 {
            let v = abs(audio.samples[i])
            if v > max {
                imax = i
                max = v
            }
        }
        if max > 0 {
            let c = Color(h: ß.rnd, s: 0.25, b: 1)
            let dx = size.width / 256.0
            let x = (Double(imax) + ß.rnd) * dx
            max = min(max, 3)
            particles.enqueue(
                Particle(
                    position: Point(x, (ß.rnd - 0.5) * Double(max) * center.y + center.y),
                    power: Double(max) * 3, color: c))
        }
        if particles.count > 0 {
            var ps = [PointSprite]()
            for p in particles {
                let lived = (t - p.birth) / life
                let power = p.power * lived * pm
                let alpha = Signal(1 - lived).pow(0.4).value
                let position = p.position.lerp(Point(p.position.x, center.y), coef: lived)
                ps.append(
                    PointSprite(
                        position: position, scale: power,
                        color: Color(a: 1, rgb: p.color.lerp(to: Color.white, coef: lived) * alpha))
                )
            }
            g.draw(sprites: ps, image: sprite, blend: .add)
        }
    }
    func drawGhostMedium(g: Graphics, size: Size) {
        guard let ghost = ghost else { return }
        let center = Rect(origin: .zero, size: size).center
        let steps = 256
        var vv = [Vertice]()
        var x = 0.0
        let dx = size.width / Double(steps)
        var a0 = ß.time
        let da0 = ß.π * 6.06151 / Double(steps)
        var a1 = ß.time * 0.6785981
        let da1 = ß.π * 2 / Double(steps)
        var a2 = -ß.time * 0.11141656561
        let da2 = ß.π * 3.167115415441 / Double(steps)
        let r = center.y * 0.8
        var u = 0.0
        let du = 2.0 / Double(steps)
        let c0 = Color.aeViolet
        let di = 1.0 / Double(steps + 1)
        for i in 0...steps {
            let rr = medium(Double(i) * di) * r
            var y0 =
                (sin(a0 * 1.017611) * 0.5 + sin(a0 * 0.3767133325411) * 0.3 + sin(a0 * 1.2651434515)
                    * 0.2) * rr
            var y1 =
                (sin(a0 * 1.316651561) * sin(a0 * 0.127615671) * 0.5 + sin(a0 * 0.1941435) * 0.3
                    + sin(a0 * 1.82454541) * 0.2) * rr
            y0 *= (sin(a1 * 3.1161656157) + sin(a1 * 5.1216516561)) * 0.5
            y1 *= (sin(a1 * 2.1611656157) + sin(a1 * 3.1916516561)) * 0.5
            let c = c0 * max(min(((sin(a2) + sin(a2 * 0.1945145)) * 0.25 + 0.5), 1), 0)
            let y = center.y
            vv.append(Vertice(position: Vec3(x: x, y: y0 + y), uv: Point(u, 1), color: c))
            vv.append(Vertice(position: Vec3(x: x, y: y1 + y), uv: Point(u, 0), color: c))
            x += dx
            a0 += da0
            a1 += da1
            a2 += da2
            u += du
        }
        g.draw(strip: vv, image: ghost, sampler: "sampler.mirror.clamp", blend: .add)
    }
    func drawGhostTreeble(g: Graphics, size: Size) {
        guard let ghost = ghost else { return }
        let center = Rect(origin: .zero, size: size).center
        let steps = 256
        var vv = [Vertice]()
        var x = 0.0
        let dx = size.width / Double(steps)
        var a0 = ß.time
        let da0 = ß.π * 6.015161 / Double(steps)
        var a1 = ß.time * 0.65981
        let da1 = ß.π * 2 / Double(steps)
        var a2 = -ß.time * 0.11656561
        let da2 = ß.π * 3.215415441 / Double(steps)
        let r = center.y * 0.8
        var u = 0.0
        let du = 2.0 / Double(steps)
        let c0 = Color.aeGreen
        let di = 1.0 / Double(steps + 1)
        for i in 0...steps {
            let rr = treeble(Double(i) * di) * r
            var y0 =
                (sin(a0 * 1.117615) * 0.5 + sin(a0 * 0.233325411) * 0.3 + sin(a0 * 1.81434515) * 0.2)
                * rr
            var y1 =
                (sin(a0 * 1.216651561) * sin(a0 * 0.317615671) * 0.5 + sin(a0 * 0.12141435) * 0.3
                    + sin(a0 * 1.292454541) * 0.2) * rr
            y0 *= (sin(a1 * 3.231656157) + sin(a1 * 5.2216516561)) * 0.5
            y1 *= (sin(a1 * 2.211656157) + sin(a1 * 3.2116516561)) * 0.5
            let c = c0 * max(min(((sin(a2) + sin(a2 * 0.12545145)) * 0.25 + 0.5), 1), 0)
            let y = center.y
            vv.append(Vertice(position: Vec3(x: x, y: y0 + y), uv: Point(u, 1), color: c))
            vv.append(Vertice(position: Vec3(x: x, y: y1 + y), uv: Point(u, 0), color: c))
            x += dx
            a0 += da0
            a1 += da1
            a2 += da2
            u += du
        }
        g.draw(strip: vv, image: ghost, sampler: "sampler.mirror.clamp", blend: .add)
    }
    func drawGhostBass(g: Graphics, size: Size) {
        guard let ghost = ghost else { return }
        let center = Rect(origin: .zero, size: size).center
        let steps = 256
        var vv = [Vertice]()
        var x = 0.0
        let dx = size.width / Double(steps)
        var a0 = ß.time
        let da0 = ß.π * 6 / Double(steps)
        var a1 = ß.time * 0.5981
        let da1 = ß.π * 2 / Double(steps)
        var a2 = -ß.time * 0.1656561
        let da2 = ß.π * 3.15415441 / Double(steps)
        let r = center.y * 0.8
        var u = 0.0
        let du = 2.0 / Double(steps)
        let c0 = Color.aeOrange
        let di = 1.0 / Double(steps + 1)
        for i in 0...steps {
            let rr = bass(Double(i) * di) * r
            var y0 = (sin(a0) * 0.5 + sin(a0 * 0.33325411) * 0.3 + sin(a0 * 1.1434515) * 0.2) * rr
            var y1 =
                (sin(a0 * 1.16651561) * sin(a0 * 0.17615671) * 0.5 + sin(a0 * 0.141435) * 0.3 + sin(
                    a0 * 1.2454541) * 0.2) * rr
            y0 *= (sin(a1 * 3.1656157) + sin(a1 * 5.16516561)) * 0.5
            y1 *= (sin(a1 * 2.1656157) + sin(a1 * 3.16516561)) * 0.5
            let c = c0 * max(min(((sin(a2) + sin(a2 * 0.1545145)) * 0.25 + 0.5), 1), 0)
            let y = center.y
            vv.append(Vertice(position: Vec3(x: x, y: y0 + y), uv: Point(u, 1), color: c))
            vv.append(Vertice(position: Vec3(x: x, y: y1 + y), uv: Point(u, 0), color: c))
            x += dx
            a0 += da0
            a1 += da1
            a2 += da2
            u += du
        }
        g.draw(strip: vv, image: ghost, sampler: "sampler.mirror.clamp", blend: .add)
    }
    func drawLines(g: Graphics, size: Size) {
        guard let line = line else { return }
        var db = [UInt8](repeating: 0, count: 512)
        var dr = 1.0 / 64
        var r = dr
        let fill: (Double, Double) -> Void = { r0, r1 in
            if r1 > r0 && r0 <= 1 {
                let x0 = max(Int(r0 * Double(db.count - 1)), 0)
                let x1 = min(Int(r1 * Double(db.count - 1)), db.count - 1)
                for x in x0...x1 {
                    db[x] += 1
                }
            }
        }
        for i in 0..<64 {
            let ii = Double(i) / 63
            let pr = all(1 - ii) * dr * ((1 - ii) * 0.5 + 0.5)
            fill(r - pr, r + pr)
            if r > 1 {
                break
            }
            r += dr
            dr *= 1.04
        }
        var di = [UInt32]()
        var n = 0
        for b in db {
            let i = Int(Double(b) * (5 * (511 - Double(n)) / 512 + 2))
            di.append(UInt32((255 << 24) | (i << 16) | (i << 8) | i))
            n += 1
        }
        line.set(pixels: di)
        let h = size.height * 0.5
        g.draw(
            rect: Rect(x: 0, y: 0, w: size.w, h: h), image: line, color: Color.aeBlue,
            rotation: .anticlockwise)
        g.draw(
            rect: Rect(x: 0, y: h, w: size.w, h: h), image: line, color: Color.aeAqua,
            rotation: .clockwise)
    }
    func bass(_ p: Double) -> Double {
        let pd = (Double(eq.count - 1) - 0.001) * p
        let i = Int(pd)
        let d = pd - Double(i)
        if eq.count > 1 {
            return Double(eq[i].low) * (1 - d) + Double(eq[i + 1].low) * d
        } else if eq.count > 0 {
            return Double(eq[i].low)
        } else {
            return 0.0
        }
    }
    func medium(_ p: Double) -> Double {
        let pd = (Double(eq.count - 1) - 0.001) * p
        let i = Int(pd)
        let d = pd - Double(i)
        if eq.count > 1 {
            return Double(eq[i].medium) * (1 - d) + Double(eq[i + 1].medium) * d
        } else if eq.count > 0 {
            return Double(eq[i].medium)
        } else {
            return 0.0
        }
    }
    func treeble(_ p: Double) -> Double {
        let pd = (Double(eq.count - 1) - 0.001) * p
        let i = Int(pd)
        let d = pd - Double(i)
        if eq.count > 1 {
            return Double(eq[i].high) * (1 - d) + Double(eq[i + 1].high) * d
        } else if eq.count > 0 {
            return Double(eq[i].high)
        } else {
            return 0.0
        }
    }
    func all(_ p: Double) -> Double {
        let pd = (Double(peaks.count - 1) - 0.001) * p
        let i = Int(pd)
        let d = pd - Double(i)
        if peaks.count > 1 {
            return Double(peaks[i]) * (1 - d) + Double(peaks[i + 1]) * d
        } else if peaks.count > 0 {
            return Double(peaks[i])
        } else {
            return 0.0
        }
    }
    struct Particle {
        var position: Point
        var power: Double
        var birth: Double
        var color: Color
        init(position: Point, power: Double, color: Color, birth: Double = ß.time) {
            self.position = position
            self.power = power
            self.color = color
            self.birth = birth
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

// old one from waves
