//
//  composition.preview.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 23/02/2024.
//

import Foundation
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class CompositionPreview: NodeUI {
    let onClose = Event<Void>()
    var window: OsWindow?
    private var closed = false
    public var ratio: Double {
        get {
            return window?.ratio ?? 16 / 9
        }
        set {
            if let w = window {
                let changed = w.ratio != newValue
                w.ratio = newValue
                if changed {
                    DispatchQueue.main.async {
                        let osize = w.frame.size
                        let size = NSSize(
                            width: w.frame.width, height: w.frame.width / CGFloat(newValue))
                        Debug.info(
                            "preview window resize to fit new aspect ratio: \(newValue) -> \(size) from \(osize)"
                        )
                        w.setContentSize(size)
                    }
                }
            }
        }
    }
    init(parent: NodeUI, ratio: Double) {
        super.init(parent: parent)
        DispatchQueue.main.async {
            let window = OsWindow(
                frame: CGRect(x: 0, y: 0, width: 1280, height: 1280 / ratio),
                title: "aestesis preview")
            window.onStartUI.once { viewport in
                viewport.rootView = PreviewView(viewport: viewport)
            }
            window.ratio = ratio
            //window.center()
            window.makeKeyAndOrderFront(nil)
            window.isReleasedWhenClosed = false
            window.onClose.once { [weak self] in
                guard let self = self else { return }
                RunLoop.composition.perform {
                    self.closed = true
                    self.onClose.dispatch(())
                }
            }
            self.window = window
        }
    }
    override func detach() {
        if !closed, let window = window {
            DispatchQueue.main.async {
                window.close()
            }
        }
        window = nil
        onClose.removeAll()
        super.detach()
    }
    func push(image: SharedBitmap) {
        guard let window = window, let preview = window.rootView as? PreviewView, preview.attached
        else { return }
        preview.image = image
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
private class PreviewView: View {
    var image: SharedBitmap?
    override init(viewport: Viewport) {
        super.init(viewport: viewport)
        var lastId: Double = 0
        viewport.pulse.alive(self) {
            if let image = self.image {
                self.needsRedraw = image.generandom != lastId
                lastId = image.generandom
            }
        }
    }
    override func draw(to g: Graphics) {
        guard let image = image else { return }
        g.draw(rect: bounds, image: image)
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
