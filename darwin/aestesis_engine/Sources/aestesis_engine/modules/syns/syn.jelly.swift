//
//  syn.shape.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 05/02/2024.
//

import Foundation
import simd

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynJelly: SynRenderer {
    var light: PointLight?
    
    var speed = 0.0
    var enveloppe = 0.0
    var eq = EQH()
    var enveloppes = [Double]()
    var colors = [Color]()
    var cube: Node3D?
    var main: Node3D?
    var material: MaterialHeightMap?
    var material2: MaterialHeightMap?
    var particles: Particles?
    
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let world = Node3D(parent: self)
        renderer!.world = world
        let camera = Camera3D(parent: world, position: Vec3(z: -2), direction: Vec3(z: 1))
        renderer!.camera = camera
        let attenuation = Attenuation(quadratic: 0.005)
        _ = PointLight(
            parent: world, position: Vec3(x: 3, y: -3, z: -5), color: .white, attenuation: attenuation)
        self["material.eq3d.uber.cube"] = MaterialOld(
            parent: self, name: "eq3d.uber.cube", cull: .back, ambient: Color(hex: "000020"),
            diffuse: Color(hex: "000020"), specular: .white, shininess: 40)
        let cube = Node3D(parent: world)
        self.cube = cube
        let _ = ObjectOld(
            parent: cube, box: Box(center: .zero, size: Vec3(x: 1, y: 1, z: 1) * 300),
            material: "material.eq3d.uber.cube",inversNormals: true)
        self["mesh.eq3d.uber"] = MeshUber(parent: self, length: 6, radius: 0.01)
        material = MaterialHeightMap(
            parent: self, name: "eq3d.uber", blend: .add, cull: .front, ambient: Color(hex: "404040"),
            diffuse: Color(hex: "606060"), specular: .white, shininess: 40, size: Size(64, 32), scale: 2,
            adjustNormals: 0.2)
        self["material.eq3d.uber"] = material
        material2 = MaterialHeightMap(
            parent: self, name: "eq3d.uber", blend: .add, cull: .none, ambient: Color(hex: "404040"),
            diffuse: Color(hex: "707070"), specular: .white, shininess: 40, size: Size(64, 32), scale: 2,
            adjustNormals: 0.2)
        self["material.eq3d.uber.2"] = material2
        let main = Node3D(parent: world)
        self.main = main
        _ = ObjectOld(
            parent: main, matrix: .identity, mesh: "mesh.eq3d.uber", material: "material.eq3d.uber")
        _ = ObjectOld(
            parent: main, matrix: Mat4.scale(Vec3(x: 1.1, y: 1, z: 1.1)), mesh: "mesh.eq3d.uber",
            material: "material.eq3d.uber.2")
        self["material.eq3d.uber.particles"] = MaterialOld(
            parent: self, name: "eq3d.uber.particles", blend: .alpha, cull: .none, diffuse: .white)
        particles = Particles(
            parent: world, matrix: Mat4.identity,
            box: Box(center: .zero, size: Vec3(x: 10, y: 10, z: 10)), count: 100,
            material: "material.eq3d.uber.particles")
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let cube = cube, let main = main, let material = material, let material2 = material2,
              let particles = particles
        else { return }
        cube.matrix = Rot3(phi: ß.time * 0.241546416, theta: ß.time * 0.176761751).matrix
        enveloppe = audio.envelope * 0.5 + enveloppe * 0.5
        speed = audio.envelope * 0.05 + speed * 0.95
        eq = EQH(audio.eq) * 0.5 + eq * 0.5
        enveloppes.enqueue(enveloppe)
        var c = Color(a: 1, r: eq.low * 2, g: eq.medium * 2.5, b: eq.high * 3.5).saturated
        if c.luminosity < 0.1 {
            c = c.lerp(to: Color(hex: "000020"), coef: 1 - c.luminosity * 10)
        }
        colors.enqueue(c)
        while enveloppes.count > 31 {
            _ = enveloppes.dequeue()
        }
        while colors.count > 31 {
            _ = colors.dequeue()
        }
        let rot = Rot3(phi: ß.time * 0.2170441, theta: (sin(ß.time * 0.13766117) * 0.5 + 0.5) * ß.π)
        main.matrix = rot.matrix
        let mp = (main.matrix.inverse * Vec4(y:-1).normalized).xyz
        particles.direction = mp * 0.05 * 60 / fps // speed
        if let b = material.texture as? Bitmap {
            self.enveloppeColor(to: b, col: colors)
        }
        if let b = material.height as? Bitmap {
            self.enveloppeHeight(to: b, env: enveloppes)
        }
        if let b = material2.texture as? Bitmap {
            self.enveloppeColor(to: b, col: colors)
        }
        if let b = material2.height as? Bitmap {
            self.enveloppeHeight(to: b, env: enveloppes)
        }
        let g = Graphics(image: output, depthClear: 1)
        renderer!.render(to: g, size: output.size)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    /*
    func enveloppeHeight(to b: Bitmap) {
        let g = Graphics(image: b)
        for yi in 0...31 {
            let y = Double(yi)
            g.fill(rect: Rect(0, y, 64, 1), color: Color(a: 1, l: Signal(y / 32).bounce.value))
        }
    }
     */
    func enveloppeHeight(to b: Bitmap, env: [Double]) {
        let g = Graphics(image: b)
        var y = 31 - Double(env.count)
        var i = 1
        g.fill(rect: b.bounds, color: .black)
        for e in env {
            let coef = Signal(Double(i) / 32).pow(2).value * 4
            g.fill(rect: Rect(0, y, 64, 1), color: Color(a: 1, l: e * coef))
            y += 1
            i += 1
        }
    }
    func enveloppeColor(to b: Bitmap, col: [Color]) {
        let g = Graphics(image: b)
        g.fill(rect: b.bounds, color: .aeViolet * 0.3)
        var y = 31 - Double(col.count)
        var i = 1
        for c in col {
            let coef = Signal(Double(i) / 32).pow(2).value * 2
            g.fill(rect: Rect(0, y, 64, 1), color: Color(a: 1, rgb: c * coef))
            y += 1.0
            i += 1
        }
        if let c = col.last {
            g.fill(rect: Rect(0, y, 64, 1), color: Color(a: 1, rgb: c * 0.6))
        }
    }
    
    class MeshUber : MeshOld {
        public init(parent:NodeUI,length:Double,radius:Double) {
            super.init(parent:parent)
            self.zz {
                let mat = "material.default"
                self.faces[mat]=[Int32]()
                let cylinder = Cylinder(center:.zero,direction:Vec3(y:length),radius:radius)
                var y = cylinder.center - cylinder.direction*0.5
                let fy = 32
                let ft = 64
                let dy = cylinder.direction/Double(fy)
                for yi in 0...fy {
                    for ai in 0..<ft {
                        let a = ß.π * 2 * (Double(ai) / Double(ft) + 0.001)
                        let n = Vec3(x:cos(a),y:0,z:sin(a))
                        let p = y + n * cylinder.radius
                        self.vertices.append(Vertex(position:p,normal:n,uv:Point(Double(ai)/Double(ft),Double(yi)/Double(fy))))
                    }
                    y += dy
                }
                for y in 0..<fy {
                    let yy = y * ft
                    for ai in 0..<ft {
                        let p0 = yy + ai
                        let p3 = yy + ai + ft
                        let p1 = (ai<ft-1) ? p0+1 : p0 - (ft - 1)
                        let p2 = (ai<ft-1) ? p3+1 : p3 - (ft - 1)
                        self.faces[mat]!.append(Int32(p2))
                        self.faces[mat]!.append(Int32(p1))
                        self.faces[mat]!.append(Int32(p0))
                        self.faces[mat]!.append(Int32(p0))
                        self.faces[mat]!.append(Int32(p3))
                        self.faces[mat]!.append(Int32(p2))
                    }
                }
                self.dispatchInitialized()
            }
        }
    }

}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
