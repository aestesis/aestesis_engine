//
//  Triad.swift
//  waves
//
//  Created by renan jegouzo on 28/05/2016.
//
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class Triad : Reflex {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func draw(graphics g:Graphics,rect:Rect,time: Double, audio: AudioAnalyzer.Info, power: Double) {
        let len=rect.center.length
        let mir=Signal.realTime(frequency:0.21516511,time:time).value*len
        let mar=Signal.realTime(frequency:0.22516511,time:time).value*len
        let r=Signal.realTime(period:0.122,time:time).sin.bounce.pow(4).bounce.exp.value*len
        let bass=min(1,Double(audio.eq.low)*100)
        
        let pa=Paint(parent:self)
        pa.color = Color(a:0.5*power,rgb:Color.blue*bass)
        pa.blend = BlendMode.screen
        
        g.circle(center:rect.center,radius:r,paint:pa)
        
        g.polygon(center: rect.center, count: 3, rotation: Signal.realTime(period:-0.1656765476,time:time).rotation, radius: mir, color: Color(a:0.7*power,l:0))
        
        drawArc(graphics:g,rect:rect,time:time,audio:audio,power:power)
        drawGone(graphics:g,rect:rect,time:time,audio:audio,power:power)
        
        let pb=Paint(parent:self)
        pb.color = Color(a:1,l:0.1*bass)
        pb.blend = .add
        g.rosace(center: rect.center, count: 5, rotation: Signal.realTime(period:0.1,time:time).rotation, r0: mir*power, r1: mar*power, paint: pb)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func drawArc(graphics g:Graphics,rect:Rect,time:Double,audio:AudioAnalyzer.Info,power:Double) {
        let len=rect.center.length
        let bass=min(1,Double(audio.eq.low)*100)
        let mir=Signal.realTime(frequency:0.21516511,time:time).value*len
        let mar=Signal.realTime(frequency:0.22516511,time:time).value*len
        let pa=Paint(parent:self)
        pa.color = Color(a:1,rgb:(Color(html:"FF2B2B")*(bass*0.5*power)).saturated)
        pa.blend = .add
        let nsec = 3
        let da = ß.π*2/Double(nsec)
        let rot = Signal.realTime(period:0.0118766565776566,time:time).rotation+Signal.realTime(frequency:0.001656756,time:time).value*Signal.realTime(period:0.7676587687,time:time).pow(0.1).rotation
        let per = Signal.realTime(frequency:0.187766576576,time:time).pow(0.4).value
        for i in 0..<nsec {
            let a = da*Double(i)+rot
            let a2 = da*per
            g.arcSector(center: rect.center, r0: mir, r1: mar, a0: a, a1: a+a2, paint: pa)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func drawGone(graphics g:Graphics,rect:Rect,time: Double, audio: AudioAnalyzer.Info, power: Double) {
        let len=rect.center.length
        let pa=Paint(parent:self)
        pa.color = Color(a:1,rgb:(Color.aeOrange*(0.5*power)).saturated)
        pa.blend = .screen
        let mi = Signal.realTime(frequency:0.121516511,time:time).value*len
        let ma = Signal.realTime(frequency:0.122516511,time:time).value*len
        let nsec = 11
        let da = ß.π*2/Double(nsec)
        let rot = Signal.realTime(period:0.0167678687687,time:time).rotation+Signal.realTime(frequency:0.001667565675,time:time).value*Signal.realTime(period:0.7767656556,time:time).pow(0.1).rotation
        let per = Signal.realTime(frequency:0.1656576567,time:time).pow(0.4).value*0.25
        for i in 0..<nsec {
            let a = da*Double(i)+rot
            let a2 = da*per
            let p:[Point] = [ rect.center.translate(Point(angle:a,radius:mi)),
                              rect.center.translate(Point(angle:a,radius:ma)),
                              rect.center.translate(Point(angle:a+a2,radius:ma)),
                              rect.center.translate(Point(angle:a+a2,radius:mi))]
            g.polygon(p,pa)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
