//
//  Memorium.swift
//  waves
//
//  Created by renan jegouzo on 23/05/2016.
//
//

import Foundation

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class WavesMemorium : WavesEffect {
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override var output:Bitmap? {
        return _output
    }
    var _output:Bitmap?
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var imgson:Bitmap?=nil
    var data=[UInt32](repeating: 0,count: 128*1)
    var image=[Bitmap?](repeating:nil,count:2)
    var current=0
    var timeV:Double=0
    var oldColor = Color.black
    var ww=[Double](repeating: 0,count: 8)
    var rendering = false
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    required init(parent:NodeUI,size:Size) {
        super.init(parent: parent, size: size)
        imgson=Bitmap(parent:self,size:Size(128,1))
        image[0]=Bitmap(parent:self,size:size)
        image[1]=Bitmap(parent:self,size:size)
        for i in 0..<ww.count {
            ww[i] = 0.1 + ß.rnd * 0.9
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func detach() {
        while rendering {
            Thread.sleep(0.01)
        }
        if let b=imgson {
            b.detach()
            imgson=nil
        }
        for b0 in image {
            if let b=b0 {
                b.detach()
            }
        }
        image.removeAll()
        super.detach()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func render(_ time: Double, fps:Double, audio: AudioAnalyzer.Info, _ fn: @escaping ()->()) {
        let color=Color(a:1,r:Double(audio.eq.low),g:Double(audio.eq.medium*2),b:Double(audio.eq.high*2)).saturated
        let imgZyg=image[current]
        current = (current+1) % 2
        let imgBlur=image[current]
        timeV += Double(audio.peak)
        oldColor = Color.black //color.lerp(to:oldColor*0.25,coef:0.5) * 0.25
        if let imgson=imgson {
            let len=Int(imgson.pixels.width)
            var s=audio.samples.count-len
            for x in 0..<len {
                let f=min(Double(abs(audio.samples[s])),1) // TODO: add adjustable amp
                let a=Double(len-x-1)/Double(len-1)
                let c=oldColor.lerp(to:color,coef:f)*a
                data[x] =  Color(a:1,rgb:c).bgra
                s += 1
            }
            imgson.set(pixels:data)
        }
        if let imgZyg=imgZyg, let imgBlur=imgBlur, let imgson=self.imgson {
            bg { [weak self] in
                guard let self=self, self.attached, imgZyg.attached, imgBlur.attached, imgson.attached else { return }
                let g=EffectGraphics(image:imgZyg)
                var sz:Double = imgZyg.size.length * 0.72
                let wx = 1 / (self.ww[0]+self.ww[1]+self.ww[2]+self.ww[3])
                let wy = 1 / (self.ww[4]+self.ww[5]+self.ww[6]+self.ww[7])
                var x = sin(time*2.1272)*self.ww[0]
                x += sin(time*0.6565777)*self.ww[1]
                x += sin(time*0.04657767)*self.ww[2]
                x += sin(time*0.05789843)*self.ww[3]
                x = x * wx * 0.5 + 0.5
                var y = sin(time*1.07677)*self.ww[4]
                y += sin(time*1.6687671)*self.ww[5]
                y += sin(time*0.08687906)*self.ww[6]
                y += sin(time*0.01668879)*self.ww[7]
                y = y * wy * 0.5 + 0.5
                let fuckingSwiftX = sin(time*10.7878176)+sin(time*2.5898989)*0.25
                x *= fuckingSwiftX*0.4+0.5
                let fuckingSwiftY = sin(time*10.2638832)+sin(time*2.6576764)*0.25
                y *= fuckingSwiftY*0.4+0.5
                x *= imgZyg.size.width
                y *= imgZyg.size.height
                let isz=imgZyg.size
                g.drawCircleFromRayon(rect:Rect(x:x-sz*0.5,y:y-sz*0.5,w:sz,h:sz),source:imgson,blend:BlendMode.add)
                g.drawCircleFromRayon(rect:Rect(x:isz.w-x-sz*0.5,y:y-sz*0.5,w:sz,h:sz),source:imgson,blend:BlendMode.add)
                g.drawCircleFromRayon(rect:Rect(x:x-sz*0.5,y:isz.h-y-sz*0.5,w:sz,h:sz),source:imgson,blend:BlendMode.add)
                g.drawCircleFromRayon(rect:Rect(x:isz.w-x-sz*0.5,y:isz.h-y-sz*0.5,w:sz,h:sz),source:imgson,blend:BlendMode.add)
                
                var xs:Double = sin(time*2.767675)*self.ww[0]
                xs += sin(time*0.676868)*self.ww[1]
                xs += sin(time*0.07687)*self.ww[2]
                xs += sin(time*0.0877865)*self.ww[3]
                xs = xs * wx * 0.5 + 0.5
                var ys:Double = sin(time*1.076786878)*self.ww[4]
                ys += sin(time*1.6768778)*self.ww[5]
                ys += sin(time*0.0876787)*self.ww[6]
                ys += sin(time*0.01767687)*self.ww[7]
                ys = ys * wy * 0.5 + 0.5
                let sinx = sin(time*10.88876787)+sin(time*2.45567657)*0.25
                xs *= (sinx)*0.4+0.5
                let siny = sin(time*10.66776878)+sin(time*2.1567876)*0.25
                ys *= (siny)*0.4+0.5
                xs *= imgZyg.size.width
                ys *= imgZyg.size.height
                sz *= 2
                let cs=Color(a:1,l:0.2)
                g.drawCircleFromRayon(rect:Rect(x:xs-sz*0.5,y:ys-sz*0.5,w:sz,h:sz),source:imgson,blend:BlendMode.sub,color:cs)
                g.drawCircleFromRayon(rect:Rect(x:isz.w-xs-sz*0.5,y:ys-sz*0.5,w:sz,h:sz),source:imgson,blend:BlendMode.sub,color:cs)
                g.drawCircleFromRayon(rect:Rect(x:xs-sz*0.5,y:isz.h-ys-sz*0.5,w:sz,h:sz),source:imgson,blend:BlendMode.sub,color:cs)
                g.drawCircleFromRayon(rect:Rect(x:isz.w-xs-sz*0.5,y:isz.h-ys-sz*0.5,w:sz,h:sz),source:imgson,blend:BlendMode.sub,color:cs)
                g.fill(rect:imgZyg.bounds,blend:BlendMode.sub,color:Color(a:1,l:0.01))
                g.onDone { [weak self] ok in
                    guard let self=self, self.attached else { return }
                    self._output = imgZyg
                    imgBlur.blurFrom(destination:imgBlur.bounds,source:imgZyg,sigma:1.6) { [weak self] in
                        guard let self=self, self.attached else { return }
                        fn()
                    }
                }
            }
        }
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
