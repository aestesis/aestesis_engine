//
//  fx.test.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 26/04/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxTest: Fx {
    let count = 1024
    let diagonal:Double = 588
    var ratio:Double = 0
    var baudio:Bitmap?
    var bfield:Bitmap?
    let param = Parameter2(complexity: 4)
    let pamp = Parameter(complexity: 4)
    override init(parent: NodeUI) {
        super.init(parent: parent)
        bfield = Bitmap(parent: self, size: Size(512, 288), format: .float2)
        ratio = bfield!.bounds.ratio
        baudio = Bitmap(parent: self, size: Size(count, 1), format: .float)
    }
    override func detach() {
        bfield?.detach()
        bfield=nil
        baudio?.detach()
        baudio=nil
        super.detach()
    }
    override func render(time: Double, dtime: Double, fps:Double, audio: AudioAnalyzer.Info, input: Bitmap, output: Bitmap, level: Double,
                         _ fn: @escaping () -> Void
    ) {
        if ratio != output.bounds.ratio {
            ratio = output.bounds.ratio
            bfield?.detach()
            bfield = Bitmap(parent: self, size: Size(diagonal:diagonal,ratio:ratio), format: .float2)
        }
        guard let bfield = bfield, let baudio=baudio else { return }
        updatePolar(audio: audio, level: level)
        bfield.gaussianBlur(sigma: 20 * 60/fps)
        let gb = EffectGraphics(image:bfield)
        gb.fill(rect: bfield.bounds, blend: .alpha, color: Color(a:0.0004,l:0))

        let c = bfield.bounds.center
        
        let t = time * 2
        let p0 = param.sin(t)*bfield.bounds.diagonal*0.003
        let s:Double = bfield.bounds.diagonal*1.1
        let co = Color(l:0.05)
        let bm = BlendMode.add

        gb.draw(rect:Rect(origin: bfield.bounds.center,size:.unity).scale(max(bfield.size.width,bfield.size.height)),cartesian:baudio,blend:bm,color:co)


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
    
    func updatePolar(audio:AudioAnalyzer.Info, level:Double) {
        var fft = audio.fft.amplitude
        fft.blur(sigma:5)
        var n = 0
        var data = [Float](repeating: .zero, count: count)
        var n1 = count / 2
        var n0 = n1 - 1
        var s:Float = 0
        var m:Float = 1
        while n0>0 {
            s += fft[n] * m
            data[n0] = s * Float(level)
            data[n1] = -s * Float(level)
            n += 1
            n0 -= 1
            n1 += 1
            s *= 0.9
            m *= 1.01
        }
        baudio?.set(pixels: data)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
