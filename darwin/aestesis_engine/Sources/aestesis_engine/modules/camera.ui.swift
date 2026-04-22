//
//  Camera.ui.swift
//  flutter_alib
//
//  Created by renan jegouzo on 04/11/2023.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CameraUI: ModuleUI {
    var cameras = SynchronizedDictionnary<String, Camera>()
    var current: Int? = nil
    var flutterOutput : FlutterBitmap?
    override init(parent: NodeUI, id: String) {
        super.init(parent: parent, id: id)
        output.value = SharedBitmap(parent: self, size: composition!.settings.size)
        flutterOutput = FlutterBitmap(parent: self, assetId: id, size: (Size(320,180)*Device.screenScale).round)
    }
    override func detach() {
        for c in cameras.values {
            c.detach()
        }
        flutterOutput?.detach()
        flutterOutput = nil
        super.detach()
    }
    override func update() {
        guard module != nil else { return }
        if cameras.count != module!.assets?.count {
            for a in module!.assets! where !cameras.has(key: a!.id) {
                let cam = Camera(parent: self, deviceId: a!.id)
                cam.start()
                cam.onNewFrame.alive(self) { [weak self] in
                    guard let self = self, self.attached, let module = module else { return }
                    if let preview = cam.preview, preview.texture != nil {
                        if let c = self.current, let i = module.assets!.firstIndex(where: { $0!.id == a!.id }), c == i {
                            self.output.value = preview
                            bg { [weak self] in
                                guard let self = self, self.attached, let output = flutterOutput else { return }
                                let g = Graphics(image:output)
                                g.draw(rect:output.bounds,image:preview,from:preview.bounds.crop(output.bounds.ratio))
                                g.onDone { [weak self] _ in
                                    guard let self=self, self.attached else { return }
                                    output.updated()
                                }
                            }
                        }
                        self.updateAssetOutput(assetId: a!.id, bitmap: preview)
                    }
                }
                cameras[a!.id] = cam
            }
            let remove = cameras.keys.filter { id in
                return !module!.assets!.contains(where: { $0!.id == id })
            }
            for id in remove {
                cameras[id]?.detach()
                cameras[id] = nil
            }
        }
        module![CameraControl.asset.id]!.count = Int64(module!.assets?.count ?? 0)        
    }
    override func process(
        time: Double, dtime: Double, beat: Double, dbeat: Double, fps:Double, audio: AudioAnalyzer.Info
    ) {
        let control = module![CameraControl.asset.id]!
        if Int(control.value) != current && control.count > 0 {
            current = Int(control.value)
        } else if control.count == 0 {
            current = nil
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
