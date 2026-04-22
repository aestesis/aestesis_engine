//
//  Trash.swift
//  waves
//
//  Created by renan jegouzo on 19/11/2017.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class WavesMental : WavesEffect {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var _output:Bitmap?
    override var output: Bitmap? {
        return _output
    }
    var pixn:Bitmap?
    var image:Bitmap?
    var gradient:Bitmap?
    let frameDuration : Double = 0.067
    var framePrevious: Double = 0
    required init(parent: NodeUI, size: Size) {
        super.init(parent:parent,size:size)
        _output = Bitmap(parent:self,size:size)
        image = Bitmap(parent:self,size:size)
        pixn = Bitmap(parent:self,size:Size(256,1))
        gradient = ColorGradient([0:.black,0.5:.black,0.51:Color(a:1,l:0.4),1:Color(a:1,l:0.4)]).createBitmap(parent:self, width:16)
    }
    override func detach() {
        if let b=pixn {
            b.detach()
            pixn=nil
        }
        if let b=pixn {
            b.detach()
            pixn=nil
        }
        if let b=image {
            b.detach()
            image=nil
        }
        if let b=gradient {
            b.detach()
            gradient=nil
        }
        if let b=_output {
            b.detach()
            _output=nil
        }
        super.detach()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func render(_ time: Double, fps:Double, audio: AudioAnalyzer.Info, _ fn: @escaping ()->()) {
        if time - framePrevious < frameDuration {
            return
        }
        framePrevious = time
        if let output=_output, let image=image, let gradient=gradient, let pixn = pixn {
            var pixels = [UInt32](repeating:0,count:256)
            for i in 0..<pixels.count {
                let n = i<128 ? i : 255-i
                let v = Double(abs(audio.bass[n]+audio.medium[n]*0.3+audio.treeble[n]*0.1))  // Double(abs(audio.samples[n]))
                let c = Color(a:1,l:v).saturated
                pixels[i] = c.bgra
            }
            pixn.set(pixels:pixels)
            let gi = EffectGraphics(image:image)
            gi.drawCross(rect:image.bounds,source:pixn)
            let g = Graphics(image:output)
            g.draw(rect:output.bounds,image:image,gradient:gradient)
            g.onDone { [weak self] ok in
                guard let self = self, self.attached else { return }
                fn()
            }
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

