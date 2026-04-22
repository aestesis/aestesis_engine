//
//  Potatoes.swift
//  waves
//
//  Created by renan jegouzo on 11/06/2016.
//
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Potatoes : Reflex {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    let npot = 6
    var potatoes = [Potatoe]()
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override init(parent: NodeUI) {
        super.init(parent: parent)
        for p in 0..<npot {
            potatoes.append(Potatoe(parent:self,phase:Double(p)/Double(npot)))
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func detach() {
        for p in potatoes {
            p.detach()
        }
        potatoes.removeAll()
        super.detach()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func draw(graphics g: Graphics, rect: Rect, time: Double, audio: AudioAnalyzer.Info, power: Double) {
        for p in potatoes {
            p.draw(graphics: g, rect: rect, time: time, audio: audio, power: power)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    class Potatoe : NodeUI {
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        let points = 12
        var radius:[Double]
        var target:[Double]
        var offset:Double
        var amplitude:Double
        var phase:Double
        var frame = 0
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        init(parent:NodeUI,phase:Double) {
            self.phase = phase
            offset = ß.rnd * 1000 * ß.π
            amplitude = (ß.rnd + 0.5)
            radius=[Double](repeating:0,count:points)
            target=[Double](repeating:0,count:points)
            super.init(parent: parent)
            radius = gen()
            target = gen()
        }
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        func gen() -> [Double] {
            var v=[Double](repeating: 0,count: points)
            var o = 0.0
            for i in 0..<points {
                if (i % 3) == 0 {
                    o = ß.rnd * 0.8 + 0.2
                    v[i] = o
                } else {
                    var r = 0.0
                    while r<o {
                        r = ß.rnd * 0.8 + 0.2
                    }
                    v[i] = r
                }
            }
            return v
        }
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        func draw(graphics g: Graphics, rect: Rect, time: Double, audio: AudioAnalyzer.Info, power: Double) {
            frame += 1
            let center=rect.center
            let t=time*amplitude*0.3+offset
            let path = Path()
            let cc = Color(h: (phase+time*0.001415561).truncatingRemainder(dividingBy:1.0), s: 0.5, b: 0.5)
            let paint = Paint(parent: self, mode: .fill, blend: .add, color: Color(a:power, rgb:cc*0.1))
            var p = [Point](repeating:Point.zero,count:points)
            var a = t
            let da = ß.π * 2 / Double(points)
            let r = min(rect.w,rect.h)*0.6
            for i in 0..<points {
                p[i] = center + Point(cos(a)*r*radius[i],sin(a)*r*radius[i])
                a += da
            }
            path.append(Path.Segment.moveTo(p[0]))
            path.append(Path.Segment.cubicTo(p[1], p[2], p[3]))
            path.append(Path.Segment.cubicTo(p[4], p[5], p[6]))
            path.append(Path.Segment.cubicTo(p[7], p[8], p[9]))
            path.append(Path.Segment.cubicTo(p[10], p[11], p[0]))
            g.draw(path,paint)
            for i in 0..<points {
                radius[i] = radius[i]*0.999 + target[i] * 0.001
            }
            if (frame & 1023) == 0 {
                target = gen()
            }
        }
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
