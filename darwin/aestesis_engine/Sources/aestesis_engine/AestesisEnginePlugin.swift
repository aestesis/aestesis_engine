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
            Task {
                if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
                    await AVCaptureDevice.requestAccess(for: .video)
                }
                if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
                    await AVCaptureDevice.requestAccess(for: .audio)
                }
            }
        #endif
    }

    func newComposition() async throws -> Composition {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                self._composition!.composition.modules.removeAll()
                self._composition!.update()
                continuation.resume(returning: self._composition!.composition)
            }
        }
    }

    func composition() async throws -> Composition {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                continuation.resume(returning: self._composition!.composition)
            }
        }
    }

    func updateComposition(composition compo: Composition) async throws -> Composition {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                //Thread.sleep(0.01)  // security: wait current frame background renderers
                self._composition!.composition = compo
                self._composition!.update()
                continuation.resume(returning: self._composition!.composition)
            }
        }
    }

    func updateModule(module: Module) async throws -> Composition {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                self._composition!.update(module: module)
                continuation.resume(returning: self._composition!.composition)
            }
        }
    }

    func updateControl(control: Control) throws {
        guard let composition = _composition else {
            return
        }
        RunLoop.composition.perform {
            composition.update(control: control)
        }
    }

    func addModule(module: Module) async throws -> Composition {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                self._composition!.composition.modules.append(module)
                self._composition!.update()
                continuation.resume(returning: self._composition!.composition)
            }
        }
    }

    func insertModule(module: Module, index: Int64) async throws -> Composition {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                self._composition!.composition.modules.insert(module, at: Int(index))
                self._composition!.update()
                continuation.resume(returning: self._composition!.composition)
            }
        }
    }

    func removeModule(moduleId: String) async throws -> Composition {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                self._composition!.composition.modules.remove(
                    at: self._composition!.composition.modules.firstIndex(where: {
                        $0?.id == moduleId
                    })!
                )
                self._composition!.update()
                continuation.resume(returning: self._composition!.composition)
            }
        }
    }

    func addAssets(moduleId: String, assets: [Asset?]) async throws -> Composition {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                self._composition!.composition[moduleId]?.assets?.append(contentsOf: assets)
                self._composition!.update(module: self._composition!.composition[moduleId]!)
                continuation.resume(returning: self._composition!.composition)
            }
        }
    }

    func removeAssets(moduleId: String, assetIds: [String?]) async throws -> Composition {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                self._composition!.composition[moduleId]?.assets?.removeAll(where: {
                    assetIds.contains(element: $0?.id)
                })
                self._composition!.update(module: self._composition!.composition[moduleId]!)
                continuation.resume(returning: self._composition!.composition)
            }
        }
    }

    func settings(settings: CompositionSettings?) async throws -> CompositionSettings {
        return await withCheckedContinuation { continuation in
            RunLoop.composition.perform {
                if let settings = settings {
                    self._composition!.update(settings: settings)
                }
                continuation.resume(returning: self._composition!.settings)
            }
        }
    }

    func outputView(show: Bool) throws {
        guard let composition = _composition else { return }
        RunLoop.composition.perform {
            composition.preview(show: show)
        }
    }

    func startRecording(path: String) {
        guard let composition = _composition else { return }
        RunLoop.composition.perform {
            composition.async {
                composition.startRecording(path: path)
            }
        }
    }

    func stopRecording() {
        guard let composition = _composition else {
            return
        }
        RunLoop.composition.perform {
            composition.async {
                composition.stopRecording()
            }
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

    func openPanel(title: String, directory: String?, multiple: Bool, ext: [String])
        async throws -> [String]
    {
        #if os(iOS)
            //let controller = UIDocumentPickerViewController()
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
                dialog.allowedContentTypes = ext.map {
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
    func savePanel(title: String, directory: String?, filename: String, ext: String)
        async throws -> String?
    {
        #if os(iOS)
            //let controller = UIDocumentPickerViewController()
            // TODO: ..
            return nil
        #else
            return await MainActor.run {
                let dialog = NSSavePanel()
                let type = UTType(tag: ext, tagClass: .filenameExtension, conformingTo: nil)!
                dialog.title = title
                if let directory = directory {
                    dialog.directoryURL = Foundation.URL(string: directory)
                }
                dialog.nameFieldStringValue = filename
                dialog.currentContentType = type
                dialog.canCreateDirectories = true
                dialog.showsResizeIndicator = true
                dialog.showsHiddenFiles = false
                dialog.allowedContentTypes = [type]
                if dialog.runModal() == NSApplication.ModalResponse.OK {
                    return dialog.url?.path
                } else {
                    return nil
                }
            }
        #endif
    }

    func setAssetData(key: String, json: String) throws {
        // TODO: does nothing, try to understand for what purpose I made it
        let j = JSON(parseJSON: json)
        guard let composition = _composition else {
            return
        }
        RunLoop.composition.perform {
            composition.async {
                composition.setAssetData(key: key, json: j)
            }
        }
    }
    func getAssetData(key: String) throws -> String? {
        guard let composition = _composition else { return nil }
        var json: JSON?
        composition.sync {
            json = composition.getAssetData(key: key)
        }
        return json?.rawString()
    }
    func setAssetDatas(json: String) throws {
        let j = JSON(parseJSON: json)
        guard let composition = _composition else {
            return
        }
        RunLoop.composition.perform {
            composition.async {
                composition.setAssetDatas(json: j)
            }
        }
    }
    func getAssetDatas() throws -> String? {
        guard let composition = _composition else { return nil }
        var json: JSON?
        composition.sync {
            json = composition.getAssetDatas()
        }
        return json?.rawString()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
