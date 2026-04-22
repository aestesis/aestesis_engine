//
//  fx.dynamic.mushroom.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 03/08/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FxDynamicDrop: Fx {
    var fft = [Float](repeating: 0, count:  256)
    let diagonal:Double = 588
    var ratio:Double = 0
    var bfield:Bitmap?
    var bsprite:Bitmap?
    var params = [Parameter2(complexity: 4),Parameter2(complexity: 4)]
    override init(parent: NodeUI) {
        super.init(parent: parent)
        bsprite = Bitmap(parent: self, size: Size(32,32), format: .float2)
        initSprite()
    }
    override func detach() {
        bfield?.detach()
        bfield=nil
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
        guard let bfield = bfield, let bsprite=bsprite else { return }
        for i in 0..<fft.count {
            fft[i] = fft[i] * 0.3 + audio.fft.amplitude[i] * 0.7
        }
        bfield.gaussianBlur(sigma: 6 * 60/fps)
        let gb = Graphics(image:bfield)
        var sprites = [PointSprite]()
        let r = bfield.bounds.diagonal*0.7
        let c = bfield.bounds.center
        for i in 0..<fft.count {
            let t = time * 1.5 + Double(i) * 0.2
            let p0 = params[0].sin(t)*r
            let p1 = params[1].sin(t)*r
            let l:Double = Double(fft[i]) * 0.5 * level
            let s:Double = (Double(fft.count - i) * 0.03 + 2) * Double(fft[i]) * 5
            sprites.append(PointSprite(position:c + p0,scale:s,color:Color(l:l)))
            sprites.append(PointSprite(position:c - p0,scale:s,color:Color(l:l)))
            sprites.append(PointSprite(position:c + p1,scale:s,color:Color(l:l)))
            sprites.append(PointSprite(position:c - p1,scale:s,color:Color(l:l)))
        }
        gb.fill(rect: bfield.bounds, blend: .alpha, color: Color(a:0.01,l:0))
        gb.draw(sprites: sprites, image: bsprite, blend: .add)
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
                // g.draw(rect:output.bounds,image:bfield)
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
    
    private func initSprite() {
        guard let sp = bsprite else { return }
        let w = Int(sp.pixels.width)
        let h = Int(sp.pixels.height)
        let c = sp.pixels.point(0.5,0.5) - Point(0.5,0.5)
        var data:[SIMD2<Float>] = [SIMD2<Float>](repeating: SIMD2<Float>(), count: w*h)
        var i:Int = 0
        for y in 0..<h {
            for x in 0..<w {
                let d = (Point(Double(x),Double(y)) - c) / (sp.pixels * 0.5)
                data[i] = ((-d).normalize * max(0, 1 - d.length)).infloat2
                i += 1
            }
        }
        sp.set(pixels: data)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
