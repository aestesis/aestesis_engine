//
//  platform.view.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 30/10/2023.
//

import AppKit
import FlutterMacOS
import aestesis_alib

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class AlibViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        return AlibView(
            frame: CGRect(x: 0, y: 0, width: 160, height: 90),  // view gets a layout event with real frame size
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class AlibView: NSView {
    var view: OsView?
    var composition: CompositionUI? {
        return AestesisEnginePlugin.instance._composition
    }
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        super.init(frame: frame)
        let channel = FlutterMethodChannel(
            name: "aestesis/alibview_macos_\(viewId)", binaryMessenger: messenger!)
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handle(call, result: result)
        })
        view = OsView(
            frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height),
            device: AestesisEnginePlugin.instance._composition?.viewport?.gpu.device, threads: false)
        super.addSubview(view!)
        view!.onStartUI.once { viewport in
            viewport.rootView = VideoView(viewport: viewport)
            if let arguments = args as? [String: Any] {
                self.handleArguments(arguments)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateView":
            let args = call.arguments as! [String: Any]
            handleArguments(args)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func handleArguments(_ args: [String: Any]) {
        let rargs = args as! [String: String?]
        if let videoView = self.view?.viewport?.rootView as? VideoView {
            videoView.update(arguments: rargs)
        }
    }
    public override func layout() {
        view?.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        super.layout()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class VideoView: View {
    var moduleId: String?
    var assetId: String?
    var bitmap: SharedBitmap?
    var pause: Bool = false
    var generandom: Double = 0
    var gain:Double = 1
    var key: String {
        return "\(moduleId!).\(assetId!)"
    }
    var composition: CompositionUI? {
        return AestesisEnginePlugin.instance._composition
    }
    init(viewport: Viewport, moduleId: String? = nil, assetId: String? = nil) {
        self.moduleId = moduleId
        self.assetId = assetId
        super.init(viewport: viewport)
        self.bitmap = SharedBitmap(parent: viewport, size: Size(192, 108))
        viewport.pulse.alive(self) {
            if let moduleId = self.moduleId, let module = self.composition?.modules[moduleId] {
                if let assetId = self.assetId {
                    if moduleId == assetId, let b = module.output.value {
                        self.bitmap = b
                    } else if let b = module.assetOutputs[assetId] {
                        self.bitmap = b
                    }
                } else if let b = module.output.value {
                    self.bitmap = b
                }
                if let bitmap = self.bitmap, bitmap.generandom != self.generandom {
                    self.needsRedraw = true
                    self.generandom = bitmap.generandom
                }
            }
        }
    }
    
    override func draw(to g: Graphics) {
        if let bitmap = bitmap {
            g.draw(rect: bounds, image: bitmap, from: bitmap.bounds.crop(bounds.ratio), color: Color(rgb:color.rgb*gain))
            if let viewport = viewport, !viewport.systemView.pauseRefresh && pause {
                viewport.systemView.pauseRefresh = true
            }
        }
    }
    func update(arguments: [String: String?]) {
        if let moduleId = arguments["moduleId"] {
            self.moduleId = moduleId
        }
        if let assetId = arguments["assetId"] {
            self.assetId = assetId
        }
        if let pause = arguments["pause"] {
            self.pause = pause?.contains("pause") ?? false
        }
        if let color = arguments["color"], color != nil {
            self.color = Color(html: color!)
        }
        if let gain = arguments["gain"], gain != nil, let v = Double(gain!) {
            self.gain = v
        }
        if let viewport = viewport, viewport.systemView.pauseRefresh && !pause {
            viewport.systemView.pauseRefresh = false
        }
        //Debug.info("VideoView.update(moduleId:\(moduleId ?? "nil") assetId:\(assetId ?? "nil") pause:\(viewport!.systemView.pauseRefresh)")
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
