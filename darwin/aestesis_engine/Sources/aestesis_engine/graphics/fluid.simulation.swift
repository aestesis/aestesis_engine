import Foundation
import Metal
import aestesis_alib
import simd

// https://docs.google.com/document/d/1rOTcBg7cpGijgfeBhA5SbsOHKM1uWnb24E18bye5hFU/edit?pli=1&tab=t.0

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class FluidSimulation: NodeUI {
    var diffusion: Double = 0.01
    let size: SizeI
    let diffuseKernel: ComputeKernel
    let boundaryKernel: ComputeKernel
    var textures: [Texture2D] = []
    var source: Texture2D {
        return textures[0]
    }
    var destination: Texture2D {
        return textures[1]
    }
    func swap() {
        textures.swapAt(0, 1)
    }
    init(parent: NodeUI, size: SizeI) throws {
        let library = parent.viewport!.library(bundle: Bundle.aestesis, name: "default")
        self.size = size
        diffuseKernel = try ComputePass.register(kernel: "kernelFluidDiffuse", library: library)
        boundaryKernel = try ComputePass.register(kernel: "kernelFluidBoundary", library: library)
        super.init(parent: parent)
    }

    func step(dtime: Double) {
        var fence: MTLFence?
        for _ in 1...6 {
            fence = diffuse(dtime: dtime, wait: fence)
            fence = boundary(wait: fence)
            swap()
        }
    }

    func diffuse(dtime: Double, wait: MTLFence? = nil, fn: ((ComputePass.Result) -> Void)? = nil)
        -> MTLFence?
    {
        guard let viewport = viewport else { return nil }
        let a = Float(dtime * diffusion) * Float((size - SizeI(2, 2)).surface)
        let c = 1 + 4 * a
        let compute = ComputePass(parent: viewport)
        compute.use(kernel: diffuseKernel)
        compute.use(texture: destination)
        compute.use(params: FluidDiffuseParams(a: a, c: c))
        if let fence = wait {
            compute.wait(fence: fence)
        }
        compute.dispatch(size: size.mtl, threads: MTLSize(width: 8, height: 8, depth: 1))
        let fence = compute.update()
        compute.onDone.once { result in
            fn?(result)
        }
        compute.commit()
        return fence
    }

    func boundary(wait: MTLFence? = nil, fn: ((ComputePass.Result) -> Void)? = nil) -> MTLFence? {
        guard let viewport = viewport else { return nil }
        let compute = ComputePass(parent: viewport)
        compute.use(kernel: boundaryKernel)
        compute.use(texture: destination)
        if let fence = wait {
            compute.wait(fence: fence)
        }
        compute.dispatch(size: size.mtl, threads: MTLSize(width: 8, height: 8, depth: 1))
        let fence = compute.update()
        compute.onDone.once { result in
            fn?(result)
        }
        compute.commit()
        return fence
    }

}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
typealias FPoint = SIMD4<Float>
extension FPoint {
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
public struct FluidDiffuseParams {
    var a: Float
    var c: Float
}
extension ComputePass {
    public func use(params: FluidDiffuseParams) {
        let b = viewport!.gpu.buffers.get(MemoryLayout<FluidDiffuseParams>.stride)
        let ptr = b.ptr.assumingMemoryBound(to: FluidDiffuseParams.self)
        ptr[0] = params
        use(buffer: b)
        onDone.once { result in
            b.recycle()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
