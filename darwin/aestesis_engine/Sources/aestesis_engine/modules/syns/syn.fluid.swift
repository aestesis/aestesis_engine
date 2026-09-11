import Foundation
import aestesis_alib
import simd

// https://docs.google.com/document/d/1rOTcBg7cpGijgfeBhA5SbsOHKM1uWnb24E18bye5hFU/edit?pli=1&tab=t.0
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynFluid: Syn {
    var textures: [Texture2D] = []
    var size = Size.zero
    var source:Texture2D {
        return textures[0]
    }
    var destination:Texture2D {
        return textures[1]
    }
    override init(parent: NodeUI) {
        super.init(parent: parent)
    }
    override func detach() {
        for t in textures {
            t.detach()
        }
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps: Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let viewport = viewport else { return }
        let size = (output.size * 0.25 / 8).round * 8
        if self.size != size {
            for t in textures {
                t.detach()
            }
            textures.removeAll()
            for i in 1...2 {
                textures.append(Texture2D(parent: viewport, size: size, format: .float4))
            }
            self.size = size
        }
        // TODO add movements

    }

    func diffuse(dtime: Float)  {
        //let compute
    }

    func boundary(texture: Texture2D) {

    }


}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
typealias FCell = SIMD4<Float>
extension FCell {
    var uv: SIMD2<Float> {
        get {
            return self.lowHalf
        }
        set(uv) {
            self.lowHalf = uv
        }
    }
    var u: Float {
        get {
            return self.x
        }
        set(u) {
            self.x = u
        }
    }
    var v: Float {
        get {
            return self.y
        }
        set(v) {
            self.y = v
        }
    }
    var density: Float {
        get {
            return self.z
        }
        set(d) {
            self.z = d
        }
    }
    var d: Float {
        get {
            return self.z
        }
        set(d) {
            self.z = d
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
