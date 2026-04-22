//
//  fx.dynamic.punch.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 22/05/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxDynamicPunch: Fx {
    var eq = EQ()
    var bdata:Bitmap?
    var data:[Float]=[Float](repeating: 0, count: 64)
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
        g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),polar:bpolar)
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    
    func updatePolar(audio:AudioAnalyzer.Info, level: Double) {
        eq = audio.eq * 0.5 + eq * 0.5
        data.insert(eq.low+eq.medium+eq.high, at: 0)
        data.removeLast()
        var rayon = [Float](repeating: 0, count: data.count)
        let dr:Float = 2/Float(data.count)
        var r:Float = 0
        var a:Float = 1
        for i in 0..<data.count {
            r -= data[i]*0.045*a*Float(level)  // very sensible constant value, don't change
            rayon[i] = r
            r += dr
            a *= 0.99
        }
        bdata?.set(pixels: rayon)
    }
    
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
