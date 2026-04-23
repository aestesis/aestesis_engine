//
//  extensions.swift
//  AestesisEnginePlugin
//
//  Created by renan jegouzo on 27/10/2023.
//

import Foundation
import aestesis_alib

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension CompositionStatistics {
    func send() {
        DispatchQueue.main.async {
            AestesisEnginePlugin.message?.statistics(statistics: self) { result in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    Debug.error("send statistics error \(error.localizedDescription)")
                }
            }
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension AudioLevel {
    func send() {
        DispatchQueue.main.async {
            AestesisEnginePlugin.message?.audio(level: self) { result in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    Debug.error("send audio levels error \(error.localizedDescription)")
                }
            }
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension CompositionSettings {
    var size: Size {
        return Size(width, height)
    }
    var bounds: Rect {
        return Rect(0, 0, width, height)
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension AudioSettings {
    static func equals(_ a: AudioSettings?, _ b: AudioSettings?) -> Bool {
        if let a = a, let b = b {
            return a.deviceName == b.deviceName && a.leftChannel == b.leftChannel
            && a.rightChannel == b.rightChannel
        } else if a == nil && b == nil {
            return true
        }
        return false
    }
    
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension Preview {
    func send() {
        DispatchQueue.main.async {
            AestesisEnginePlugin.message?.preview(preview: self) { result in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    Debug.error("send preview error \(error.localizedDescription)")
                }
            }
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension Asset: CustomStringConvertible {
    /*
    static func == (a: Asset, b: Asset) -> Bool {
        return a.id == b.id
    }
     */
    var description: String {
        return "Asset(id:\(id) name:\(name) uri:\(uri ?? ""))"
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension ControlType: CustomStringConvertible {
    var description: String {
        switch self {
        case .boolean:
            return "boolean"
        case .color:
            return "color"
        case .float:
            return "float"
        case .integer:
            return "integer"
        case .unit:
            return "unit"
        }
    }
}

extension Control: CustomStringConvertible {
    /*
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (a: Control, b: Control) -> Bool {
        return a.id == b.id
    }
     */
    mutating func setValue(from control: Control) {
        guard control.id == id else {
            Debug.error(
                "Control(id:\(id) name:\(name).valueFrom(Control(id:\(control.id) \(control.name)) id mistmatch"
            )
            return
        }
        value = control.value
        count = control.count
    }
    func send() {
        DispatchQueue.main.async {
            AestesisEnginePlugin.message?.control(control: self) { result in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    Debug.error("send control error \(error.localizedDescription)")
                }
            }
        }
    }
    var description: String {
        return "Control(module:\(moduleId) id:\(id) name:\(name) type:\(type) value:\(value))"
    }
    var color: Color {
        return Color(bgra: UInt32(count)).with(a: 1)
    }
    var blend: ControlBlendMode? {
        return ControlBlendMode(rawValue:Int(value))
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension AnalogControl {
    var id: String { return "AnalogControl.\(self)" }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension AnalogSourceControl {
    static let all: [AnalogSourceControl] = [.blendMode, .color, .opacity, .gain]
    func id(source: Module) -> String {
        return "AnalogSource.\(source.id).AnalogSourceControl.\(self)"
    }
    var name: String {
        switch self {
        case .blendMode:
            return "Blend Mode"
        case .color:
            return "Color"
        case .opacity:
            return "Opacity"
        case .gain:
            return "Gain"
        }
    }
    var type: ControlType {
        switch self {
        case .blendMode:
            return ControlType.integer
        case .color:
            return ControlType.color
        case .opacity:
            return ControlType.unit
        case .gain:
            return ControlType.float
        }
    }
    var value: Double {
        switch self {
        case .blendMode:
            return Double(ControlBlendMode.normal.rawValue)
        case .color:
            return 0
        case .opacity:
            return 0
        case .gain:
            return 0
        }
    }
    var count: Int64 {
        switch self {
        case .blendMode:
            return Int64(ControlBlendMode.all.count)
        case .color:
            return 0xFFFF_FFFF  // ARGB
        case .opacity:
            return 0
        case .gain:
            return 0
        }
    }
    static func controls(module: Module, source: Module) -> [Control] {
        return AnalogSourceControl.all.map { c in
            return Control(
                moduleId: module.id, id: c.id(source: source), type: c.type, name: c.name, value: c.value,
                count: c.count)
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension CameraControl {
    var id: String { return "CameraControl.\(self)" }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension FxControl {
    var id: String { return "FxControl.\(self)" }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension LutControl {
    var id: String { return "LutControl.\(self)" }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension PlayerControl {
    var id: String { return "PlayerControl.\(self)" }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension SynControl {
    var id: String { return "SynControl.\(self)" }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension ControlBlendMode {
    static let all: [ControlBlendMode] = [
        .normal, .add, .subtract, .multiply, .difference, .exclusion, .luma, .lumaAdd, .lumaSubtract, .lumaMultiply, .screen, .overlay, .darken,
        .lighten, .colorDodge, .colorBurn, .softLight, .hardLight, .glow, .linearLight, .negation,
        .phoenix, .reflect,
    ]
    var blendMode: BlendMode {
        switch self {
        case .normal:
            return .alpha
        case .add:
            return .add
        case .subtract:
            return .sub
        case .multiply:
            return .multiply
        case .difference:
            return .difference
        case .exclusion:
            return .exclusion
        case .negation:
            return .negation
        case .luma:
            return .luma
        case .lumaAdd:
            return .lumaAdd
        case .lumaSubtract:
            return .lumaSub
        case .lumaMultiply:
            return .lumaMultiply
        case .screen:
            return .screen
        case .overlay:
            return .overlay
        case .darken:
            return .darken
        case .lighten:
            return .lighten
        case .colorDodge:
            return .colorDodge
        case .colorBurn:
            return .colorBurn
        case .softLight:
            return .softLight
        case .hardLight:
            return .hardLight
        case .glow:
            return .glow
        case .linearLight:
            return .linearLight
        case .linearBurn:
            return .linearBurn
        case .phoenix:
            return .phoenix
        case .reflect:
            return .reflect
        }
    }
    var isLuma: Bool {
        return self == .luma || self == .lumaAdd || self == .lumaSubtract || self == .lumaMultiply
    }
}

/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension ModuleType {
    var isMixer: Bool {
        return self == .analog
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension Module: CustomStringConvertible {
    subscript(id: String) -> Control? {
        mutating get {
            if let index = controls!.firstIndex(where: { $0!.id == id }) {
                return controls![index]
            }
            return nil
        }
        mutating set(c) {
            let index = controls!.firstIndex(where: { $0!.id == id })
            controls![index!] = c
        }
    }
    var description: String {
        return "Module(id:\(id) name:\(name)"
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
extension Composition {
    subscript(id: String) -> Module? {
        mutating get {
            let index = modules.firstIndex(where: { $0!.id == id })
            if let index = index {
                return modules[index]
            }
            return nil
        }
        mutating set(c) {
            let index = modules.firstIndex(where: { $0!.id == id })
            modules[index!] = c
        }
    }
}
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
/// ///////////////////////////////////////////////////////////////////////////////////////////////////////
