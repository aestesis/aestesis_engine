//
//  Spine.swift
//  waves
//
//  Created by renan jegouzo on 26/05/2016.
//
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class WavesSpline: WavesEffect {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    var _output: Bitmap?
    override var output: Bitmap? {
        return _output
    }
    var swap = [Bitmap?](repeating: nil, count: 2)
    var palette: Bitmap?
    var spalette: Bitmap?
    var sprite: Bitmap?
    var lastFrame = ß.time
    var fps: Double = 0
    var current: Int = 0
    var rendering = false
    var lastChange: Double = 0
    var cval: Double = 0
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    required init(parent: NodeUI, size: Size) {
        super.init(parent: parent, size: size)
        swap[0] = Bitmap(parent: self, size: size)
        swap[1] = Bitmap(parent: self, size: size)
        sprite = Bitmap(
            parent: self, path: "Sprites/sprite-gris-16x32-no-alpha.png",
            bundle: Bundle(for: WavesSpline.self))
        _output = Bitmap(parent: self, size: size)
        computerPalette()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func detach() {
        while rendering {
            Thread.sleep(0.01)
        }
        _output?.detach()
        _output = nil
        for p in swap {
            p?.detach()
        }
        swap.removeAll()
        palette?.detach()
        palette = nil
        spalette?.detach()
        spalette = nil
        sprite?.detach()
        sprite = nil
        super.detach()
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func render(
        _ time: Double, fps: Double, audio: AudioAnalyzer.Info, _ fn: @escaping () -> Void
    ) {
        if let src = swap[current & 1], let dst = swap[(current + 1) & 1], let sprite = sprite,
            let output = _output
        {
            if audio.envelope > cval {
                if time - lastChange > 30 {
                    cval = audio.envelope * 1.001
                    lastChange = time
                    computerPalette()
                } else {
                    cval = audio.envelope * 1.001
                }
            } else {
                cval *= 0.9995
            }
            let gp = Graphics(image: spalette!)
            gp.draw(
                rect: spalette!.bounds, image: palette!, blend: .alpha, color: Color(a: 0.1, l: 1))

            dst.blurFrom(
                destination: dst.bounds.scale(1, 1 + 0.1 * 20 / fps), source: src, sigma: 0.4
            ) { [weak self] in
                guard let self = self else { return }
                let mid = dst.bounds.center
                var s = audio.samples.count - Int(mid.x) / 5
                let spscale = 4 * dst.size.height / 256
                let spmin: Double = 0.7
                let g = Graphics(image: dst)
                var sprites = [PointSprite]()
                var n = 0
                sprites.append(
                    PointSprite(
                        position: mid, scale: spscale * Double(abs(audio.samples[s])) + spmin,
                        color: Color.white))
                n += 1
                s += 1
                var x: Double = 6
                while x < mid.x {
                    let ss = spscale * Double(abs(audio.samples[s])) + spmin
                    s += 1
                    sprites.append(
                        PointSprite(position: mid.translate(x, 0), scale: ss, color: Color.white))
                    n += 1
                    sprites.append(
                        PointSprite(position: mid.translate(-x, 0), scale: ss, color: Color.white))
                    n += 1
                    x += 6
                }
                g.fill(
                    rect: dst.bounds, blend: BlendMode.sub, color: Color(a: 1, l: 0.03 * 30 / fps))
                g.draw(sprites: sprites, image: sprite, blend: BlendMode.add)
                g.onDone { [weak self] ok in
                    guard let self = self else { return }
                    self.bg { [weak self] in
                        guard let self = self else { return }
                        if output.attached {
                            let g = EffectGraphics(image: output)
                            g.paletize(
                                rect: output.bounds, source: dst, palette: self.spalette!,
                                offset: Point(0, 0), blend: BlendMode.copy, color: Color.white)
                            g.onDone { [weak self] ok in
                                guard let self = self else { return }
                                fn()
                                self.rendering = false
                            }
                        }
                    }
                }
            }
            current += 1
        }
    }
    func computerPalette() {
        var icolors: [Double: Color] = [Double: Color]()
        let n = 10 + Int(ß.rnd * 5)
        for i in 0...n {
            icolors[Double(i) / Double(n)] =
                Color(h: ß.rnd, s: 0.8, l: 0.4 * pow(Double(i) / Double(n), 0.1)).saturated
                * Color(hex: "FF5020")
        }
        let gr = ColorGradient(icolors)
        palette = gr.createBitmap(parent: self, width: 64)
        if spalette == nil {
            spalette = gr.createBitmap(parent: self, width: 64)
        }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
