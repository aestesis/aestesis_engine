//
//  syn.swarm.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 11/02/2024.
//

import Foundation
import simd
// MTLMeshRenderPipelineDescriptor

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynSagittarius: SynRenderer {
    var collection:ObjectCollection?
    var data:[Data] = []
    let gradient = ColorGradient([0.0:Color(hex:"#260BAF"),0.25:Color(hex:"#C3068E"),0.75:Color(hex:"#D9FF00"),1.0:Color(hex:"#01FCA8")])
    var freq:[Double] = [Double](repeating: 0, count: 320)
    var populated = false
    let paramCam:Parameter3 = Parameter3()
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let world = Node3D(parent: renderer!)
        renderer!.world = world
        renderer!.camera = Camera3D(parent: world, position: Vec3(z: -12), direction: Vec3(z: 1))
        let _ = Mirror(parent: world, matrix: Mat4.rotX(ß.π2))
        let _ = Mirror(parent: world, matrix: Mat4.rotY(ß.π2))
        let p = Cube()
        collection = ObjectCollection(parent: world, mesh: p.mesh(factor:p.defaultFactor), materials: [Material(blend:.add)])
        zz { [ weak self ] in
            self?.populateCollection()
        }
    }
    func populateCollection() {
        guard let collection=collection else { return }
        let count = 3000
        let dr:Double = 50 / Double(count)
        let da:Double = 300 / Double(count)
        let dg:Double = 1 / Double(count)
        let dl:Double = 1 / Double(count)
        var r:Double = 0
        var a:Double = 0
        var g:Double = 0
        var l:Double = 0
        for _ in 1...count {
            let p = Point(angle: a, radius: r)
            let c = Color(a:1,h:g,s:0.5,l:0.1)
            //let c = gradient.value(g)*(0.7+pow(l,0.4)*0.3)
            data.append(Data(a:a,r:r,p:Vec3(p),color:c))
            collection.instances.append(Instance(matrix: .translation(Vec3(p)), color:c))
            r += dr
            a += da
            g += dg
            l += dl
        }
        populated = true
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard populated, let renderer = renderer, let collection = collection, let camera=renderer.camera else { return }
        
        for i in 0..<freq.count {
            freq[i] = freq[i] * 0.4 + Double(audio.fft.amplitude[i]) * 0.6
        }
        
        let t = Mat4.translation(collection.matrix.translation)
        collection.matrix = Mat4.rotZ(time * 0.141546416) * Mat4.rotY(time * 0.0276761751) * Mat4.rotX(time * 0.076761751) * t
        var f:Double = 0
        let df:Double = 1/Double(collection.instances.count)
        for i in 0..<collection.instances.count {
            let d = data[i]
            let t = (time + Double(i)*0.01116)
            let t0 = ((sin(t*1.15561)+sin(t*0.916716)+2) * 0.25)*2*ß.π
            let t1 = ((sin(t*1.017151)+sin(t*0.9316716)+2) * 0.25)*2*ß.π
            let s:Double = ß.lerp(array:freq,coef:f)*(1+f*9)
            collection.instances[i].matrix = Mat4.scale(Vec3(x:s*200,y:s*20,z:s*20)) * Mat4.rotation(phi: t0, theta:t1) * Mat4.translation(d.p)
            f += df
        }
        
        camera.matrix.translation = paramCam.sin(time*0.3)*10
        camera.lookAt(node: collection)
        
        let g = Graphics(image: output, clear: Color(hex:"000020"),depthClear: 1)
        renderer.render(to: g, size: output.size)
        g.onDone { [weak self] ok in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    struct Data {
        var a:Double
        var r:Double
        var p:Vec3
        var color:Color
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
