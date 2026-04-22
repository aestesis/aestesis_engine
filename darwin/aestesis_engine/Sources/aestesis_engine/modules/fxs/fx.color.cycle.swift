//
//  fx.color.clash.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 18/05/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxColorCycle: Fx {
    var eq = EQ()
    var bdata:Bitmap?
    var data:[Float]=[Float](repeating: 0, count: 64)
    override init(parent: NodeUI) {
        super.init(parent: parent)
        bdata = Bitmap(parent: self, size: Size(data.count*2, 1), format: .height)
    }
    override func detach() {
        bdata?.detach()
        bdata=nil
        super.detach()
    }
    override func render(time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, input: Bitmap, output: Bitmap, level: Double,
        _ fn: @escaping () -> Void
    ) {
        guard let bfft = bdata else { return }
        updateFFT(audio: audio, level: level)
        let g = EffectGraphics(image: output)
        if level == 1 {
            g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),hsvDecal:bfft,color:Color(a:1,l:2))
        } else {
            let il = 1 - level
            g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),color:Color(a:1,l:il))
            if level>0 {
                g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),hsvDecal:bfft,blend:.add,color:Color(a:1,l:2*level))
            }
        }
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    
    func updateFFT(audio:AudioAnalyzer.Info,level:Double) {
        var dint = [UInt16](repeating: 0, count: data.count*2)
        eq = audio.eq * 0.5 + eq * 0.5
        data.insert(min(eq.low+eq.medium+eq.high,1)*65535, at: 0)
        data.removeLast()
        var i = 0
        var j = data.count*2-1
        for v in data {
            dint[i] = UInt16(v)
            dint[j] = UInt16(v)
            i += 1
            j -= 1
        }
        bdata?.set(pixels: dint)
    }
    
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
