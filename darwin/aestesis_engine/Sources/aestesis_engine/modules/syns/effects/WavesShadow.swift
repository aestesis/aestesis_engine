//
//  DaShadow.swift
//  waves
//
//  Created by renan jegouzo on 16/12/2016.
//
//

import Foundation
import aestesis_alib

class WavesShadow : WavesEffect {
    var _output:Bitmap?
    var bw:Bitmap?
    override var output: Bitmap? {
        return _output
    }
    var baudio:Bitmap?
    var data = [UInt32](repeating:0,count:1024)
    var xcol = 0
    required init(parent:NodeUI,size:Size) {
        super.init(parent: parent, size: size)
        io {
            self._output = Bitmap(parent:self,size:size)
            self.bw = Bitmap(parent:self,size:size)
            self.baudio = Bitmap(parent:self,size:Size(8,128))
        }
    }
    override func detach() {
        if let b=_output {
            b.detach()
            _output=nil
        }
        if let b=bw {
            b.detach()
            bw=nil
        }
        if let b=baudio {
            b.detach()
            baudio=nil
        }
        super.detach()
    }
    override func render(_ time: Double, fps:Double, audio: AudioAnalyzer.Info, _ fn: @escaping ()->()) {
        if let bw=bw, let output=_output, let ba=baudio {
            let g=Graphics(image: bw)
            g.fill(rect: bw.bounds, color: .black)
            var y = xcol
            for i in 0..<128 {
                let c = Color(a:1,l:abs(Double(audio.samples[i])))
                data[y] = c.saturated.bgra
                y += 8
            }
            xcol = (xcol - 1) & 7
            ba.set(pixels:data)
            let steps = 100
            var vv = [Vertice]()
            let center = bw.bounds.center
            var r = center.length*1.5
            var a = 0.0
            let da = ß.π * 6 / Double(steps)
            var op = center+Point(angle:a-da,radius:r)
            var ol = 0.0
            var u = 0.0
            let du = 2.0 / Double(steps)
            let pow = 0.9
            for i in 0...steps {
                let l = Signal(Double(i)/Double(steps)).bounce.pow(0.8).value
                let p = center+Point(angle:a,radius:r)
                vv.append(Vertice(position:Vec3(center),uv:Point(u,1),color:Color(a:1,l:ol*pow)))
                vv.append(Vertice(position:Vec3(op),uv:Point(u,0),color:Color(a:1,l:ol*0)))
                vv.append(Vertice(position:Vec3(p),uv:Point(u+du,0),color:Color(a:1,l:l*0)))
                op = p
                a += da
                r *= 0.99
                ol = l
                u += du
            }
            g.draw(triangle:vv,image:ba,sampler:"sampler.mirror",blend:.add)
            let gg = Graphics(parent:g,matrix:Mat4.rotZ(ß.π,origin:Vec3(center)))
            gg.draw(triangle:vv,image:ba,sampler:"sampler.mirror",blend:BlendMode.add)
            g.onDone { [weak self] ok in
                guard let self=self else { return }
                switch ok {
                case .success:
                    self.bg { [weak self] in
                        guard let self=self, self.attached else { return }
                        let t=ß.modulo(ß.time*0.0031114514,1)
                        let st0 = ß.modulo(ß.time*0.0003165761,1)
                        let st1 = ß.modulo(ß.time*0.0003262652,1)
                        let t0=ß.modulo(t+0.0625+sin(st0)*0.03125, 1)
                        let t1=ß.modulo(t+0.33333+sin(st1)*0.11111, 1)
                        var gr = ColorGradient()
                        gr.add(0, .black)
                        gr.add(0.5, Color(a:1,h:t0,s:0.5,b:0.5))
                        gr.add(0.75, Color(a:1,h:t,s:0.5,b:0.75))
                        gr.add(1, Color(a:1,h:t1,s:0.33,b:0.9))
                        gr.process(source:bw,destination:output) { [weak self] ok in
                            guard let self = self, self.attached else { return }
                            switch ok {
                            case .error(let message):
                                Debug.error("error in Color.Gradient.process() \(message)",#file,#line)
                            default:
                                break
                            }
                            fn()
                        }
                    }
                case .error(let message):
                    Debug.warning("DaShadow error, skipping end of rendering \(message)",#file,#line)
                    fn()
                default:
                    fn()
                }
            }
        } else {
            Debug.warning("DaShadow error, skipping rendering",#file,#line)
            self.ui { [weak self] in
                guard let self = self, self.attached else { return }
                Debug.warning("DaShadow, sending OK anyway",#file,#line)
                fn()
            }
        }
    }
}
