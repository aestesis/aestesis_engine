import Foundation
import aestesis_alib
import simd

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynFluidEq: Syn, @unchecked Sendable {
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
        var pointSprites: [PointSprite] = []
        let sized = size.double
        let sz = (sized.crop(1).width * 0.002) * sized.area / sized.crop(1).area
        var i = 0
        for e in eq {
            let p = spos.unity(tt)
            let d = Point(
                angle: sdir.sin(tt).normalized.angle
                    + (p - spos.unity(tt + 0.1)).normalized.angle)
            let v = d * (0.01 + abs(Double(audio.samples[i])) * 0.5)
            let s = e * sz
            pointSprites.append(
                PointSprite(
                    position: p * sized, scale: s, color: Color(a: 1, r: v.x, g: v.y, b: 1)))
            pointSprites.append(
                PointSprite(
                    position: Point(1 - p.x, p.y) * sized, scale: s,
                    color: Color(a: 1, r: -v.x, g: v.y, b: 1)))
            points.append(p)
            tt -= 1
            i += 1
        }
        g0.drawFloat(sprites: pointSprites, image: sprite)
        /*
        for e in eq {
            let position = spos.unity(tt)
            let direction = sdir.sin(tt).normalized
            let v = direction * 0.1
            let m = size.double.area / size.double.crop(1).aera
            let rsz = Size(0.15, 0.15) * m * e
            let r = Rect(center: position, size: rsz)
            let ri = Rect(center: Point(1 - position.x, position.y), size: rsz)
            g0.drawFloat(
                rect: Rect(center: r.center * size.double, size: r.size * size.double.crop(1)),
                image: sprite, color: Color(a: 1, r: v.x, g: v.y, b: 1))
            g0.drawFloat(
                rect: Rect(center: ri.center * size.double, size: ri.size * size.double.crop(1)),
                image: sprite, color: Color(a: 1, r: -v.x, g: v.y, b: 1))
            points.append(r.center)
            tt -= 0.1
        }
*/
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

        let g = EffectGraphics(image: output, viewport: viewport)
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
        let sz = (size.crop(1).width * 0.005) * size.area / size.crop(1).area
        var ps: [PointSprite] = []
        for p in points {
            let s = eq[i] * sz
            let c = Color(a: 1, h: h, s: 1, b: 1)
            ps.append(PointSprite(position: p * size, scale: s, color: c))
            ps.append(PointSprite(position: Point(1 - p.x, p.y) * size, scale: s, color: c))
            i += 1
            h += dh
        }
        g.draw(sprites: ps, image: sprite, blend: .add)
    }

    func vSpriteData(size: Int) -> [FPoint] {
        var data: [FPoint] = [FPoint](repeating: .zero, count: size * size)
        var i = 0
        for y in 0..<32 {
            for x in 0..<32 {
                let r = Point(x: Double(x) - 15.5, y: Double(y) - 15.5).radius
                let v = Float(apow(max(1 - (r / 16.0), 0), 0.3))
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
                let v = apow(max(1 - (r / 16.0), 0), 0.3)
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
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
