import Foundation
import aestesis_alib
import simd

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynFluid2: Syn, @unchecked Sendable {
    static let count = 40
    var eq: [Double] = [Double](repeating: 0.0, count: count)
    var times: [Double] = [Double](repeating: 0.0, count: count)
    var sim: FluidSimulation?
    var size: SizeI = .zero
    var vSprite: Bitmap?
    var sprite: Bitmap?
    let spos = Parameter2(complexity: 4)
    let sdir = Parameter2(complexity: 4)
    var t = ß.rnd * 10000
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let ssize = 32
        vSprite = Bitmap(parent: self, size: Size(ssize, ssize), format: .float4)
        vSprite?.set(pixels: vSpriteData(size: ssize))
        sprite = Bitmap(parent: self, size: Size(32, 32))
        sprite?.set(pixels: spriteData(size: ssize))
    }
    override func detach() {
        sim?.detach()
        sim = nil
        vSprite?.detach()
        vSprite = nil
        sprite?.detach()
        sprite = nil
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps: Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let viewport = viewport else { return }
        let size = ((output.size * 0.25 / 8).round * 8).int
        if self.size != size {
            sim?.detach()
            sim = nil
            do {
                sim = try FluidSimulation(parent: self, size: size)
            } catch {
                Debug.info(error.localizedDescription)
                return
            }
            self.size = size
        }
        guard let sim = sim, let sprite = vSprite else { return }
        updateEq(audio: audio)

        let g0 = EffectGraphics(image: sim.texture, viewport: viewport)
        t += dtime * (Double(audio.eq.low) * 10 + 0.5)
        var tt = t
        var points: [Point] = []
        for e in eq {
            let position = spos.unity(tt)
            let direction = Point(
                angle: sdir.sin(tt).normalized.angle
                    + (position - spos.unity(tt + 0.1)).normalized.angle)
            let v = direction * 0.1
            let m = size.double.area / size.double.crop(1).aera
            let rsz = Size(0.3, 0.3) * m * e
            let r = Rect(center: position, size: rsz)
            let ri = Rect(center: Point(1 - position.x, position.y), size: rsz)
            g0.drawFloat(
                rect: Rect(center: r.center * size.double, size: r.size * size.double.crop(1)),
                image: sprite, color: Color(a: 1, r: v.x, g: v.y, b: 1))
            g0.drawFloat(
                rect: Rect(center: ri.center * size.double, size: ri.size * size.double.crop(1)),
                image: sprite, color: Color(a: 1, r: -v.x, g: v.y, b: 1))
            points.append(r.center)
            tt -= 1
        }
        var fence = g0.update()

        fence = sim.advance(dtime: dtime, fence: fence)
        g0.onDone { result in
            switch result {
            case .discarded:
                Debug.info("discarded")
            case .error(let message):
                Debug.info(message)
            case .success:
                break
            }
        }

        let g = EffectGraphics(image: output, clear: .red, viewport: viewport)
        if let fence = fence {
            g.wait(fence: fence)
        }
        do {
            let src = try output.copy()
            g.fluidAdvect(rect: output.bounds, source: src, fluid: sim.texture)
        } catch {
            Debug.info(error)
        }
        drawColor(graphics: g, size: output.size, points: points)
        g.onDone { result in
            switch result {
            case .discarded:
                Debug.info("discarded")
            case .error(let message):
                Debug.info(message)
            case .success:
                fn()
            }
        }
    }

    func drawColor(
        graphics g: EffectGraphics, size: Size, points: [Point]
    ) {
        guard let sprite = sprite else { return }
        let rb = Rect(origin: .zero, size: size)
        g.fill(rect: rb, blend: .sub, color: Color(l: 0.01))
        var i = 0
        var h = 0.0
        let dh = 1.0 / Double(points.count)
        for p in points {
            let m = eq[i] * size.area / size.crop(1).aera
            let r = Rect(center: p * size, size: Size(0.4, 0.4) * size.crop(1) * m)
            let ri = Rect(
                center: Point(1 - p.x, p.y) * size, size: Size(0.4, 0.4) * size.crop(1) * m)
            let c = Color(h: h, s: 1, b: 1)
            g.draw(rect: r, image: sprite, blend: .add, color: c)
            g.draw(rect: ri, image: sprite, blend: .add, color: c)
            i += 1
            h += dh
        }
    }

    func vSpriteData(size: Int) -> [FPoint] {
        var data: [FPoint] = [FPoint](repeating: .zero, count: size * size)
        var i = 0
        for y in 0..<32 {
            for x in 0..<32 {
                let r = Point(x: Double(x) - 15.5, y: Double(y) - 15.5).radius
                let v = max(Float(1 - (r / 16.0)), 0)
                data[i].uv = SIMD2<Float>(x: v, y: v)
                i += 1
            }
        }
        return data
    }
    func spriteData(size: Int) -> [UInt32] {
        var data: [UInt32] = [uint32](repeating: .zero, count: size * size)
        var i = 0
        for y in 0..<32 {
            for x in 0..<32 {
                let r = Point(x: Double(x) - 15.5, y: Double(y) - 15.5).radius
                let v = max(1 - (r / 16.0), 0)
                data[i] = Color(a: 1, l: v).bgra
                i += 1
            }
        }
        return data
    }
    struct ColorPoint {
        internal init(position: Point, orientation: Double) {
            self.position = position
            self.orientation = orientation
        }
        let position: Point
        let orientation: Double
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
        Debug.info("\(d)")
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
