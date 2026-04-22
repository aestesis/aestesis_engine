//
//  Disco.swift
//  waves
//
//  Created by renan jegouzo on 11/06/2016.
//
//

import Foundation
import aestesis_alib

class Disco : Reflex {
    var sprites=[[PointSprite]]()
    var sprite:Bitmap?=nil
    override init(parent: NodeUI) {
        super.init(parent:parent)
        sprite=Bitmap(parent:self,path:"Sprites/sprite-32.png",bundle: Bundle(for: Disco.self))
    }
    override func detach() {
        if let sp=sprite {
            sp.detach()
            sprite = nil
        }
        super.detach()
    }
    override func draw(graphics g: Graphics, rect: Rect, time: Double, audio: AudioAnalyzer.Info, power: Double) {
        if let sprite = sprite {
            let ns = 20
            let center = rect.center
            let r0 = min(rect.w,rect.h) * 0.4
            var a = time * 0.1
            var b = time * 0.115465164141
            let da = ß.π * 2 / Double(ns)
            let db = ß.π * (3 + sin(time*0.001015451651)) / Double(ns)
            var ps = [PointSprite]()
            let scale = power*rect.height/1024 + 0.001
            for _ in 1...ns {
                let r = (r0 * sin(b*10*ß.π*0.45) + r0) * 0.5
                ps.append(PointSprite(position: center + Point(cos(a),sin(a)) * r,scale:scale,color:Color(a:1,l:0.7)))
                ps.append(PointSprite(position: center + Point(cos(a+ß.π),sin(a+ß.π)) * r,scale:scale,color:Color(a:1,l:0.7)))
                a += da
                b += db
            }
            g.draw(sprites:ps,image:sprite,blend: .add)
            var scp = 0.8
            if sprites.count>0 {
                for i in 1...sprites.count {
                    let ps=sprites[sprites.count-i]
                    g.draw(sprites:ps,image:sprite,scale:scp,blend: .add)
                    scp *= 0.8
                }
            }
            if sprites.count>8 {
                let _ = sprites.dequeue()
            }
            sprites.enqueue(ps)
        }
    }
}
