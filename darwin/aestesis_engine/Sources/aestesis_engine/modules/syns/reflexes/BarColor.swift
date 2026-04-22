//
//  Barcode.swift
//  waves
//
//  Created by renan jegouzo on 22/06/2016.
//
//

import Foundation
import aestesis_alib

class BarColor : Reflex {
    var palette : Bitmap?
    override init(parent: NodeUI) {
        super.init(parent:parent)
        palette = Bitmap(parent: self, size: Size(128,1))
    }
    override func detach() {
        if let p = palette {
            p.detach()
            palette = nil
        }
        super.detach()
    }
    override func draw(graphics g: Graphics, rect: Rect, time: Double, audio: AudioAnalyzer.Info, power: Double) {
        if let palette = palette {
            let range : (Double)->(Double) = { x in
                return x * 0.5 + 0.5
            }
            var data = [UInt32](repeating:0, count:128)
            var x = time*0.1
            let dx = 2.0 * ß.π / 128
            for i in 0..<128 {
                let c = Color(a:1,rgb:Color(r:range(sin(x)),g:range(sin(x*1.19811)),b:range(sin(x*0.91651641)))*power*0.4)
                data[i] = c.bgra
                x += dx
            }
            palette.set(pixels:data)
            g.draw(rect: rect , image: palette, blend: .sub, rotation: .clockwise)
        }
    }
}
