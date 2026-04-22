//
//  Shader.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 16/10/2023.
//

import Foundation
import SpriteKit

// https://www.shadertoy.com/howto


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class ShaderUI: ModuleUI {
    var renderer:SKRenderer?
    var shader:SKShader?
    override init(parent: NodeUI, id: String) {
        super.init(parent: parent, id: id)
        if let composition = composition {
            output.value = FlutterBitmap(parent:self,assetId:id,size:composition.settings.size)
            renderer = SKRenderer(device: viewport!.gpu.device!)
            renderer?.scene = SKScene(size:composition.settings.size.system)
            let sprite = SKSpriteNode(color:.white,size:composition.settings.size.system)
            sprite.position = (composition.settings.size*0.5).point.system
            renderer?.scene?.addChild(sprite)
            
            // http://battleofbrothers.com/sirryan/understanding-shaders-in-spritekit/
            
            let src = """


vec4 mainImage(vec2 fragCoord) {
    float ts = sin(iTime*0.1156154)*5.0+12.0;
    vec2 uv = fragCoord/iResolution.xy;
    vec4 z0 = 0.5 + 0.5*cos(iTime+uv.xyxy+vec4(0,5,17,23));
    vec4 z1 = 0.5 + 0.5*cos(iTime+uv.xyxy+vec4(1,3,7,11));
    float v0 = sin(distance(z0.xy,uv)*ts)+sin(distance(z0.zw,uv)*ts)*0.5+0.5;
    float v1 = sin(distance(z1.xy,uv)*ts)+sin(distance(z1.zw,uv)*ts)+1.0;
    return vec4(v0,v1,0.5,1);
}

void main() {
    gl_FragColor = mainImage(v_tex_coord);
}
"""
            let uniforms:[SKUniform] = [
                SKUniform(name: "iResolution", vectorFloat3: SIMD3<Float>(1920,1080,0)),
                SKUniform(name: "iTime", float: 0)
            ]
            shader = SKShader(source: src, uniforms: uniforms)
            sprite.shader = shader
        }
    }
    override func detach() {
        super.detach()
    }
    override func update(settings: CompositionSettings) {
        if output.value!.size != settings.size {
            output.value = FlutterBitmap(parent: self, assetId: id,  size: settings.size)
            renderer?.scene?.size = settings.size.system
            guard let sprite:SKSpriteNode = renderer?.scene?.children.first as? SKSpriteNode else { return }
            sprite.size = settings.size.system
            sprite.position = (settings.size*0.5).point.system
        }
    }
    override func process(time: Double, dtime: Double, beat: Double, dbeat: Double, fps:Double, audio: AudioAnalyzer.Info) {
        guard let output = output.value else { return }
        guard let renderer=renderer  else { return }
        guard let sprite:SKSpriteNode = renderer.scene?.children.first as? SKSpriteNode else { return }
        guard let cb = viewport?.gpu.queue.makeCommandBuffer() else { return }
        guard let shader = shader else { return }
        renderer.update(atTime: TimeInterval(time))
        if let iTime = shader.uniformNamed("iTime") {
            iTime.floatValue = Float(time)
        }
        renderer.render(withViewport: output.bounds.system, commandBuffer: cb, renderPassDescriptor: simpleDescriptor(texture: output))
        cb.addCompletedHandler({ [weak self] (cb: MTLCommandBuffer) in
            switch cb.status {
            case .completed:
                guard let self=self, self.attached else { return }
                output.updated()
            case .error:
                Debug.error(cb.error!.localizedDescription.lowercased())
            default:
                // Debug.info("\(cb.status)")
                break;
            }
        })
        // cb.present(..)
        cb.commit()
    }
    
    func simpleDescriptor(texture: Texture2D, clear: Color? = nil) -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = texture.texture
        if let c = clear {
            descriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(c.r, c.g, c.b, c.a)
        } else {
            descriptor.colorAttachments[0].loadAction = MTLLoadAction.load
        }
        descriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        return descriptor
    }
    
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
