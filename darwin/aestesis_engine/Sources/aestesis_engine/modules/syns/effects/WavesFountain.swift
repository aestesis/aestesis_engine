//
//  Fountain.swift
//  waves
//
//  Created by renan jegouzo on 25/05/2016.
//
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class WavesFountain : WavesEffect {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var _output:Bitmap?
    override var output: Bitmap? {
        return _output
    }
    var swap:Bitmap?
    var polar:Bitmap?
    var image:Bitmap?
    var data:[UInt32]?
    let seed=ß.rnd
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    required init(parent: NodeUI, size: Size) {
        super.init(parent:parent,size:size)
        polar = Bitmap(parent:self,size:Size(32,256))
        swap = Bitmap(parent:self,size: polar!.size)
        image = Bitmap(parent:self,size:Size(1,256))
        data = [UInt32](repeating:0, count:Int(image!.size.width * image!.size.height))
        _output = Bitmap(parent:self,size:size)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func detach() {
        swap?.detach()
        polar?.detach()
        image?.detach()
        _output?.detach()
        swap = nil
        polar = nil
        image = nil
        _output = nil
        super.detach()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func render(_ time: Double, fps:Double, audio: AudioAnalyzer.Info, _ fn: @escaping ()->()) {
        if let image=image, let polar=polar, let swap=swap, let output=_output {
            let scroll = 1
            let len:Int = Int(image.size.height) / 2
            let h = ß.modulo(seed + ß.time*0.003, 1.0)
            let hr = Color(a:1,h:(h+0.00).truncatingRemainder(dividingBy: 1.0),s:0.5,b:0.5)
            let hg = Color(a:1,h:(h+0.25).truncatingRemainder(dividingBy: 1.0),s:0.5,b:0.5)
            let hb = Color(a:1,h:(h+0.50).truncatingRemainder(dividingBy: 1.0),s:0.5,b:0.5)
            
            var s = audio.samples.count-len
            var d = 0
            let endm = (len * 2 - 1) * Int(image.size.width)
            
            for _ in 0..<len {
                let r = hr * abs(Double(audio.bass[s]))
                let g = hg * abs(Double(audio.medium[s]))
                let b = hb * abs(Double(audio.treeble[s]))
                let c = Color(a:1,rgb:((r+g+b)*4).saturated).bgra
                data![endm-d] = c
                data![d] = c
                s += 1
                d += Int(image.size.width)
            }
            image.set(pixels:data!)
            let g=Graphics(image:polar)
            g.draw(rect:Rect(x:0,y:0,w:Double(scroll),h:polar.size.height),image:image,from:Rect(x:0,y:0,w:1,h:polar.size.height))
            //var frame = viewport!.nframes
            g.onDone { [weak self] ok in
                guard let self=self, self.attached else { return }
                self.bg { [weak self] in
                    guard let self=self, self.attached else { return }
                    swap.blurFrom(source: polar, sigma: 0.8,sampler:"sampler.clamp.wrap") { [weak self] in
                        guard let self=self, self.attached, polar.attached else { return }
                        let g=Graphics(image:polar)
                        g.draw(rect:Rect(x:Double(scroll),y:0,w:swap.size.w,h:swap.size.h),image:swap,from:swap.bounds)
                        g.onDone { [weak self] ok in
                            guard let self=self, self.attached else { return }
                            self.bg { [weak self] in
                                guard let self=self, self.attached, output.attached, polar.attached else { return }
                                let g=EffectGraphics(image:output)
                                g.drawPolar(rect: output.bounds.fit(1),source:polar)
                                g.onDone { [weak self] ok in
                                    guard let self=self, self.attached else { return }
                                    fn()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
