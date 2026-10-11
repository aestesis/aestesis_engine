import Foundation
import aestesis_alib
import simd

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynFluid: Syn, @unchecked Sendable {
    var sim: FluidSimulation?
    var size: SizeI = .zero
    var vSprite: Bitmap?
    var sprite: Bitmap?
    let spos = Parameter2(complexity: 4)
    var t = ß.rnd * 10000
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let ssize = 32
        vSprite = Bitmap(parent: self, size: Size(ssize, ssize), format: .float4)
        vSprite?.set(pixels: spriteData(size: ssize))
        sprite = Bitmap(parent: self, size: Size(32, 32))
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

        let g0 = EffectGraphics(image: sim.texture, viewport: viewport)
        t += dtime * (Double(audio.peak) * 20 + 0.5)
        let position = spos.unity(t)
        let direction = (spos.unity(t + 0.01) - position).normalized
        let v = direction * 0.1
        var points: [Point] = []
        let r = Rect(center: position, size: Size(0.05, 0.05))
        let ri = Rect(center: Point.unity - position, size: Size(0.05, 0.05))
        g0.drawFloat(rect: r * size.double, image: sprite, color: Color(a: 1, r: v.x, g: v.y, b: 1))
        g0.drawFloat(
            rect: ri * size.double, image: sprite, color: Color(a: 1, r: -v.x, g: -v.y, b: 1))
        points.append(r.center)
        points.append(ri.center)
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
        g.fluidAdvect(rect: output.bounds, source: output, fluid: sim.texture)
        drawColor(graphics: g, size: output.size, points: points, audio: audio)
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
        graphics g: EffectGraphics, size: Size, points: [Point], audio: AudioAnalyzer.Info
    ) {
        guard let sprite = sprite else { return }
        var pdata: [UInt32] = []
        var colors: [Color] = []
        for i in 0..<16 {
            colors.append(
                Color(
                    r: Double(audio.bass[i]) * 100 + 0.5, g: Double(audio.medium[i]) * 5 + 0.5,
                    b: Double(audio.treeble[i]) * 20 + 0.5))
        }
        colors.append(contentsOf: colors.reversed())
        for y in 0..<32 {
            for x in 0..<32 {
                let p = Point(Double(x) - 15.5, Double(y) - 15.5)
                let v = max(0, 1 - (p.radius / 16))
                let c = (colors[x] + colors[y]) * 0.5
                pdata.append(c.saturated.with(a: v).bgra)
            }
        }
        sprite.set(pixels: pdata)
        let rb = Rect(origin: .zero, size: size)
        g.fill(rect: rb, blend: .sub, color: Color(l: 0.01))
        for p in points {
            let r = Rect(center: p, size: Size(0.6, 0.6))
            g.draw(rect: r * size, image: sprite, blend: .alpha, color: Color(a: 0.8, l: 1))
        }
    }

    func spriteData(size: Int) -> [FPoint] {
        var data: [FPoint] = [FPoint](repeating: .zero, count: size * size)
        var i = 0
        for y in 0..<32 {
            for x in 0..<32 {
                let r = Point(x: Double(x) - 15.5, y: Double(y) - 15.5).radius
                let v = Float(1 - (r / 16.0))
                data[i].uv = SIMD2<Float>(x: v, y: v)
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
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
