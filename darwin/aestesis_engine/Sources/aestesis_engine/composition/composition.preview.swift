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
    public var ratio:Double {
        get {
            return window?.ratio ?? 16/9
        }
        set {
            window?.ratio = newValue
        }
    }
    init(parent: NodeUI, ratio:Double) {
        super.init(parent: parent)
        window = OsWindow(
            frame: CGRect(x: 0, y: 0, width: 1280, height: 720), title: "aestesis preview")
        window!.onStartUI.once { viewport in
            viewport.rootView = PreviewView(viewport: viewport)
        }
        window!.ratio = ratio
        window!.center()
        window!.makeKeyAndOrderFront(nil)
        window!.isReleasedWhenClosed = false
        window!.onClose.once { [weak self] in
            guard let self=self else { return }
            closed = true
            onClose.dispatch(())
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
        guard let window=window, let preview = window.rootView as? PreviewView, preview.attached else { return }
        preview.image = image
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
private class PreviewView: View {
    var image: SharedBitmap?
    override init(viewport: Viewport) {
        super.init(viewport: viewport)
        var lastId:Double = 0
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
