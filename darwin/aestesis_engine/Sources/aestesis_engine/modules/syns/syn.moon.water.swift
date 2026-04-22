//
//  syn.sea.waves.swift
//  flutter_alib
//
//  Created by renan jegouzo on 04/02/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynMoonWater: SynRenderer {
    var world: Node3D?
    var camera: Camera3D?
    var material: MaterialHeightMap?
    var light: PointLight?
    var plan: Plan?
    var eq = EQH()
    var zygos: [Zygo] = [
        Zygo(pos: Point(-1000, -1000), freq: 0.3, amp: 0.4, speed: 3),
        Zygo(pos: Point(1000, -1000), freq: 0.41871, amp: 0.3, speed: 5),
        Zygo(pos: Point(500, -1000), freq: 0.6167101, amp: 0.3, speed: 7),
    ]
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let world = Node3D(parent: renderer!)
        let onode = Node3D(parent: world, matrix: Mat4.rotX(ß.π * 0.85))
        let camera = Camera3D(parent: world, position: Vec3(z: -5), direction: Vec3(z: 1))
        let attenuation = Attenuation(quadratic: 0.005)
        light = PointLight(
            parent: world, position: Vec3(x: 1, y: -3, z: -5), color: .white, attenuation: attenuation)
        plan = Plan(parent: self, factor: 32)
        self["mesh.plan"] = plan
        material = MaterialHeightMap(
            parent: self, name: "eq3d.waves", cull: .front, ambient: Color(hex: "404040"),
            diffuse: Color(hex: "606060"), specular: .white, shininess: 3, size: Size(32, 32), scale: 0.2,
            adjustNormals: 0.2)
        self["material.eq3d.waves"] = material
        renderer!.world = world
        renderer!.camera = camera
        self.io {
            let b = Bitmap(parent: self, path: "Effects/sea.png", bundle: Bundle(for: SynMoonWater.self))
            if let bc = self.material?.texture as? Bitmap {
                let g = Graphics(image: bc)
                g.draw(rect: bc.bounds, image: b)
            }
            b.detach()
        }
        _ = ObjectOld(
            parent: onode, matrix: Mat4.scale(Vec3(x: 1, y: 1, z: 1) * 20), mesh: "mesh.plan",
            material: "material.eq3d.waves")
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let bh = material?.height, let plan = plan, plan.initialized, let renderer = renderer
        else { return }
        eq = eq * 0.9 + EQH(audio.eq) * 0.1
        zygos[0].amp = min(eq.low, 0.5)
        zygos[1].amp = min(eq.medium, 0.3)
        zygos[2].amp = min(eq.high, 0.2)
        let w = Int(bh.pixels.width)
        let h = Int(bh.pixels.height)
        var data = [UInt32](repeating: 0, count: w * h)
        var d = 0
        var c = Color(hex: "#00000000")
        for yi in 0..<h {
            let y = Double(yi)
            for xi in 0..<w {
                let x = Double(xi)
                var v = 0.0
                for z in zygos {
                    let dx = x - z.pos.x
                    let dy = y - z.pos.y
                    v += (sin(sqrt(dx * dx + dy * dy) * z.freq + time * z.speed) * 0.5 + 0.5) * z.amp
                }
                c.r = v
                data[d] = c.bgra
                d += 1
            }
        }
        bh.set(pixels: data)
        let pl = Point(x: sin(ß.time * 0.05141), y: sin(ß.time * 0.01141)) * 3 + Point(0, -3)
        light?.position = Vec3(x: pl.x, y: pl.y, z: -5)
        let g = Graphics(image: output, clear: .black, depthClear: 1.0)
        renderer.render(to: g, size: output.size)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    class Plan: MeshOld {
        init(parent: NodeUI, factor: Int = 64) {
            super.init(parent: parent)
            zz {
                let d = 1 / Double(factor)
                let n = Vec3(x: 0, y: 0, z: 1).normalized
                for yi in 0..<factor {
                    let y = Double(yi) * d
                    let dx = (yi & 1) == 0 ? 0 : d * 0.5
                    for xi in 0..<factor {
                        let x = Double(xi) * d + dx
                        let p = Vec3(x: (x - 0.5) * 2, y: (y - 0.5) * 2, z: 0)
                        self.vertices.append(Vertex(position: p, normal: n, uv: Point(x: x, y: y)))
                    }
                }
                let mat = "material.default"
                self.faces[mat] = [Int32]()
                for yi in 0..<factor - 1 {
                    let ypair = (yi & 1) == 0
                    var x = yi * factor
                    var nx = x + factor
                    for _ in 0..<factor - 1 {
                        if ypair {
                            self.appendFace(material: mat, v0: Int32(x), v1: Int32(x + 1), v2: Int32(nx))
                            self.appendFace(material: mat, v0: Int32(x + 1), v1: Int32(nx + 1), v2: Int32(nx))
                        } else {
                            self.appendFace(material: mat, v0: Int32(x), v1: Int32(nx + 1), v2: Int32(nx))
                            self.appendFace(material: mat, v0: Int32(x), v1: Int32(x + 1), v2: Int32(nx + 1))
                        }
                        x += 1
                        nx += 1
                    }
                    
                }
                self.dispatchInitialized()
            }
        }
    }
    struct Zygo {
        var pos: Point
        var freq: Double
        var amp: Double
        var speed: Double
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
