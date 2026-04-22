//
//  syn.soundscape.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 07/02/2024.
//

import Foundation
import Accelerate
import simd

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynSoundscape: SynRenderer {
    var material: MaterialHeightMap?
    var light: PointLight?
    var onode: Node3D?
    var plan: Plan?
    var mask: Bitmap?
    var waveform: Bitmap?
    var gradient: Bitmap?
    var mffts = [FFT](repeating: FFT(freq: 0, time: 0, amplitude: 0), count: 512)
    let zygos: [Zygo] = [Zygo(), Zygo(), Zygo(), Zygo()]
    let sampleCount = 512
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let world = Node3D(parent: renderer!)
        renderer!.world = world
        let rotplan = 0.85
        onode = Node3D(parent: world, matrix: Mat4.rotX(ß.π * rotplan))
        renderer!.camera = Camera3D(parent: world, position: Vec3(z: -10), direction: Vec3(z: 1))
        let attenuation = Attenuation(quadratic: 0.005)
        light = PointLight(
            parent: world, position: Vec3(x: 1, y: -3, z: -5), color: .white, attenuation: attenuation)
        plan = Plan(parent: self, factor: 320)
        self["mesh.plan"] = plan
        material = MaterialHeightMap(
            parent: self, name: "eq3d.waves", blend: .alpha, cull: .front, ambient: Color(hex: "404040"),
            diffuse: Color(hex: "A0A0A0"), specular: .white, shininess: 100,
            textureSize: Size(1024, 1024), heightSize: Size(sampleCount, sampleCount),
            heightFormat: .height, scale: 0.4, adjustNormals: 0.2)
        self["material.eq3d.waves"] = material
        _ = ObjectOld(
            parent: onode!, matrix: Mat4.scale(Vec3(x: 1, y: 1, z: 1) * 20), mesh: "mesh.plan",
            material: "material.eq3d.waves")
        self.bg {
            self.mask = Bitmap(
                parent: self, path: "Effects/medusa.2.png", bundle: Bundle(for: SynSoundscape.self))
            self.waveform = Bitmap(parent: self, size: Size(self.sampleCount, 1), format: .height)
            self.gradient = ColorGradient([
                0: .aeMagenta * 0.25, 0.2: .aeMagenta * 0.5, 0.8: .aeOrange, 1: .white,
            ]).createBitmap(parent: self, width: 32)
        }
        initMFFT()
        
        // _ = Object(parent: onode!, box: Box(center: .zero, size: .unity*10))
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let plan = plan, plan.initialized, let renderer = renderer, let light = light,
              let camera = renderer.camera, let onode = onode
        else { return }
        
        updateWaveform(dtime: dtime, audio: audio)
        updateMaterial(time: time)
        
        let pl = Point(x: sin(time * 0.05141), y: sin(time * 0.01141)) * 3 + Point(0, -3)
        light.position = Vec3(x: pl.x, y: pl.y, z: -5)
        let pc = Point(x: sin(time * 0.1141), y: sin(time * 0.2141)) * 3
        camera.position = Vec3(x: pc.x, y: pc.y, z: -10 - sin(time * 0.12341) + sin(time * 0.012511) + sin(time * 0.0018141))
        camera.lookAt(node: onode)
        
        let g = Graphics(image: output, clear: Color(hex: "000020"), depthClear: 1)
        renderer.render(to: g, size: output.size)
        /* debug
        if let height = material?.height as? Bitmap, let gradient=gradient {
            g.draw(rect: output.bounds, image: height, gradient: gradient)
        }
         */
        g.onDone { [weak self] ok in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    func updateWaveform(dtime: Double, audio: AudioAnalyzer.Info) {
        guard let waveform = waveform else { return }
        let sample = getSample(dtime:dtime,audio:audio)
        var data = [UInt16](repeating: 0, count: sampleCount)
        for xi in 0..<sampleCount {
            let l = max(min(sample[xi] * 0.5 + 0.5, 1), 0)
            data[xi] = UInt16(l * 65535)
        }
        waveform.set(pixels: data)
    }
    func initMFFT() {
        let di: Double = 64.0 / Double(mffts.count)
        for i in 0..<mffts.count {
            let ix = di * Double(i)
            mffts[i].freq = (10 + ix * 0.6) * 0.02
        }

    }
    func getSample(dtime:Double, audio:AudioAnalyzer.Info) -> [Float] {
        var sample = [Float](repeating: 0, count: sampleCount)
        let di: Double = 64.0 / Double(mffts.count)
        for i in 0..<mffts.count {
            let ix = di * Double(i)
            mffts[i].time += dtime * (4 + ix * 0.12)
            let a: Double = Double(audio.fft.amplitude[i]) * 50
            let v: Double = a * (0.03 + di * 0.001)
            mffts[i].amplitude = mffts[i].amplitude * 0.5 + v
        }
        let mt = 128 / Double(sampleCount)
        var smp = [SIMD16<Float>](repeating: SIMD16<Float>(), count:sampleCount / 16)
        for f in mffts {
            let a = Float(f.amplitude)
            let amp = SIMD16<Float>(a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a)
            var t = Float(f.time)
            let dt = Float(-(f.freq * mt))
            var ismp = 0
            for _ in 0..<smp.count {
                var v = SIMD16<Float>()
                v[0] = t
                t += dt
                v[1] = t
                t += dt
                v[2] = t
                t += dt
                v[3] = t
                t += dt
                v[4] = t
                t += dt
                v[5] = t
                t += dt
                v[6] = t
                t += dt
                v[7] = t
                t += dt
                v[8] = t
                t += dt
                v[9] = t
                t += dt
                v[10] = t
                t += dt
                v[11] = t
                t += dt
                v[12] = t
                t += dt
                v[13] = t
                t += dt
                v[14] = t
                t += dt
                v[15] = t
                t += dt
                smp[ismp] += sin(v) * amp
                ismp += 1
            }
        }
        var si = 0
        for s in smp {
            sample[si] = s[0]
            si += 1
            sample[si] = s[1]
            si += 1
            sample[si] = s[2]
            si += 1
            sample[si] = s[3]
            si += 1
            sample[si] = s[4]
            si += 1
            sample[si] = s[5]
            si += 1
            sample[si] = s[6]
            si += 1
            sample[si] = s[7]
            si += 1
            sample[si] = s[8]
            si += 1
            sample[si] = s[9]
            si += 1
            sample[si] = s[10]
            si += 1
            sample[si] = s[11]
            si += 1
            sample[si] = s[12]
            si += 1
            sample[si] = s[13]
            si += 1
            sample[si] = s[14]
            si += 1
            sample[si] = s[15]
            si += 1
        }
        return sample
    }
    func updateMaterial(time: Double) {
        guard let material = material, let mask = mask, let texture = material.texture as? Bitmap,
              let height = material.height as? Bitmap, let heightBase = waveform, let gradient = gradient
        else { return }
        let gHeight = EffectGraphics(image: height)
        let rz: Size = height.size * 0.1
        let p0: Point = zygos[0].position(time: time) * rz
        let p1: Point = zygos[1].position(time: time) * rz
        let p2: Point = zygos[2].position(time: time) * rz
        let p3: Point = zygos[3].position(time: time) * rz
        gHeight.drawPolar(
            rect: height.bounds.translate(p0).scale(1.7), source: heightBase, blend: .opaque,
            color: Color(a: 1, l: 0.25))
        gHeight.drawPolar(
            rect: height.bounds.translate(p1).scale(1.7), source: heightBase, blend: .add,
            color: Color(a: 1, l: 0.25))
        gHeight.drawPolar(
            rect: height.bounds.translate(p2).scale(1.7), source: heightBase, blend: .add,
            color: Color(a: 1, l: 0.25))
        gHeight.drawPolar(
            rect: height.bounds.translate(p3).scale(1.7), source: heightBase, blend: .add,
            color: Color(a: 1, l: 0.25))
        let gt = Graphics(image: texture)
        gt.draw(rect: texture.bounds, image: height, gradient: gradient)
        gt.draw(rect: texture.bounds, image: mask, blend: .setAlpha)
    }
    class Plan: MeshOld {
        init(parent: NodeUI, factor: Int = 128) {
            super.init(parent: parent)
            self.zz {
                let d = 1 / Double(factor)
                let n = Vec3(x: 0, y: 0, z: 1).normalized
                var v = [Vertex](
                    repeating: Vertex(position: .zero, normal: .zero, uv: .zero, color: .black),
                    count: factor * factor)
                var nv = 0
                var y = 0.0
                for yi in 0..<factor {
                    var x = (yi & 1) == 0 ? 0 : d * 0.5
                    for _ in 0..<factor {
                        let p = Vec3(x: (x - 0.5) * 2, y: (y - 0.5) * 2, z: 0)
                        v[nv] = Vertex(position: p, normal: n, uv: Point(x: x, y: y))
                        nv += 1
                        x += d
                    }
                    y += d
                    if !self.attached {
                        return
                    }
                }
                self.vertices = v
                let mat = "material.default"
                var f = [Int32](repeating: 0, count: (factor - 1) * (factor - 1) * 2 * 3)
                var nf = 0
                let addFace: (Int32, Int32, Int32) -> Void = { v0, v1, v2 in
                    f[nf] = v0
                    nf += 1
                    f[nf] = v1
                    nf += 1
                    f[nf] = v2
                    nf += 1
                }
                for yi in 0..<factor - 1 {
                    let ypair = (yi & 1) == 0
                    var x = yi * factor
                    var nx = x + factor
                    for _ in 0..<factor - 1 {
                        if ypair {
                            addFace(Int32(x), Int32(x + 1), Int32(nx))
                            addFace(Int32(x + 1), Int32(nx + 1), Int32(nx))
                        } else {
                            addFace(Int32(x), Int32(nx + 1), Int32(nx))
                            addFace(Int32(x), Int32(x + 1), Int32(nx + 1))
                        }
                        x += 1
                        nx += 1
                    }
                    if !self.attached {
                        return
                    }
                }
                self.faces[mat] = f
                if self.attached {
                    self.dispatchInitialized()
                }
            }
        }
    }
    struct Zygo {
        let freq0: Double
        let freq1: Double
        func position(time t: Double) -> Point {
            return Point(sin(t * freq0), sin(t * freq1))
        }
        init() {
            freq0 = ß.rnd * 0.1 + 0.0172675261
            freq1 = ß.rnd * 0.1 + 0.0114521913
        }
    }
    struct FFT {
        var freq: Double
        var time: Double
        var amplitude: Double
    }
    
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
