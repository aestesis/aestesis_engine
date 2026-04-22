//
//  Kiss.swift
//  waves
//
//  Created by renan jegouzo on 19/05/2016.
//
//

import Foundation
import aestesis_alib

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class WavesKiss : WavesEffect {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override var output:Bitmap? {
        return _output
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var _output:Bitmap?
    var swap=[Bitmap?](repeating:nil,count:2)
    var current:Int = 0
    var sprite:Bitmap?=nil
    var functions:[(_ time:Double,_ v:Double)->(Vec3)]?
    var size:Size
    var rendering = false
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    required init(parent:NodeUI,size:Size) {
        self.size = size
        super.init(parent: parent, size: size)
        sprite = Bitmap(parent:self,path:"Sprites/sprite-blanc.png", bundle: Bundle(for: WavesKiss.self))
        swap[0] = Bitmap(parent:self,size:size)
        swap[1] = Bitmap(parent:self,size:size)
        functions=[triangle,star,quad,ovale]
        shuffleFunctions()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func detach() {
        while rendering {
            Thread.sleep(0.01)
        }
        _output?.detach()
        _output = nil
        sprite?.detach()
        sprite=nil
        swap[0]?.detach()
        swap[1]?.detach()
        swap.removeAll()
        functions?.removeAll()
        functions=nil
        super.detach()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func render(_ time: Double, fps:Double, audio: AudioAnalyzer.Info, _ fn:@escaping ()->())  {
        //let t=ß.time
        let scale=0.15/(fps/25)+1
        let vv = (self.size.height/512)
        let o = _output ?? Bitmap(parent:self,size:self.size)
        let swap = self.swap[current]!
        current = (current + 1) % 2
        let old = self.swap[current]!
        rendering = true
        swap.blurFrom(destination:o.bounds.scale(scale),source:old,sigma:vv) { [weak self] in
            guard let self=self else { return }
            if swap.attached {
                let g=Graphics(image:swap)
                let sp=self.sprite!
                let f=self.functions!
                let c=Color(a:1,r:Double(audio.eq.low*0.08),g:Double(audio.eq.medium*0.15),b:Double(audio.eq.high*0.15)).saturated
                let zz=pow(o.size.height/256,0.5)
                var ps = [PointSprite]()
                for i in 0..<100 {
                    let mix = (time*0.1987789).truncatingRemainder(dividingBy: Double(f.count))
                    let f1 = Int(mix)
                    let f2 = (f1+1) % f.count
                    let mval = mix-Double(f1)
                    let v = ß.π*Double(i)/100
                    let vec = f[f1](time,v) * (1-mval) + f[f2](time,v) * mval
                    let p=Point(vec.x,vec.y) * o.size
                    ps.enqueue(PointSprite(position:p,scale:(vec.z*zz),color:c))
                }
                g.draw(sprites:ps,image:sp,blend:BlendMode.add)
                g.fill(rect:o.bounds,blend:BlendMode.sub,color:Color(a:1,l:0.04))
                if ß.rnd<0.0001 {
                    self.shuffleFunctions()
                }
                g.onDone { [weak self] ok in
                    guard let self=self else { return }
                    self._output = swap
                    fn()
                    self.rendering = false
                }
            } else {
                self.rendering = false
            }
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    func shuffleFunctions() {
        for i in 0..<functions!.count-1 {
            if ß.rnd<0.5 {
                let f=functions![i]
                functions![i] = functions![i+1]
                functions![i+1] = f
            }
        }
    }
    func triangle(_ time:Double,v:Double) -> Vec3 {
        let zobx = (sin (time * 1.008771) * 0.1 + 0.9) * 0.2
        var x = cos (time + v * 2.0) * zobx
        x += 0.5
        let zoby = (sin (time * 1.001609) * 0.1 + 0.9) * 0.2
        var y = sin (time + v * 2) * zoby
        y += 0.5
        let z = sin (time * 0.17292 + v * 6.0) * 0.5 + 1.0
        return Vec3( x: x, y: y, z: z)
    }
    func star(_ time:Double,v:Double) -> Vec3 {
        let tz = sin (time * 1.1245 + v * 4)
        let z = sin (time * 1.1245 + v * 8)
        let near = tz * 0.3 + 0.7
        let x0 = cos (time + v * 2)
        let x1 = sin (time * 1.008771) * 0.1 + 0.9
        let y0 = sin (time + v * 2)
        let y1 = sin (time * 1.001609) * 0.1 + 0.9
        return Vec3( x: x0 * x1 * near * 0.2 + 0.5,
                     y: y0 * y1 * near * 0.2 + 0.5,
                     z: z * 0.5 + 1)
    }
    func quad(_ time:Double,v:Double) -> Vec3 {
        let zobx = (sin (time * 1.008771) * 0.1 + 0.9)
        var x = cos (time + v * 2.0) * zobx * 0.2
        x += 0.5
        let zoby = (sin (time * 1.001609) * 0.1 + 0.9)
        var y = sin (time + v * 2.0) * zoby * 0.2
        y += 0.5
        return Vec3( x: x,
                     y: y,
                     z: sin (time * 0.17292 + v * 8.0) * 0.5 + 1.0)
    }
    func ovale(_ time:Double,v:Double) -> Vec3 {
        let tz = sin (time * 1.1245 + v * 2)
        let z = sin (time * 1.1245 + v * 4)
        let near = tz * 0.3 + 0.7
        let x0 = cos (time + v * 2)
        let x1 = sin (time * 1.008771) * 0.1 + 0.9
        let y0 = sin (time + v * 2)
        let y1 = sin (time * 1.001609) * 0.1 + 0.9
        return Vec3( x: x0 * x1  * near * 0.2 + 0.5,
                     y: y0 * y1 * near * 0.2 + 0.5,
                     z: z * 0.5 + 1)
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
