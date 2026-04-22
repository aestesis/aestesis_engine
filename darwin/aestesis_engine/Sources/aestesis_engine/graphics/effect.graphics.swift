//
//  effect.graphics.swift
//  FlutterAlib
//
//  Created by renan jegouzo on 09/02/2024.
//

import Foundation

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
class EffectGraphics: Graphics {
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func drawCircleFromRayon(
        rect: Rect, source: Bitmap, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.circular", blend: blend)
        uniforms(matrix)
        let vert = textureVertices(4)
        let strip = rect.strip
        let uv = Rect(x: 0, y: 0, w: 1, h: 1).strip
        for i in 0...3 {
            vert[i] = TextureVertice(
                position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler("sampler.clamp")
        render.use(texture: source)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func drawPolar(
        rect: Rect, source: Bitmap, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        if source.format == .height {
            program("program.polar.height", blend: blend)
        } else {
            program("program.polar", blend: blend)
        }
        uniforms(matrix)
        let vert = textureVertices(4)
        let strip = rect.strip
        let uv = Rect(x: 0, y: 0, w: 1, h: 1).strip
        for i in 0...3 {
            vert[i] = TextureVertice(
                position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler("sampler.clamp.wrap")
        render.use(texture: source)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func drawCross(
        rect: Rect, source: Bitmap, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.cross", blend: blend)
        uniforms(matrix)
        let vert = textureVertices(4)
        let strip = rect.strip
        let uv = Rect(x: 0, y: 0, w: 1, h: 1).strip
        for i in 0...3 {
            vert[i] = TextureVertice(
                position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler("sampler.clamp")
        render.use(texture: source)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func paletizeParam(_ p: SIMD2<Float>) {
        let b = buffer(MemoryLayout<SIMD2<Float>>.stride)
        let ptr = b.ptr.assumingMemoryBound(to: SIMD2<Float>.self)  //UnsafeMutablePointer<float2>(b.ptr)
        ptr[0] = p
        render.use(fragmentBuffer: b, atIndex: 0)
    }
    func paletize(
        rect: Rect, source: Bitmap, from: Rect? = nil, palette: Bitmap, offset: Point = Point.zero,
        blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.paletize", blend: blend)
        uniforms(matrix)
        paletizeParam(SIMD2<Float>(Float(offset.x), Float(offset.y)))
        let vert = textureVertices(4)
        let strip = rect.strip
        var rs = Rect(x: 0, y: 0, w: 1, h: 1)
        var wrap = false
        if let r = from {
            rs = r / source.size
            wrap = rs.w > 1 || rs.h > 1  // TODO: better test
        }
        let uv = rs.strip
        for i in 0...3 {
            vert[i] = TextureVertice(
                position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler(wrap ? "sampler.wrap" : "sampler.clamp")
        render.use(texture: source)
        render.use(texture: palette, atIndex: 1)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func popoopooParam(_ p: Popoopooo) {
        let b = buffer(MemoryLayout<Popoopooo>.stride)
        let ptr = b.ptr.assumingMemoryBound(to: Popoopooo.self)  //UnsafeMutablePointer<Popoopooo>(b.ptr)
        ptr[0] = p
        render.use(fragmentBuffer: b, atIndex: 0)
    }
    struct Popoopooo {
        var offset: SIMD2<Float>
        var amplitude: SIMD2<Float>
        var decal: SIMD2<Float>
        init(offset: Point, amplitude: Point, decal: Point) {
            self.offset = offset.infloat2
            self.amplitude = amplitude.infloat2
            self.decal = decal.infloat2
        }
    }
    func drawPopoo(
        rect: Rect, source: Bitmap, offset: Point = Point.zero, amplitude: Point = Point.unity,
        decal: Point = Point.zero, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.popoopooo", blend: blend)
        uniforms(matrix)
        popoopooParam(Popoopooo(offset: offset, amplitude: amplitude, decal: decal))
        let vert = textureVertices(4)
        let strip = rect.strip
        let uv = Rect(x: 0, y: 0, w: 1, h: 1).strip
        for i in 0...3 {
            vert[i] = TextureVertice(
                position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler("sampler.mirror")
        render.use(texture: source)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func zoomParameters(_ p: ZoomParameters) {
        let b = buffer(MemoryLayout<ZoomParameters>.stride)
        let ptr = b.ptr.assumingMemoryBound(to: ZoomParameters.self)  //UnsafeMutablePointer<Popoopooo>(b.ptr)
        ptr[0] = p
        render.use(fragmentBuffer: b, atIndex: 0)
    }
    struct ZoomParameters {
        var zoom : Float
        var rotation: Float
        init(zoom: Double, rotation:Double) {
            self.zoom = Float(zoom)
            self.rotation = Float(rotation)
        }
    }
    func draw(rect: Rect, image: Bitmap, zoom:Double, rotation: Double = 0, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.zoom", blend: blend)
        uniforms(matrix)
        zoomParameters(ZoomParameters(zoom:zoom,rotation:rotation))
        let vert = textureVertices(4)
        let strip = rect.strip
        let uv = Rect(x: 0, y: 0, w: 1, h: 1).strip
        for i in 0...3 {
            vert[i] = TextureVertice(
                position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler("sampler.mirror")
        render.use(texture: image)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func fxColorRGBParameters(_ p: FxColorRGBParameters) {
        let b = buffer(MemoryLayout<FxColorRGBParameters>.stride)
        let ptr = b.ptr.assumingMemoryBound(to: FxColorRGBParameters.self)
        ptr[0] = p
        render.use(fragmentBuffer: b, atIndex: 0)
    }
    struct FxColorRGBParameters {
        var red_offset: SIMD2<Float>
        var green_offset: SIMD2<Float>
        var blue_offset: SIMD2<Float>
    }
    func draw(rect: Rect, image: Bitmap, from: Rect? = nil, redOffset: Point, greenOffset: Point, blueOffset:Point , blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.fx.color.rgb", blend: blend)
        uniforms(matrix)
        let params = FxColorRGBParameters(red_offset: (redOffset/image.size).infloat2, green_offset: (greenOffset/image.size).infloat2, blue_offset: (blueOffset/image.size).infloat2)
        fxColorRGBParameters(params)
        let vert = textureVertices(4)
        let strip = rect.strip
        var rs = Rect(x: 0, y: 0, w: 1, h: 1)
        if let r = from {
            rs = r / image.size
        }
        let uv = rs.strip
        for i in 0...3 {
            vert[i] = TextureVertice(position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler("sampler.mirror")
        render.use(texture: image)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func draw(rect: Rect, image: Bitmap, from: Rect? = nil, hsvDecal:Bitmap, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.fx.color.hsv", blend: blend)
        uniforms(matrix)
        let vert = textureVertices(4)
        let strip = rect.strip
        var rs = Rect(x: 0, y: 0, w: 1, h: 1)
        var wrap = false
        if let r = from {
            rs = r / image.size
            wrap = rs.w > 1 || rs.h > 1  // TODO: better test
        }
        let uv = rs.strip
        for i in 0...3 {
            vert[i] = TextureVertice(position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler(wrap ? "sampler.wrap" : "sampler.clamp")
        render.use(texture: image)
        render.use(texture: hsvDecal, atIndex:1)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func fxDynamicPolarParameters(_ p: FxDynamicPolarParameters) {
        let b = buffer(MemoryLayout<FxDynamicPolarParameters>.stride)
        let ptr = b.ptr.assumingMemoryBound(to: FxDynamicPolarParameters.self)
        ptr[0] = p
        render.use(fragmentBuffer: b, atIndex: 0)
    }
    struct FxDynamicPolarParameters {
        var ratio: Float
    }
    func draw(rect: Rect, image: Bitmap, from: Rect? = nil, polar:Bitmap, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.fx.dynamic.polar", blend: blend)
        uniforms(matrix)
        fxDynamicPolarParameters(FxDynamicPolarParameters(ratio: Float(image.bounds.ratio)))
        let vert = textureVertices(4)
        let strip = rect.strip
        var rs = Rect(x: 0, y: 0, w: 1, h: 1)
        if let r = from {
            rs = r / image.size
        }
        let uv = rs.strip
        for i in 0...3 {
            vert[i] = TextureVertice(position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler("sampler.mirror")
        render.use(texture: image)
        render.use(texture: polar, atIndex:1)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func draw(rect: Rect, image: Bitmap, from: Rect? = nil, vhs:Bitmap, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.fx.dynamic.vhs.desync", blend: blend)
        uniforms(matrix)
        let vert = textureVertices(4)
        let strip = rect.strip
        var rs = Rect(x: 0, y: 0, w: 1, h: 1)
        if let r = from {
            rs = r / image.size
        }
        let uv = rs.strip
        for i in 0...3 {
            vert[i] = TextureVertice(position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler("sampler.mirror")
        render.use(texture: image)
        render.use(texture: vhs, atIndex:1)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func draw(rect: Rect, image: Bitmap, from: Rect? = nil, field:Bitmap, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.fx.dynamic.float2", blend: blend)
        uniforms(matrix)
        let vert = textureVertices(4)
        let strip = rect.strip
        var rs = Rect(x: 0, y: 0, w: 1, h: 1)
        if let r = from {
            rs = r / image.size
        }
        let uv = rs.strip
        for i in 0...3 {
            vert[i] = TextureVertice(position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        sampler("sampler.mirror")
        render.use(texture: image)
        render.use(texture: field, atIndex:1)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func fxDynamicPolar2Parameters(_ p: FxDynamicPolar2Parameters) {
        let b = buffer(MemoryLayout<FxDynamicPolar2Parameters>.stride)
        let ptr = b.ptr.assumingMemoryBound(to: FxDynamicPolar2Parameters.self)
        ptr[0] = p
        render.use(fragmentBuffer: b, atIndex: 0)
    }
    struct FxDynamicPolar2Parameters {
        var amplitude: SIMD2<Float>
    }
    func draw(rect: Rect, polar:Bitmap, from: Rect? = nil, amplitude: Point = .unity, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.fx.dynamic.polar.float2", blend: blend)
        uniforms(matrix)
        fxDynamicPolar2Parameters(FxDynamicPolar2Parameters(amplitude: amplitude.infloat2))
        let vert = textureVertices(4)
        let strip = rect.strip
        let rs = from ?? Rect(x: 0, y: 0, w: 1, h: 1)
        let uv = rs.strip
        for i in 0...3 {
            vert[i] = TextureVertice(position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        render.use(texture: polar)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    func draw(rect: Rect, cartesian:Bitmap, from: Rect? = nil, blend: BlendMode = BlendMode.opaque, color: Color = Color.white
    ) {
        program("program.fx.dynamic.cartesian.float2", blend: blend)
        uniforms(matrix)
        let vert = textureVertices(4)
        let strip = rect.strip
        let rs = from ?? Rect(x: 0, y: 0, w: 1, h: 1)
        let uv = rs.strip
        for i in 0...3 {
            vert[i] = TextureVertice(position: strip[i].infloat3, uv: uv[i].infloat2, color: color.infloat4)
        }
        render.use(texture: cartesian)
        render.draw(trianglestrip: 4)
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    static func initShareds(store: NodeUI) {
        let library = ProgramLibrary(parent: store, filename: "default")
        store["metalsharedlibrary"] = library
        Program.populateDefaultBlendModes(
            store: store, key: "program.fx.dynamic.cartesian.float2", library: library, vertex: "textureFuncVertex_float",
            fragment: "fxDynamicCartesianFloat2", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.fx.dynamic.polar.float2", library: library, vertex: "textureFuncVertex_float",
            fragment: "fxDynamicPolarFloat2", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.fx.dynamic.float2", library: library, vertex: "textureFuncVertex",
            fragment: "fxDynamicFloat2", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.fx.dynamic.vhs.desync", library: library, vertex: "textureFuncVertex",
            fragment: "fxDynamicVhsDesync", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.fx.dynamic.polar", library: library, vertex: "textureFuncVertex",
            fragment: "fxDynamicPolar", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.fx.color.hsv", library: library, vertex: "textureFuncVertex",
            fragment: "fxColorHSV", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.fx.color.rgb", library: library, vertex: "textureFuncVertex",
            fragment: "fxColorRGB", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.zoom", library: library, vertex: "textureFuncVertex",
            fragment: "zoomFuncFragment", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.circular", library: library, vertex: "textureFuncVertex",
            fragment: "circularFuncFragment", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.polar", library: library, vertex: "textureFuncVertex",
            fragment: "polarFuncFragment", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.polar.height", library: library, vertex: "textureFuncVertex",
            fragment: "polarFuncFragmentHeight", vertexFormat: [.float3, .float4, .float2],
            pixelFormat: .height)   // TODO: warning, blend.add doesn't work, opaque works, maybe other blend doesn't work
        store["program.polar.height.add"] = Program(
            library: library, vertex: "textureFuncVertex", fragment: "polarFuncFragmentHeightAdd",
            blend: BlendMode.opaque, vertexFormat: [.float3, .float4, .float2], pixelFormat: .height)
        Program.populateDefaultBlendModes(
            store: store, key: "program.cross", library: library, vertex: "textureFuncVertex",
            fragment: "crossFuncFragment", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.paletize", library: library, vertex: "textureFuncVertex",
            fragment: "paletizeFuncFragment", vertexFormat: [.float3, .float4, .float2])
        Program.populateDefaultBlendModes(
            store: store, key: "program.popoopooo", library: library, vertex: "textureFuncVertex",
            fragment: "popoopoooFuncFragment", vertexFormat: [.float3, .float4, .float2])
        store["program.popoopooo.screen"] = Program(
            library: library, vertex: "textureFuncVertex", fragment: "popoopoooScreenFuncFragment",
            blend: BlendMode.opaque, vertexFormat: [.float3, .float4, .float2])
        store["program.popoopooo.difference"] = Program(
            library: library, vertex: "textureFuncVertex", fragment: "popoopoooDifferenceFuncFragment",
            blend: BlendMode.opaque, vertexFormat: [.float3, .float4, .float2])
        store["program.popoopooo.glow"] = Program(
            library: library, vertex: "textureFuncVertex", fragment: "popoopoooDifferenceFuncFragment",
            blend: BlendMode.opaque, vertexFormat: [.float3, .float4, .float2])
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////////
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
