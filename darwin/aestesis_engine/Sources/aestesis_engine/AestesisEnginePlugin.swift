import AVKit

#if os(iOS)
import UIKit
import Flutter
#else
import Cocoa
import FlutterMacOS
#endif

// ▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄
// █▓▒▒░░░__(C) AESTESIS 2023 __░░░▒▒▓█
// ▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
// temporarix fix: https://github.com/flutter/flutter/issues/137057
extension FlutterError: Swift.Error {}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
public class AestesisEnginePlugin: NSObject, FlutterPlugin, AestesisEngineApi {
    static var instance: AestesisEnginePlugin = AestesisEnginePlugin()
    static var message: MessageAestesisEngineApi?
    public static func register(with registrar: FlutterPluginRegistrar) {
#if os(iOS)
        let messenger = registrar.messenger()
#else
        let messenger = registrar.messenger
#endif
        let viewFactory = AlibViewFactory(messenger: messenger)
        registrar.register(viewFactory, withId: "@views/alibview-view-type")
        AestesisEngineApiSetup.setUp(binaryMessenger: messenger, api: instance)
        message = MessageAestesisEngineApi(binaryMessenger: messenger)
        instance.textures = registrar.textures
    }
    
    var textures:FlutterTextureRegistry?
    var _dummy : DummyOsView?
    var _composition: CompositionUI?
    
    override init() {
        super.init()
        _dummy = DummyOsView(); 
        _composition = CompositionUI(parent: _dummy!.viewport!)
    }
    
    func newComposition() throws -> Composition {
        var composition: Composition?
        _composition?.sync {
            _composition!.composition.modules.removeAll()
            _composition!.update()
            composition = _composition?.composition
        }
        return composition!
    }
    
    func composition() throws -> Composition {
        var composition: Composition?
        _composition?.sync {
            composition = _composition?.composition
        }
        return composition!
    }
    
    func updateComposition(composition compo: Composition) throws -> Composition {
        _composition?.sync {
            Thread.sleep(0.01)  // security: wait current frame background renderers, find better..
            _composition!.composition = compo
            _composition!.update()
        }
        return _composition!.composition
    }
    
    func updateModule(module: Module) throws -> Composition {
        _composition!.sync {
            _composition!.update(module: module)
        }
        return _composition!.composition
    }
    
    func addModule(module: Module) throws -> Composition {
        _composition!.sync {
            _composition!.composition.modules.append(module)
            _composition!.update()
        }
        return _composition!.composition
    }
    
    func insertModule(module: Module, index: Int64) throws -> Composition {
        _composition!.sync {
            _composition!.composition.modules.insert(module, at: Int(index))
            _composition!.update()
        }
        return _composition!.composition
    }
    
    func removeModule(moduleId: String) throws -> Composition {
        _composition!.sync {
            _composition!.composition.modules.remove(
                at: _composition!.composition.modules.firstIndex(where: { $0?.id == moduleId })!)
            _composition!.update()
        }
        return _composition!.composition
    }
    
    func addAssets(moduleId: String, assets: [Asset?]) throws -> Composition {
        _composition!.sync {
            let index = _composition!.composition.modules.firstIndex(where: { $0?.id == moduleId })!
            _composition!.composition.modules[index]!.assets!.append(contentsOf: assets)
            _composition!.update(module: _composition!.composition.modules[index]!)
        }
        return _composition!.composition
    }
    
    func removeAssets(moduleId: String, assetIds: [String?]) throws -> Composition {
        _composition!.sync {
            let index = self._composition!.composition.modules.firstIndex(where: { $0?.id == moduleId })!
            _composition!.composition.modules[index]!.assets!.removeAll(where: {
                assetIds.contains(element: $0?.id)
            })
            _composition!.update(module: _composition!.composition.modules[index]!)
        }
        return _composition!.composition
    }
    
    func updateControl(control: Control) throws {
        _composition!.sync {
            _composition?.composition[control.moduleId]?[control.id]?.setValue(from: control)
            _composition?.update(control:control)
        }
    }
    
    func settings(settings: CompositionSettings?) throws -> CompositionSettings {
        if let settings = settings {
            _composition!.sync {
                _composition!.update(settings: settings)
            }
            _dummy!.fps = settings.fps
        }
        return _composition!.settings
    }
    
    func outputView(show: Bool) throws {
        _composition?.preview(show:show)
    }
    
    func startRecording(path: String) {
        let compo = _composition!
        compo.async {
            compo.startRecording(path:path)
        }
    }
    
    func stopRecording() {
        let compo = _composition!
        compo.async {
            compo.stopRecording()
        }
    }
    
    func cameraDevices(completion: @escaping (Result<[CameraDevice], Swift.Error>) -> Void) {
        let cameraType: ((AVCaptureDevice.DeviceType) -> CameraType) = { type in
            switch type {
            case .builtInWideAngleCamera:
                return CameraType.builtin
            case .continuityCamera:
                return CameraType.continuity
            case .deskViewCamera:
                return CameraType.deskview
            case .external:
                return CameraType.external
            default:
                return CameraType.undefined
            }
        }
        let cameraPostion: ((AVCaptureDevice) -> CameraPosition) = { device in
            switch device.position {
            case .front:
                return CameraPosition.front
            case .back:
                return CameraPosition.back
            default:
#if os(iOS)
                if device.isVirtualDevice {
                    return CameraPosition.virtual
                }
#else
                if device.localizedName.lowercased().contains("virtual") {
                    return CameraPosition.virtual
                }
#endif
                return CameraPosition.undefined
            }
        }
        let seekCameras : (() -> Void) = {
            let session = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .continuityCamera, .deskViewCamera, .external],
                mediaType: .video, position: .unspecified)
            let cameras = session.devices.map {
                CameraDevice(
                    id: $0.uniqueID, name: $0.localizedName, model: $0.modelID, manufacturer: $0.manufacturer,
                    position: cameraPostion($0), type: cameraType($0.deviceType))
            }
            completion(Result.success(cameras))
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            seekCameras()
        default:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { ok in
                if !ok {
                    completion(Result.success([]))
                }
                seekCameras()
            })
        }
    }
    
    func audioDevices(completion: @escaping (Result<[AudioDevice], Swift.Error>) -> Void) {
        completion(Result.success(AudioDevice.devices))
    }
    
    func pickFiles(
        title: String, directory: String?, multiple: Bool, extensions: [String],
        completion: @escaping (Result<[String], Swift.Error>) -> Void
    ) {
#if os(iOS)
        let controller = UIDocumentPickerViewController()
        completion(Result.success([]))
#else
        DispatchQueue.main.async {
            let dialog = NSOpenPanel()
            dialog.title = title
            if let directory = directory {
                dialog.directoryURL = Foundation.URL(string: directory)
            }
            dialog.resolvesAliases = false
            dialog.showsResizeIndicator = true
            dialog.showsHiddenFiles = false
            dialog.canChooseDirectories = false
            dialog.allowsMultipleSelection = multiple
            dialog.allowedContentTypes = extensions.map {
                UTType(tag: $0, tagClass: .filenameExtension, conformingTo: nil)!
            }
            if dialog.runModal() == NSApplication.ModalResponse.OK {
                let results = dialog.urls
                completion(Result.success(results.map { $0.path }))
            } else {
                completion(Result.success([]))
            }
        }
#endif
    }
    
    func setAssetData(key: String, json: String) throws {
        let j = JSON(parseJSON: json)
        let compo = _composition!
        compo.async {
            compo.setAssetData(key:key,json:j)
        }
    }
    func getAssetData(key: String) throws -> String? {
        let compo = _composition!
        var json:JSON?
        compo.sync {
            json = compo.getAssetData(key:key)
        }
        return json?.rawString()
    }
    func setAssetDatas(json: String) throws {
        let j = JSON(parseJSON: json)
        let compo = _composition!
        compo.async {
            compo.setAssetDatas(json:j)
        }
    }
    func getAssetDatas() throws -> String? {
        let compo = _composition!
        var json:JSON?
        compo.sync {
            json = compo.getAssetDatas()
        }
        return json?.rawString()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////


/*
 
 2026 generated
 // Import the correct Flutter module and UI framework for each platform
 #if os(iOS)
 import Flutter
 import UIKit
 #elseif os(macOS)
 import FlutterMacOS
 import Cocoa
 #endif
 
 public class AestesisEnginePlugin: NSObject, FlutterPlugin {
 public static func register(with registrar: FlutterPluginRegistrar) {
 // The registrar's `messenger` is a method on iOS and a property on macOS.
 // Use a compile-time condition to handle this difference.
 #if os(iOS)
 let messenger = registrar.messenger()
 #else
 let messenger = registrar.messenger
 #endif
 let channel = FlutterMethodChannel(name: "aestesis_engine", binaryMessenger: messenger)
 let instance = AestesisEnginePlugin()
 registrar.addMethodCallDelegate(instance, channel: channel)
 }
 
 public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
 switch call.method {
 case "getPlatformVersion":
 // Use compile-time conditions to return the correct OS version string.
 #if os(iOS)
 result("iOS " + UIDevice.current.systemVersion)
 #elseif os(macOS)
 result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
 #else
 // A fallback for any other Apple platform that might be supported in the future.
 result(FlutterMethodNotImplemented)
 #endif
 default:
 result(FlutterMethodNotImplemented)
 }
 }
 }
 */
