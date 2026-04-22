//
//  syn.test.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 10/02/2024.
//

import Foundation
import simd

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynCygnus: SynRenderer {
    static let fsize = 512
    var light:Light?
    var collection:ObjectCollection?
    let paramPos = Parameter3(complexity: 4)
    let paramScale = Parameter3(complexity: 4)
    var frequencies:Bitmap?
    var texture:Bitmap?
    let gradient:ColorGradient = ColorGradient([-1: .white, 0: .black, 1: .white])
    var eq = EQH()
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let world = Node3D(parent:renderer!)
        renderer!.world = world
        renderer!.camera = Camera3D(parent: world,position: Vec3(0,0,-2),direction: Vec3(0,0,2))
        light = DirectionalLight(parent: world, direction: Vec3(x: 0, y: 0, z: -1).normalized, color: .white, intensity: 1)

        let _ = Mirror(parent: world, matrix: Mat4.scale(Vec3(x: -1, y: -1, z: 1)))

        frequencies = Bitmap(parent:self,size:Size(Double(SynCygnus.fsize*2),1))
        texture = Bitmap(parent:self,size:Size(Double(SynCygnus.fsize),Double(SynCygnus.fsize)))
        self["mat.texture"] = texture
        let material = Material(blend:.add,ambient:Color(l:0.1),diffuse:Color(l:0.6),specular:Color(l:1),shininess:2, texture: "mat.texture")
        let prim = Sphere(radius:2)
        var mesh = prim.mesh()
        mesh.cullMode = .none
        collection = ObjectCollection(parent: world, mesh: mesh, materials: [material])
        collection!.instances = [Instance](repeating: Instance(), count: 300)
        for i in 0..<collection!.instances.count {
            collection!.instances[i].color = Color(a:1,l:0.3+0.15*Double(i)/Double(collection!.instances.count))
        }
    }
    override func detach() {
        super.detach()
    }
    override func render(time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap, _ fn: @escaping () -> Void) {
        guard let collection=collection, let renderer = renderer, let texture=texture, let frequencies=frequencies else { return }
        let fsize = SynCygnus.fsize
        var pixels = [UInt32](repeating: 0, count: SynCygnus.fsize * 2)
        eq = EQH(audio.eq) * 0.3 + eq * 0.7
        let ceq = Color(a: 1, r: eq.low , g: eq.medium * 2.5, b: eq.high * 4)
        for i in 0..<fsize {
            let v = Double(audio.samples[audio.samples.count-fsize+i])
            let c = gradient.value(v)*0.15*ceq
            let cv = c.saturated.bgra
            pixels[SynCygnus.fsize-i-1] = cv
            pixels[SynCygnus.fsize+i] = cv
        }
        frequencies.set(pixels: pixels)
        
        for i in 0..<collection.instances.count {
            let di = Double(i)*0.1
            collection.instances[i].matrix = Mat4.scale(paramScale.sin(time+di)) * Mat4.rotation(phi: time * 0.176152 + di, theta: time * 0.2189111 + di) *  Mat4.translation(paramPos.sin(time*2 + di)*4)
        }

        let ge = EffectGraphics(image:texture)
        ge.drawCross(rect: texture.bounds, source: frequencies)
        ge.onDone { [weak self] _ in
            guard let self=self, self.attached, output.attached else { return }
            let g = Graphics(image: output)
            g.fill(rect: output.bounds, blend: .sub, color: Color(a:1,l:0.05))
            renderer.render(to: g, size: output.size)
            g.onDone { [weak self] _ in
                guard let self = self, self.attached else { return }
                fn()
            }
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

