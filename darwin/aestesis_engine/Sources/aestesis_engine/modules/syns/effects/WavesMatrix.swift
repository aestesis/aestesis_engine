//
//  Matrix.swift
//  waves
//
//  Created by renan jegouzo on 23/05/2016.
//
//

import Foundation

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class WavesMatrix : WavesEffect {
    struct Colors {
        var low:Color
        var medium:Color
        var high:Color
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    var _output:Bitmap?
    override var output : Bitmap? {
        return _output
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    let len = 64
    var swap=[Bitmap?](repeating:nil,count:2)
    var image:Bitmap?
    var data:[UInt32]?
    var current = 0
    var toggle = false
    var colors:Colors = Colors(low:.aeOrange,medium:.aeGreen,high:.aeAqua)
    var boost:EQH = EQH(low: 1, medium: 1, high: 1)
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    required init(parent:NodeUI,size:Size) {
        super.init(parent: parent, size: size)
        swap[0] = Bitmap(parent:self,size:size)
        swap[1] = Bitmap(parent:self,size:size)
        image = Bitmap(parent:self,size:Size(len*2,2))
        data = [UInt32](repeating:0,count:Int(size.width*size.height))
    }
    convenience init(parent:NodeUI,size:Size,colors:Colors,boost:EQH) {
        self.init(parent:parent,size:size)
        self.colors = colors
        self.boost = boost
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func detach() {
        image?.detach()
        image = nil
        for b in swap {
            b?.detach()
        }
        swap.removeAll()
        super.detach()
    }
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func render(_ time: Double, fps:Double, audio: AudioAnalyzer.Info, _ fn: @escaping ()->()) {
        guard let image = image, let sw0 = swap[current], image.attached, sw0.attached else { return }
        current = (current+1) % swap.count
        guard let sw1 = swap[current], sw1.attached else { return }
        for i in 0...1 {
            var sb = i * len * 3
            var sm = i * len * 3 + len
            var st = i * len * 3 + len * 2
            let adr = i * Int(image.size.width)
            for x in 0..<len {
                let c=Color(a:1,rgb:colors.low*Double(audio.bass[sb])*boost.low+colors.medium*Double(audio.medium[sm])*boost.medium+colors.high*Double(audio.treeble[st])*boost.high).saturated
                data![adr + x] = c.bgra
                data![adr + (len * 2 - 1) - x] = c.bgra
                sb += 1
                sm += 1
                st += 1
            }
        }
        bg { [weak self] in
            guard let self=self, self.attached else { return }
            image.set(pixels:self.data!)
            let g=EffectGraphics(image:sw0)
            g.drawCross(rect:sw0.bounds,source:image,blend:BlendMode.add,color:Color(a:1,l:0.2))
            g.drawCross(rect:sw0.bounds.scale(2),source:image,blend:BlendMode.sub,color:Color(a:1,l:0.2))
            if audio.peak<0.01 {
                g.fill(rect:sw0.bounds,blend:BlendMode.sub,color:Color(a:1,l:0.005))
            }
            self.toggle = !self.toggle
            g.onDone { [weak self] ok in
                guard let self=self, self.attached else { return }
                self._output = sw0
                sw1.blurFrom(source: sw0, sigma: 1) { [weak self] in
                    guard let self=self, self.attached else { return }
                    fn()
                }
            }
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
