//
//  bitmap.output.swift
//  flutter_alib
//
//  Created by renan jegouzo on 05/12/2023.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class FlutterBitmap: SharedBitmap {
    static let useFlutterTexture = true
    var flutterTexture: AEFlutterTexture?
    public init(
        parent: ModuleUI, assetId: String, size: Size, file: String = #file, line: Int = #line
    ) {
        super.init(parent: parent, size: size, file: file, line: line)
#if DEBUG
        self["debug"] = "\(parent.module!.name): \(parent.id).\(assetId)"
#endif
        if FlutterBitmap.useFlutterTexture {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.flutterTexture = AEFlutterTexture(image: self)
                self.flutterTexture?.publish(moduleId: parent.id, assetId: assetId)
            }
        }
    }
    deinit {
        if let flutterTexture = flutterTexture {
            DispatchQueue.main.async {
                flutterTexture.unregister()
            }
        }
    }
    override func updated() {
        flutterTexture?.updated()
        super.updated()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
