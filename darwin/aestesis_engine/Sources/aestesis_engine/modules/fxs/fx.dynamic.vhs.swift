//
//  fx.dynamic.vhs.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 24/05/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxDynamicVHS: Fx {
    var data:[Float] = [Float](repeating: 0, count: 256)
    var bdata:Bitmap?
    override init(parent: NodeUI) {
        super.init(parent: parent)
        bdata = Bitmap(parent: self, size: Size(data.count, 1), format: .float)
    }
    override func detach() {
        bdata?.detach()
        bdata=nil
        super.detach()
    }
    override func render(time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, input: Bitmap, output: Bitmap, level: Double,
        _ fn: @escaping () -> Void
    ) {
        guard let bpolar = bdata else { return }
        updatePolar(audio: audio, level: level)
        let g = EffectGraphics(image: output)
        g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),vhs:bpolar)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    
    func updatePolar(audio:AudioAnalyzer.Info, level:Double) {
        var n = audio.bass.count - data.count
        var pixels = [Float](repeating: 0, count: 256)
        for i in 0..<data.count {
            data[i] = data[i]*0.9+audio.bass[n]*0.1
            pixels[i] = data[i] * Float(level)
            n += 1
        }
        bdata?.set(pixels: pixels)
    }
    
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
