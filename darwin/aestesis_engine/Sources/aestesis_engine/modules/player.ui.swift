//
//  Player.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 16/10/2023.
//

import AVFoundation
import CoreImage
import Foundation

#if os(iOS)
import UIKit
import Flutter
#else
import AppKit
import FlutterMacOS
#endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class PlayerUI: ModuleUI {
    var assets = SynchronizedDictionnary<String, PlayerAsset>()
    let player = AVPlayer()
    var playerItemDidPlayToEndObserver: NSObjectProtocol?
    var currentAsset: PlayerAsset?
    var lastPixelBufferAsset: String?
    var lastPixelBuffer: CVPixelBuffer?
    var needPreview = SynchronizedArray<String>()
    var needsJump: Double?
    var flutterOutput : FlutterBitmap?
    override init(parent: NodeUI, id: String) {
        super.init(parent: parent, id: id)
        player.defaultRate = 1
        player.isMuted = true
        flutterOutput = FlutterBitmap(parent: self, assetId: id, size: (Size(320,180)*Device.screenScale).round)
    }
    override func detach() {
        stop()
        assets.removeAll()
        flutterOutput?.detach()
        flutterOutput = nil
        super.detach()
    }
    override func update() {
        if module!.assets?.count != assets.count {
            for a in module!.assets! where !assets.has(key: a!.id) {
                let pAsset = PlayerAsset(asset: a!)
                assets[a!.id] = pAsset
                needPreview.append(pAsset.id)
            }
            let remove = assets.values.filter { pa in
                return !module!.assets!.contains(where: { $0!.id == pa.id })
            }
            for pa in remove {
                assets[pa.id] = nil
                assetOutputs[pa.id] = nil
            }
        }
        module![PlayerControl.asset.id]!.count = Int64(assets.count)
        module![PlayerControl.asset.id]!.value = min(
            self.module![PlayerControl.asset.id]!.value,
            Double(self.module![PlayerControl.asset.id]!.count - 1))
    }
    override func update(control: Control) {
        if control.id == PlayerControl.position.id {
            needsJump = control.value
        }
    }
    override func process(time: Double, dtime: Double, beat: Double, dbeat: Double, fps:Double, audio: AudioAnalyzer.Info) {
        if let control = module![PlayerControl.asset.id], control.count > 0 && control.value >= 0 && Int(control.value) < assets.count
        {
            if let asset = module!.assets?[Int(control.value)], currentAsset?.id != asset.id {
                if let currentAsset = currentAsset, let pixelBuffer = lastPixelBuffer, currentAsset.id == lastPixelBufferAsset {
                    io {
                        currentAsset.sendPreview(moduleId: self.id, pixelBuffer: pixelBuffer, ratio: self.ratio)
                    }
                }
                play(asset: assets[asset.id]!)
                textureCache?.flush()
            }
        } else if currentAsset != nil {
            stop()
        }
        if let asset = currentAsset {
            let videoOutput = asset.videoOutput
            if let jump = needsJump {
                player.rate = 0
                player.seek(
                    to: CMTime(seconds: jump * asset.item.duration.seconds, preferredTimescale: 600))
                needsJump = nil
            } else if player.rate == 0 {
                player.rate = 1
            }
            let itime = player.currentTime()
            if videoOutput.hasNewPixelBuffer(forItemTime: itime) {
                if let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itime, itemTimeForDisplay: nil) {
                    bg { [weak self] in
                        guard let self = self, self.attached else { return }
                        let bitmap = SharedBitmap(parent:self,pixelBuffer: pixelBuffer)
                        self.output.value = bitmap
                        self.updateAssetOutput(assetId: asset.id, bitmap: bitmap)
                        self.lastPixelBuffer = pixelBuffer
                        self.lastPixelBufferAsset = asset.id
                        guard let output = flutterOutput else { return }
                        let g = Graphics(image:output)
                        g.draw(rect:output.bounds,image:bitmap,from:bitmap.bounds.crop(output.bounds.ratio))
                        g.onDone { [weak self] _ in
                            guard let self=self, self.attached else { return }
                            output.updated()
                        }
                    }
                }
                module![PlayerControl.position.id]!.value = itime.seconds / asset.item.duration.seconds
                self.module![PlayerControl.position.id]!.send()
            }
        }
        updatePreviews()
    }
    func stop() {
        if let playerItemDidPlayToEndObserver = playerItemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(playerItemDidPlayToEndObserver)
            self.playerItemDidPlayToEndObserver = nil
        }
        player.pause()
        player.replaceCurrentItem(with: nil)
        currentAsset = nil
    }
    func play(asset: PlayerAsset) {
        stop()
        player.replaceCurrentItem(with: asset.item)
        currentAsset = asset
        lastPixelBufferAsset = nil
        player.play()
        playerItemDidPlayToEndObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: asset.item, queue: .main) {
            [weak self] _ in
            self?.player.seek(to: CMTime.zero)
            self?.player.play()
        }
    }
    func updatePreviews() {
        if let id = needPreview.dequeue(), let pAsset = assets[id] {
            pAsset.processPreview(player: self)
        }
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class PlayerAsset {
    let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
        String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
        String(kCVPixelBufferMetalCompatibilityKey): true
    ])
    let asset: Asset
    let url: Foundation.URL
    let item: AVPlayerItem
    init(asset: Asset) {
        self.asset = asset
        url = Application.db.secureUrl(string: asset.uri!)!
        item = AVPlayerItem(url: url)
        item.add(videoOutput)
    }
    deinit {
        item.remove(videoOutput)
    }
    var id: String {
        return asset.id
    }
    
    func processPreview(player: PlayerUI)  {
        AVAsset(url: url).generateThumbnail { [weak self] cgImage in
            guard let self=self, let cgImage=cgImage else { return }
            player.io { [weak self] in
                guard let self=self else { return }
                self.sendPreview(moduleId: player.id, cgImage: cgImage, ratio: player.composition?.ratio ?? 16/9)
                let b = Bitmap(parent: player, cg: cgImage)
                player.updateAssetOutput(assetId: self.id, bitmap: b)
                b.detach()
            }
        }
    }
    
    func sendPreview(moduleId: String, pixelBuffer: CVPixelBuffer, ratio: Double) {
        let ciContext = CIContext()
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let fullImage = ciContext.createCGImage(ciImage, from: ciImage.extent)
        if let fullImage = fullImage {
            self.sendPreview(moduleId: moduleId, cgImage: fullImage, ratio: ratio)
        }
    }
    
    func sendPreview(moduleId: String, cgImage: CGImage, ratio: Double) {
        let height = Int(90 * Device.screenScale)
        let width = Int(Double(height) * ratio)
        var sizedImage: CGImage = cgImage
        if cgImage.height != height || cgImage.width != width {
            guard let sImage = cgImage.croppedResize(size: CGSize(width: width, height: height)) else { return }
            sizedImage = sImage
        }
        let data = sizedImage.pngData()
        let preview = Preview(moduleId: moduleId, assetId: id, width: Int64(sizedImage.width),height: Int64(sizedImage.height), data: FlutterStandardTypedData(bytes: data))
        preview.send()
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
