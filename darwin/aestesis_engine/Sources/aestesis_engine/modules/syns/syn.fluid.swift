import Foundation
import aestesis_alib
import simd

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynFluid: Syn {
    var sim: FluidSimulation?
    var size: SizeI = .zero
    override init(parent: NodeUI) {
        super.init(parent: parent)
    }
    override func detach() {
        sim?.detach()
        sim = nil
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
        guard let sim = sim else { return }
        // TODO add movements

    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
