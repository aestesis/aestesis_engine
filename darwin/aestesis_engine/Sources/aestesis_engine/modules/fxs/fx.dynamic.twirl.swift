//
//  fx.dynamic.twirl.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 08/08/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxDynamicTwirl: Fx {
    let count = 1024
    let diagonal:Double = 588
    var ratio:Double = 0
    var polar:Bitmap?
    var bfield:Bitmap?
    let param = Parameter2(complexity: 4)
    let pamp = Parameter(complexity: 4)
    override init(parent: NodeUI) {
        super.init(parent: parent)
        polar = Bitmap(parent: self, size: Size(count, 1), format: .float2)
    }
    override func detach() {
        bfield?.detach()
        bfield=nil
        polar?.detach()
        polar=nil
        super.detach()
    }
    override func render(time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, input: Bitmap, output: Bitmap, level: Double,
                         _ fn: @escaping () -> Void
    ) {
        if ratio != output.bounds.ratio {
            ratio = output.bounds.ratio
            bfield?.detach()
            bfield = Bitmap(parent: self, size: Size(diagonal:diagonal,ratio:ratio).round, format: .float2)
        }
        guard let bfield = bfield, let polar=polar else { return }
        updatePolar(audio: audio, level: level)
        bfield.gaussianBlur(sigma: 10 * 60/fps)
        let gb = EffectGraphics(image:bfield)
        // gb.fill(rect: bfield.bounds, blend: .alpha, color: Color(a:0.0004,l:0))

        let c = bfield.bounds.center
        
        let t = time * 2
        let p0 = param.sin(t)*bfield.bounds.diagonal*0.003
        let s:Double = bfield.bounds.diagonal*1.1
        let co = Color(l:0.1)
        let bm = BlendMode.add

        gb.draw(rect:Rect(origin:c+p0,size:Size(1,1)).scale(s),polar:polar,amplitude: Point(1,pamp.sin(t*0.03175361)),blend:bm,color:co)


        gb.onDone { [weak self] ok in
            switch ok {
            case .discarded:
                break
            case .error(let message):
                Debug.warning(message)
            case .success:
                guard let self = self, self.attached else { return }
                let g = EffectGraphics(image: output)
                g.draw(rect:output.bounds,image:input,from:input.bounds.crop(output.bounds.ratio),field:bfield)
                g.onDone { [weak self] ok in
                    guard let self = self, self.attached else { return }
                    switch ok {
                    case .discarded:
                        break
                    case .error(let message):
                        Debug.warning(message)
                    case .success:
                        fn()
                    }
                }
            }
        }
    }
    
    func updatePolar(audio:AudioAnalyzer.Info, level: Double) {
        var n = audio.samples.count - count
        var data = [SIMD2<Float>](repeating: .zero, count: count)
        for i in 0..<count {
            let s = audio.samples[n]
            let r = pow(Float(i) / Float(count),0.5) * Float(level)
            let a = pow(1 - Float(i) / Float(count),0.4) * Float(level)
            let ss:Float = audio.bass[n] + audio.medium[n]
            data[i] = SIMD2<Float>(ss*r,s*a)
            n += 1
        }
        polar?.set(pixels: data)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
