import Foundation
import aestesis_alib
import simd

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynFluid: Syn, @unchecked Sendable {
    var sim: FluidSimulation?
    var size: SizeI = .zero
    var sprite: Bitmap?
    let spos = Parameter2(complexity: 3)
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let ssize = 32
        sprite = Bitmap(parent: self, size: Size(ssize, ssize), format: .float4)
        sprite?.set(pixels: spriteData(size: ssize))
    }
    override func detach() {
        sim?.detach()
        sim = nil
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
        guard let sim = sim, let sprite = sprite else { return }

        let g0 = EffectGraphics(image: sim.texture, viewport: viewport)
        let position = spos.unity(time*5) * size.double
        let direction = spos.unity(time*5+0.01) * size.double - position
        let r = Rect(center: position, size: size.double * 0.05)
        g0.drawFloat(rect: r, image: sprite, rotation: direction.angle)
        var fence = g0.update()

        fence = sim.advance(dtime: dtime, fence: fence)

        let g = EffectGraphics(image: output, viewport: viewport)
        if let fence = fence {
            g.wait(fence: fence)
        }
        g.fluidAdvect(rect: output.bounds, source: output, fluid: sim.texture)
        g.onDone({ result in
            switch result {
            case .discarded:
                Debug.info("discarded")
            case .error(let message):
                Debug.info(message)
            case .success:
                fn()
            }
        })
    }

    func spriteData(size: Int) -> [FPoint] {
        var data: [FPoint] = [FPoint](repeating: .zero, count: size * size)
        var i = 0
        for _ in 0..<32 {
            for _ in 0..<32 {
                data[i].uv = SIMD2<Float>(x: 0.01, y: 0.01)
                i += 1
            }
        }
        return data
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
