import AVKit
import aestesis_alib

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
extension Bundle {
    public static var aestesis: Bundle = .module
}
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

    var textures: FlutterTextureRegistry?
    var _dummy: DummyOsView?
    var _composition: CompositionUI?

    override init() {
        super.init()
        _dummy = DummyOsView()
        _composition = CompositionUI(parent: _dummy!.viewport!)
        #if DEBUG
            Task.init {
                if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
                    await AVCaptureDevice.requestAccess(for: .video)
                }
                if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
                    await AVCaptureDevice.requestAccess(for: .audio)
                }
            }
        #endif
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

    func updateControl(control: Control) throws {
        _composition!.sync {
            _composition?.update(control: control)
        }
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
            let index = self._composition!.composition.modules.firstIndex(where: {
                $0?.id == moduleId
            })!
            _composition!.composition.modules[index]!.assets!.removeAll(where: {
                assetIds.contains(element: $0?.id)
            })
            _composition!.update(module: _composition!.composition.modules[index]!)
        }
        return _composition!.composition
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
        _composition?.preview(show: show)
    }

    func startRecording(path: String) {
        let compo = _composition!
        compo.async {
            compo.startRecording(path: path)
        }
    }

    func stopRecording() {
        let compo = _composition!
        compo.async {
            compo.stopRecording()
        }
    }

    func cameraDevices() async throws -> [CameraDevice] {
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
        let cameraPosition: ((AVCaptureDevice) -> CameraPosition) = { device in
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
        let seekCameras: (() -> [CameraDevice]) = {
            let session = AVCaptureDevice.DiscoverySession(
                deviceTypes: [
                    .builtInWideAngleCamera, .continuityCamera, .deskViewCamera, .external,
                ],
                mediaType: .video, position: .unspecified)
            let cameras = session.devices.map {
                CameraDevice(
                    id: $0.uniqueID, name: $0.localizedName, model: $0.modelID,
                    manufacturer: $0.manufacturer,
                    position: cameraPosition($0), type: cameraType($0.deviceType))
            }
            return cameras
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return seekCameras()
        default:
            let ok = try await AVCaptureDevice.requestAccess(for: .video)
            if !ok {
                return []
            }
            return seekCameras()
        }

    }

    func audioDevices() async throws -> [AudioDevice] {
        return aestesis_alib.AudioDevice.devices.map { d in
            return AudioDevice(
                id: Int64(d.id), name: d.name, manufacturer: d.manufacturer,
                inputChannels: d.inputChannels, outputChannels: d.outputChannels)
        }
    }

    func pickFiles(title: String, directory: String?, multiple: Bool, extensions: [String])
        async throws -> [String]
    {
        #if os(iOS)
            let controller = UIDocumentPickerViewController()
            // TODO: ..
            return []
        #else
            return await MainActor.run {
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
                    return results.map { $0.path }
                } else {
                    return []
                }
            }
        #endif
    }

    func setAssetData(key: String, json: String) throws {
        let j = JSON(parseJSON: json)
        let compo = _composition!
        compo.async {
            compo.setAssetData(key: key, json: j)
        }
    }
    func getAssetData(key: String) throws -> String? {
        let compo = _composition!
        var json: JSON?
        compo.sync {
            json = compo.getAssetData(key: key)
        }
        return json?.rawString()
    }
    func setAssetDatas(json: String) throws {
        let j = JSON(parseJSON: json)
        let compo = _composition!
        compo.async {
            compo.setAssetDatas(json: j)
        }
    }
    func getAssetDatas() throws -> String? {
        let compo = _composition!
        var json: JSON?
        compo.sync {
            json = compo.getAssetDatas()
        }
        return json?.rawString()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
