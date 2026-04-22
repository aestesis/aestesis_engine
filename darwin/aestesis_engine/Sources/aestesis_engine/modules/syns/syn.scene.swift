//
//  syn.scene.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 10/02/2024.
//

import Foundation
import simd

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class SynScene: SynRenderer {
    let attenuation = Attenuation(quadratic:0.00003)
    var light1:PointLight?
    var light2:PointLight?
    var light3:PointLight?
    var light4:PointLight?
    var plight1 = Parameter3(complexity: 4)
    var plight2 = Parameter3(complexity: 4)
    var plight3 = Parameter3(complexity: 4)
    var plight4 = Parameter3(complexity: 4)
    var collection:ObjectCollection?
    var lcollection:ObjectCollection?
    
    var env0 = 0.0
    var cmode = 3
    var cval = 0.0
    var eval = 0.0
    var tcam = 0.0
    var eq = EQH()
    var lastChange:Double = 0
    var mlights:[Mlights] = []
    
    override init(parent: NodeUI) {
        super.init(parent: parent)
        let world = Node3D(parent:renderer!)
        let camera = Camera3D(parent:world,position:Vec3(z:150),direction:Vec3(z:-1))
        renderer!.world = world
        renderer!.camera = camera

        let material = Material(ambient:Color(hex:"000020"),diffuse:Color(hex:"788acd"),specular:Color(hex:"f1c40f"),shininess:80)
        let sphere = Sphere(radius: 30)
        collection = ObjectCollection(parent: world, mesh: sphere.mesh(factor:30), materials: [material])
        populateGrid(collection: collection!)
        
        light1 = PointLight(parent:collection!,position:.zero,color:Color(hex:"#e74c3c"),attenuation:attenuation)
        light2 = PointLight(parent:collection!,position:.zero,color:Color(hex:"#3498db"),attenuation:attenuation)
        light3 = PointLight(parent:collection!,position:.zero,color:Color(hex:"#9b59b6"),attenuation:attenuation)
        light4 = PointLight(parent:collection!,position:.zero,color:Color(hex:"#050520"),attenuation:attenuation)
        
        var lmesh = Sphere(radius:6).mesh(factor:10)
        lmesh.cullMode = .none
        let lmaterial = Material(blend:.add,ambient:Color(hex:"FFFFFF"))
        lcollection = ObjectCollection(parent: collection!, mesh: lmesh, materials: [lmaterial])
    }
    func populateGrid(collection:ObjectCollection) {
        let N=3
        let space=100.0
        for z in -N...N {
            for y in -N...N {
                for x in -N...N {
                    let t = Vec3(x:Double(x),y:Double(y),z:Double(z))*space
                    collection.instances.append(Instance(matrix:Mat4.translation(t)))
                }
            }
        }
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, output: Bitmap,
        _ fn: @escaping () -> Void
    ) {
        guard let renderer=renderer, let camera=renderer.camera, let collection=collection, let lcollection=lcollection, let world=renderer.world else { return }
        guard let light1=light1, let light2=light2, let light3=light3, let light4=light4 else { return }
        let g = Graphics(image: output,clear: Color(hex:"000020"),depthClear: 1)
        
        if audio.envelope>cval {
            if time-lastChange>0.05 {
                cval = audio.envelope*1.001
                cmode = Int(ß.rnd*4)
                lastChange = time
            } else {
                cval = audio.envelope*1.001
            }
        } else {
            cval *= 0.9995
        }
        
        env0 = env0*0.7 + audio.envelope*0.3
        eq = eq*0.8 + EQH(audio.eq)*0.2
        
        let lcolor=Color(r:eq.low,g:eq.medium,b:eq.high).saturated
        light1.color = lcolor
        light2.color = lcolor
        light3.color = lcolor
        light4.color = lcolor

        let rr:Double = 240
        light1.position = plight1.sin(time*4)*rr
        light2.position = plight2.sin(time*4)*rr
        light3.position = plight3.sin(time*4)*rr
        light4.position = plight4.sin(time*4)*rr
        
        mlights.enqueue(Mlights(light1:Mlight(light1),light2: Mlight(light2),light3: Mlight(light3),light4: Mlight(light4)))
        while mlights.count>100 {
            _ = mlights.dequeue()
        }
        
        lcollection.instances.removeAll()
        
        var s:Double=1
        for i in stride(from: mlights.count-1, through: 0, by: -1) {
            let ml = mlights[i]
            lcollection.instances.append(Instance(matrix:Mat4.scale(Vec3(s,s,s))*Mat4.translation(ml.light1.position),color:light1.color))
            lcollection.instances.append(Instance(matrix:Mat4.scale(Vec3(s,s,s))*Mat4.translation(ml.light2.position),color:light2.color))
            lcollection.instances.append(Instance(matrix:Mat4.scale(Vec3(s,s,s))*Mat4.translation(ml.light3.position),color:light3.color))
            lcollection.instances.append(Instance(matrix:Mat4.scale(Vec3(s,s,s))*Mat4.translation(ml.light4.position),color:light4.color))
            s *= 0.95
        }
        switch cmode {
        case 3:
            eval = eval * 0.99 + audio.envelope * 0.01
            tcam += eval*0.5
            camera.position = self.cam(time:tcam)
            camera.direction = (self.cam(time:tcam+0.001)-camera.position).normalized
            collection.matrix = Mat4.rotX(time*0.541546416)*Mat4.rotY(time*0.676761751)
        case 2:
            camera.position = Vec3.zero
            camera.direction = Vec3(z:1)
            collection.matrix = Mat4.rotX(time*1.141546416)*Mat4.rotY(time*0.576761751)
        case 1:
            camera.position = Vec3(z:-30+env0*30)
            camera.direction = Vec3(z:1)
            collection.matrix = Mat4.rotX(time*0.1141546416)*Mat4.rotY(time*0.0576761751)
        default:
            camera.position = Vec3(z:300-env0*450)
            camera.lookAt(node: world)
            collection.matrix = Mat4.rotX(time*1.141546416)*Mat4.rotY(time*0.576761751)
        }
        
        renderer.render(to: g, size: output.size)
        g.onDone { [weak self] ok in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    func cam(time:Double) -> Vec3 {
        return Vec3(x:sin(time*0.1)+sin(time*0.01657151),y:sin(time*0.1545151)+sin(time*0.0156571),z:sin(time*0.1851451)+sin(time*0.016111131))*50.0
    }
    struct Mlight {
        let position:Vec3
        let color:Color
        init(_ light:PointLight) {
            position = light.position
            color = light.color
        }
    }
    struct Mlights {
        let light1:Mlight
        let light2:Mlight
        let light3:Mlight
        let light4:Mlight
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
