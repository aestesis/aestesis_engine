import Foundation
import Metal
import aestesis_alib
import simd

// https://docs.google.com/document/d/1rOTcBg7cpGijgfeBhA5SbsOHKM1uWnb24E18bye5hFU/edit?pli=1&tab=t.0

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class FluidSimulation: NodeUI, @unchecked Sendable {
    var diffusion: Double = 0.01
    private let size: SizeI
    private let diffuseKernel: ComputeKernel
    private let boundaryKernel: ComputeKernel
    private let projectDivergenceKernel: ComputeKernel
    private let projectPoissonKernel: ComputeKernel
    private let projectPressureKernel: ComputeKernel
    private var textures: [Bitmap] = []
    private var source: Bitmap {
        return textures[0]
    }
    private var destination: Bitmap {
        return textures[1]
    }
    public var texture: Bitmap {
        return source
    }
    private func swap() {
        textures.swapAt(0, 1)
    }
    init(parent: NodeUI, size: SizeI) throws {
        let library = parent.viewport!.library(bundle: Bundle.aestesis, name: "default")
        self.size = size
        diffuseKernel = try ComputePass.register(kernel: "kernelFluidDiffuse", library: library)
        boundaryKernel = try ComputePass.register(kernel: "kernelFluidBoundary", library: library)
        projectDivergenceKernel = try ComputePass.register(
            kernel: "kernelFluidProjectDivergence", library: library)
        projectPoissonKernel = try ComputePass.register(
            kernel: "kernelFluidProjectPoisson", library: library)
        projectPressureKernel = try ComputePass.register(
            kernel: "kernelFluidProjectPressure", library: library)
        super.init(parent: parent)
        for _ in 1...2 {
            textures.append(Bitmap(parent: self, size: size.double, format: .float4))
        }
    }

    func advance(dtime: Double, fence f0: MTLFence? = nil) -> MTLFence? {
        let iteration = 20
        var fence: MTLFence? = f0
        /*
        let g = EffectGraphics(image: source)
        if let fence = fence {
            g.wait(fence: fence)
        }
        g.fillFloat(rect: source.bounds, blend: .alpha, color: Color(a: 0.001, l: 0))
        fence = g.update()
        */
        for _ in 1...iteration {
            fence = diffuse(dtime: dtime, wait: fence) { result in
                switch result {
                case .discarded:
                    Debug.info("discarded")
                case .error(let message):
                    Debug.info("error \(message)")
                case .success:
                    break
                }
            }
            swap()
            fence = boundary(wait: fence) { result in
                switch result {
                case .discarded:
                    Debug.info("discarded")
                case .error(let message):
                    Debug.info("error \(message)")
                case .success:
                    break
                }
            }
        }
        fence = project(kernel: projectDivergenceKernel, wait: fence) { result in
            switch result {
            case .discarded:
                Debug.info("discarded")
            case .error(let message):
                Debug.info("error \(message)")
            case .success:
                break
            }
        }
        fence = boundary(wait: fence) { result in
            switch result {
            case .discarded:
                Debug.info("discarded")
            case .error(let message):
                Debug.info("error \(message)")
            case .success:
                break
            }
        }
        for _ in 1...iteration {
            fence = project(kernel: projectPoissonKernel, wait: fence) { result in
                switch result {
                case .discarded:
                    Debug.info("discarded")
                case .error(let message):
                    Debug.info("error \(message)")
                case .success:
                    break
                }
            }
            fence = boundary(wait: fence) { result in
                switch result {
                case .discarded:
                    Debug.info("discarded")
                case .error(let message):
                    Debug.info("error \(message)")
                case .success:
                    break
                }
            }
        }
        fence = project(kernel: projectPressureKernel, wait: fence) { result in
            switch result {
            case .discarded:
                Debug.info("discarded")
            case .error(let message):
                Debug.info("error \(message)")
            case .success:
                break
            }
        }
        fence = boundary(wait: fence) { result in
            switch result {
            case .discarded:
                Debug.info("discarded")
            case .error(let message):
                Debug.info("error \(message)")
            case .success:
                break
            }
        }
        return fence
    }

    private func diffuse(
        dtime: Double, wait: MTLFence? = nil, fn: ((ComputePass.Result) -> Void)? = nil
    )
        -> MTLFence?
    {
        guard let viewport = viewport else { return nil }
        let a = Float(dtime * diffusion) * Float((size - SizeI(2, 2)).surface)
        let c = 1 + 4 * a
        let compute = ComputePass(parent: viewport)
        compute.use(kernel: diffuseKernel)
        compute.use(texture: destination)
        compute.use(texture: source, atIndex: 1)
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

    private func project(
        kernel: ComputeKernel, wait: MTLFence? = nil, fn: ((ComputePass.Result) -> Void)? = nil
    )
        -> MTLFence?
    {
        guard let viewport = viewport else { return nil }
        let compute = ComputePass(parent: viewport)
        compute.use(kernel: kernel)
        compute.use(texture: source)
        compute.use(
            params: FluidProjectParams(
                size: Float(max(destination.pixels.width, destination.pixels.height))))
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

    private func boundary(wait: MTLFence? = nil, fn: ((ComputePass.Result) -> Void)? = nil)
        -> MTLFence?
    {
        guard let viewport = viewport else { return nil }
        let compute = ComputePass(parent: viewport)
        compute.use(kernel: boundaryKernel)
        compute.use(texture: source)
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
public struct FluidProjectParams {
    internal init(size: Float) {
        self.isize = 1 / size
    }
    var isize: Float
}
extension ComputePass {
    public func use(params: FluidProjectParams) {
        let b = viewport!.gpu.buffers.get(MemoryLayout<FluidProjectParams>.stride)
        let ptr = b.ptr.assumingMemoryBound(to: FluidProjectParams.self)
        ptr[0] = params
        use(buffer: b)
        onDone.once { result in
            b.recycle()
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
