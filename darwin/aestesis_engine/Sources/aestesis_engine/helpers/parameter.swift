//
//  parameter.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 16/02/2024.
//

import Foundation
import aestesis_alib

struct Parameter3 {
    var x:Parameter
    var y:Parameter
    var z:Parameter
    init(complexity:Int = 1) {
        x = Parameter(complexity: complexity)
        y = Parameter(complexity: complexity)
        z = Parameter(complexity: complexity)
    }
    func sin(_ time:Double) -> Vec3 {
        return Vec3(x.sin(time),y.sin(time),z.sin(time))
    }
}
struct Parameter2 {
    var x:Parameter
    var y:Parameter
    init(complexity:Int = 1) {
        x = Parameter(complexity: complexity)
        y = Parameter(complexity: complexity)
    }
    func sin(_ time:Double) -> Point {
        return Point(x.sin(time),y.sin(time))
    }
}
struct Parameter {
    var t:[Double]
    var a:[Double]
    var p:[Double]
    let suma:Double
    init(complexity:Int = 1) {
        t = []
        a = []
        p = []
        var suma:Double = 0
        for _ in 0..<complexity {
            t.append(ß.rnd)
            p.append(ß.rnd*ß.π*2)
            let va = ß.rnd
            a.append(va)
            suma += va
        }
        self.suma = suma
    }
    func sin(_ time:Double) -> Double {
        var s:Double = 0
        for i in 0..<t.count {
            s += Darwin.sin(p[i]+t[i]*time)*a[i]
        }
        return (s/suma)
    }
}
