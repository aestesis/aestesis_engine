//
//  syn.hanna.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 08/02/2024.
//

import Foundation
import simd
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynHanna: SynRenderer {
    let gradient = ColorGradient([0: Color.aeOrange, 0.8: Color(hex: "FF1050"), 1: Color(hex: "A00000")])
    var collection: ObjectCollection?
  //  var cube: Node3D?
    var freq:[Double] = [Double](repeating: 0, count: 256)
    let param = Parameter3(complexity: 4)
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let world = Node3D(parent: renderer!)
        renderer!.world = world
        let camera = Camera3D(parent: world, position: Vec3(z: -40), direction: Vec3(z: 1))
        renderer!.camera = camera
        _ = DirectionalLight(
            parent: world, direction: Vec3(x: 1, y: -1, z: 1).normalized, color: .white, intensity: 1)
/*
        self["material.eq3d.cylinder.cube"] = MaterialOld(
            parent: self, name: "eq3d.cylinder.cube", cull: .back, ambient: Color(hex: "000020"),
            diffuse: Color(hex: "000020"), specular: .white, shininess: 40)
        cube = Node3D(parent: world)
        let _ = ObjectOld(
            parent: cube!, box: Box(center: .zero, size: Vec3(x: 1, y: 1, z: 1) * 300.0),
            material: "material.eq3d.cylinder.cube",inversNormals: true)
*/
        let cnode = Node3D(parent: world)
        let _ = Mirror(parent: cnode, matrix: Mat4.scale(Vec3(x: -1, y: 1, z: 1)))
        let _ = Mirror(parent: cnode, matrix: Mat4.scale(Vec3(x: -1, y: -1, z: 1)))
        let _ = Mirror(parent: cnode, matrix: Mat4.scale(Vec3(x: 1, y: -1, z: 1)))

        let cyl = Cylinder(direction:Vec3(y:5),radius:1)
        var mesh = cyl.mesh()
        mesh.cullMode = .none
        collection = ObjectCollection(parent: cnode, mesh: mesh, materials: [Material(blend:.add)])
        populate(collection:collection!)
    }
    func populate(collection:ObjectCollection) {
        for i in 0..<freq.count {
            let c = gradient.value(Double(i) / Double(freq.count))
            collection.instances.append(Instance(color:c))
        }

    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let renderer = renderer, let collection = collection else { return }
        let g = Graphics(image: output, clear: Color(hex: "000000"), depthClear: 1)

        for i in 0..<freq.count {
            freq[i] = freq[i] * 0.4 + Double(audio.fft.amplitude[i]) * (0.6 + 2*Double(i)/Double(freq.count))
        }

        var rot = Rot3(phi: time * 0.141546416, theta: time * 0.576761751)
        var t = time * 10
        for i in 0..<collection.instances.count {
            let p = param.sin(-t*0.5)*100
            let m1:Mat4 = Mat4.scale(Vec3(x: 0.1 + Double(freq[i]) * 10, y: 0.1 + Double(freq[i]) * 50, z: 0.1 + Double(freq[i]) * 10))
            let m2:Mat4 = rot.matrix
            let m3:Mat4 = Mat4.translation(p)
            collection.instances[i].matrix = m1 * m2 * m3
            rot += 0.02
            t += 0.3
        }
        collection.matrix = Rot3(phi: time * 0.341546416, theta: time * 0.276761751).matrix
        renderer.render(to: g, size: output.size)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    
    func sumFft(audio:AudioAnalyzer.Info) -> [Float] {
        let fft = audio.fft.amplitude
        var sfft: [Float] = []
        var fi = 0
        for _ in 0...63 {
            let v:Float = fft[fi]+fft[fi+1]+fft[fi+2]+fft[fi+3]
            sfft.append(v)
            fi += 4
        }
        return sfft
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
