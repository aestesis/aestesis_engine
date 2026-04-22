//
//  fx.dynamic.pulse.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 15/05/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxDynamicPulse: Fx {
    var power:[Double] = []
    override init(parent: NodeUI) {
        super.init(parent: parent)
    }
    override func detach() {
        super.detach()
    }
    override func render(
        time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, input: Bitmap, output: Bitmap, level: Double,
        _ fn: @escaping () -> Void
    ) {
        power.enqueue(Double(audio.eq.low)+Double(audio.eq.medium)+Double(audio.eq.high))
        while power.count>3 {
            power.dequeue()
        }
        
        let g = Graphics(image: output,clear: .transparent)
        let l = incArray(count: power.count)
        var n = 0
        for p in power {
            g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio).scale(1/(1+p*level)),blend:.add,color:Color(a:1,l:l[n]))
            n += 1
        }
        
        g.onDone { [weak self] _ in
            guard let self = self, self.attached else { return }
            fn()
        }
    }
    
    func incArray(count:Int) -> [Double] {
        var l:[Double] = []
        var sum:Double = 0
        for i in stride(from:1,through: count,by:1) {
            l.append(Double(i))
            sum += Double(i)
        }
        return l.map { $0 / sum }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
