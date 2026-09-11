//
//  default.metal
//  Alib
//
//  Created by renan jegouzo on 20/03/2016.
//  Copyright © 2016 aestesis. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct Uniforms
{
    float4x4 matrix;
};
struct Uniforms3d
{
    float4x4 view;
    float4x4 world;
    float3 eye;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//constant half3 zero = half3(0,0,0);
constant half3 one = half3(1,1,1);
//constant half3 two = one * 2.0;
constant half e = 1e-10;
constant float pi = 3.14159265358979323846264;
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
half mixColorBurn(half a, half b);
half mixColorDodge(half a, half b);
half mixHardLight(half a, half b);
half mixOverlay(half a, half b);
half mixLinearBurn(half a, half b, float mix);
half mixLinearDodge(half a, half b);
half mixLinearLight(half a, half b);
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
half mixColorBurn(half a, half b) {
    return 1.0-(1.0-a)/(b+e);
}
half mixColorDodge(half a, half b) {
    return a/(1.0+e-b);
}
half mixHardLight(half a, half b) {
    if(b<0.5)
        return 2.0*a*b;
    else
        return 1.0-2.0*(1.0-a)*(1.0-b);
}
half mixOverlay(half a, half b) {
    if(a<0.5)
        return 2.0*a*b;
    else
        return 1.0-2.0*(1.0-a)*(1.0-b);
}
half mixLinearBurn(half a, half b, float mix) {
    return a+(b-1.0)*mix;
}
half mixLinearDodge(half a, half b) {
    return a+b;
}
half mixLinearLight(half a, half b) {
    if(b<0.5)
        return a+2.0*a*b;
    else
        return a+2.0*(b-a)*(1.0-a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
half3 rgb2hsv(half3 c) {
    const half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    half4 p = mix(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
    half4 q = mix(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
half3 hsv2rgb(half3 c) {
    const half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    half3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
half brightness(half3 rgb) {
    // sqrt( .299 R² + .587 G² + .114 B² )
    const half3 K = half3(0.299,0.587,0.114);
    half3 v = rgb*rgb*K;
    return v.x+v.y+v.z;
}
half3 brightness3(half3 rgb) {
    half b = brightness(rgb);
    return half3(b,b,b);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct InstanceIn {
    float4x4 matrix;
    float4 color;
};
struct ColorVerticeIn {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};
struct ColorVertice {
    float4 position [[position]];
    half4 color;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex ColorVertice colorFuncVertex(const device ColorVerticeIn *vin [[buffer(0)]],
                                    constant Uniforms &u [[buffer(1)]],
                                    uint vid [[vertex_id]]){
    ColorVertice vout;
    vout.position = u.matrix * float4(vin[vid].position, 1);
    vout.color = half4(vin[vid].color);
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct TextureVerticeIn
{
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
    float2 uv [[attribute(2)]];
};
struct TextureVertice
{
    float4 position [[position]];
    half4 color;
    float2 uv;
};
struct TextureVertice_float
{
    float4 position [[position]];
    float4 color;
    float2 uv;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct TextureMaskVerticeIn
{
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
    float2 uv [[attribute(2)]];
    float2 uvmask [[attribute(3)]];
};
struct TextureMaskVertice
{
    float4 position [[position]];
    half4 color;
    float2 uv;
    float2 uvmask;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex TextureVertice textureFuncVertex(const device TextureVerticeIn *vin [[buffer(0)]],
                                        constant Uniforms &u [[buffer(1)]],
                                        uint vid [[vertex_id]]) {
    TextureVertice vout;
    vout.position = u.matrix * float4(vin[vid].position, 1);
    vout.uv = vin[vid].uv;
    vout.color = half4(vin[vid].color);
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
vertex TextureVertice_float textureFuncVertex_float(const device TextureVerticeIn *vin [[buffer(0)]],
                                        constant Uniforms &u [[buffer(1)]],
                                        uint vid [[vertex_id]]) {
    TextureVertice_float vout;
    vout.position = u.matrix * float4(vin[vid].position, 1);
    vout.uv = vin[vid].uv;
    vout.color = vin[vid].color;
    return vout;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct zoomParameters
{
    float zoom;
    float rotation;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 zoomFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], constant zoomParameters &zoom [[buffer(0)]])
{
    const float2 center = { 0.5, 0.5 };
    float2 d = (v.uv-center);
    if(zoom.rotation == 0) {
        float2 p = d * zoom.zoom + center;
        half4 c = t.sample(s,p).rgba;
        return c * v.color;
    }
    float r = length(d) * zoom.zoom;
    float a = atan2(d.y, d.x) + zoom.rotation;
    float2 p = float2(cos(a), sin(a)) * r + center;
    half4 c = t.sample(s,p).rgba;
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 circularFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]])
{
    float2 p=float2((v.uv.x-0.5)*2,(v.uv.y-0.5)*2);
    p.x = length(p);
    p.y = 0;
    half4 c = t.sample(s,p).rgba * v.color;
    return half4(c.r,c.g,c.b,v.color.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 polarFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]])
{
    const float2 center = { 0.5, 0.5 };
    float2 d = (v.uv-center)*2;
    float2 p = {length(d), (atan2(d.y, d.x)+pi*0.5)/(pi*2.0)};
    half4 c = t.sample(s,p).rgba * v.color;
    return half4(c.r,c.g,c.b,v.color.a);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment float polarFuncFragmentHeight(TextureVertice v [[stage_in]], texture2d<float> t [[texture(0)]], sampler s [[sampler(0)]])
{
    const float2 center = { 0.5, 0.5 };
    float2 d = (v.uv-center)*2;
    float2 p = {length(d), (atan2(d.y, d.x)+pi*0.5)/(pi*2.0)};
    return t.sample(s,p).r*float(v.color.r);
}
// 4test / 4debug
fragment float polarFuncFragmentHeightAdd(TextureVertice v [[stage_in]], texture2d<float> t [[texture(0)]], sampler s [[sampler(0)]], float cb [[color(0)]])
{
    const float2 center = { 0.5, 0.5 };
    float2 d = (v.uv-center)*2;
    float2 p = {length(d), (atan2(d.y, d.x)+pi*0.5)/(pi*2.0)};
    return cb+t.sample(s,p).r*float(v.color.r);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 crossFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]])
{
    half4 c = t.sample(s,float2(v.uv.x,0)).rgba + t.sample(s,float2(v.uv.y,1)).rgba;
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 paletizeFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<half> pal [[texture(1)]], sampler s [[sampler(0)]], constant float2 &p[[buffer(0)]])
{
    constexpr sampler ss(coord::normalized,s_address::clamp_to_edge,t_address::clamp_to_edge,filter::linear);
    half4 cs = t.sample(s,v.uv).rgba;
    float2 ps = float2(brightness(cs.rgb))+p;
    half4 c = pal.sample(ss,ps).rgba;
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 rgbPaletizeFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<half> pal [[texture(1)]], sampler s [[sampler(0)]])
{
    constexpr sampler ss(coord::normalized,s_address::clamp_to_edge,t_address::clamp_to_edge,filter::linear);
    half4 cs = t.sample(s,v.uv).rgba;
    float2 pr = float2(cs.r,0);
    float2 pg = float2(cs.g,0.5);
    float2 pb = float2(cs.b,1);
    half3 cr = pal.sample(ss,pr).rgb;
    half3 cg = pal.sample(ss,pg).rgb;
    half3 cb = pal.sample(ss,pb).rgb;
    return half4(cr+cg+cb,cs.a) * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct popoopooo
{
    float2 offset;
    float2 amplitude;
    float2 decal;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 popoopoooFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], constant popoopooo &p[[buffer(0)]])
{
    //constexpr sampler ss(coord::normalized,s_address::clamp_to_edge,t_address::repeat,filter::linear);
    const float2 center = { 0.5, 0.5 };
    float2 d = (v.uv-center)*2;
    float2 uv = {length(d), ((atan2(d.y, d.x)+pi*0.5)/(pi*2.0))};
    float2 duv = { uv.x+p.decal.x * uv.y, uv.y + p.decal.y * uv.x };
    uv = duv * p.amplitude + p.offset;
    half4 c = t.sample(s,uv).rgba * v.color;
    return half4(c.r,c.g,c.b,v.color.a);
}
fragment half4 popoopoooScreenFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], constant popoopooo &p[[buffer(0)]], half4 cb [[color(0)]])
{
    const float2 center = { 0.5, 0.5 };
    float2 d = (v.uv-center)*2;
    float2 uv = {length(d), ((atan2(d.y, d.x)+pi*0.5)/(pi*2.0))};
    float2 duv = { uv.x+p.decal.x * uv.y, uv.y + p.decal.y * uv.x };
    uv = duv * p.amplitude + p.offset;
    half4 c = t.sample(s,uv).rgba;
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = one-(one-cb.rgb)*(one-co.rgb);
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
    
}
fragment half4 popoopoooDifferenceFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], constant popoopooo &p[[buffer(0)]], half4 cb [[color(0)]])
{
    const float2 center = { 0.5, 0.5 };
    float2 d = (v.uv-center)*2;
    float2 uv = {length(d), ((atan2(d.y, d.x)+pi*0.5)/(pi*2.0))};
    float2 duv = { uv.x+p.decal.x * uv.y, uv.y + p.decal.y * uv.x };
    uv = duv * p.amplitude + p.offset;
    half4 c = t.sample(s,uv).rgba;
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    return half4(abs(cb.rgb-co.rgb*opa),max(c.a,cb.a));
}
fragment half4 popoopoooGlowFuncFragment(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], constant popoopooo &p[[buffer(0)]], half4 cb [[color(0)]])
{
    const float2 center = { 0.5, 0.5 };
    float2 d = (v.uv-center)*2;
    float2 uv = {length(d), ((atan2(d.y, d.x)+pi*0.5)/(pi*2.0))};
    float2 duv = { uv.x+p.decal.x * uv.y, uv.y + p.decal.y * uv.x };
    uv = duv * p.amplitude + p.offset;
    half4 c = t.sample(s,uv).rgba;
    half3 co = c.rgb * v.color.rgb;
    half opa = c.a * v.color.a;
    half3 blend = co.rgb*co.rgb/(half3(1.01,1.01,1.01)-cb.rgb);
    return half4(mix(cb.rgb,blend,opa),max(c.a,cb.a));
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct FxColorRGBParams {
    float2 r_offset;
    float2 g_offset;
    float2 b_offset;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fxColorRGB(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], sampler s [[sampler(0)]], constant FxColorRGBParams &p[[buffer(0)]]) {
    half4 r = t.sample(s,v.uv+p.r_offset).rgba;
    half4 g = t.sample(s,v.uv+p.g_offset).rgba;
    half4 b = t.sample(s,v.uv+p.b_offset).rgba;
    return half4(r.r,g.g,b.b,1)*half4(r.a,g.a,b.a,max(max(r.a,g.a),b.a))*v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fxColorHSV(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<half> adjust [[texture(1)]], sampler s [[sampler(0)]]) {
    constexpr sampler ss = sampler(filter::linear, address::clamp_to_edge);
    half4 cc = t.sample(s,v.uv).rgba;
    half4 ca = t.sample(s,v.uv + float2(0.005,0.005)).rgba;
    ca += t.sample(s,v.uv + float2(-0.005,0.005)).rgba;
    ca += t.sample(s,v.uv + float2(0.005,-0.005)).rgba;
    ca += t.sample(s,v.uv + float2(-0.005,-0.005)).rgba;
    ca /= 4;
    half3 hca = rgb2hsv(ca.rgb);
    half3 hco = rgb2hsv(cc.rgb);
    hco.z = adjust.sample(ss,float2(hca.x,0)).x * hco.z;
    half3 cr = hsv2rgb(hco);
    return half4(cr,cc.a)*v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct FxDynamicPolarParams {
    float ratio;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fxDynamicPolar(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<float> adjust [[texture(1)]], sampler s [[sampler(0)]], constant FxDynamicPolarParams &params[[buffer(0)]]) {
    constexpr sampler ss = sampler(filter::linear, address::clamp_to_edge);
    const float2 center = { 0.5, 0.5 };
    float2 ratio = float2(params.ratio,1);
    float2 d = (v.uv-center) * ratio;
    float r = length(d);
    float a = atan2(d.y, d.x);
    r = adjust.sample(ss,float2(r*0.5,0)).r;
    float2 p = float2(cos(a), sin(a)) / ratio * r + center;
    half4 c = t.sample(s,p).rgba;
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fxDynamicVhsDesync(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<float> adjust [[texture(1)]], sampler s [[sampler(0)]]) {
    constexpr sampler ss = sampler(filter::linear, address::clamp_to_edge);
    float2 d = float2(adjust.sample(ss,float2(v.uv.y,0)).r,0);
    half4 c = t.sample(s,v.uv+d).rgba;
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment half4 fxDynamicFloat2(TextureVertice v [[stage_in]], texture2d<half> t [[texture(0)]], texture2d<float> adjust [[texture(1)]], sampler s [[sampler(0)]]) {
    constexpr sampler ss = sampler(filter::linear, address::clamp_to_edge);
    float2 d = float2(adjust.sample(ss,v.uv).xy);
    half4 c = t.sample(s,v.uv+d).rgba;
    return c * v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct FxDynamicPolar2Params {
    float2 amplitude;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment float4 fxDynamicPolarFloat2(TextureVertice_float v [[stage_in]], texture2d<float> t [[texture(0)]], constant FxDynamicPolar2Params &params[[buffer(0)]]) {
    constexpr sampler ss = sampler(filter::linear, address::clamp_to_edge);
    const float2 center = { 0.5, 0.5 };
    float2 p = (v.uv-center)*2;
    float l = length(p);
    if (l>1) {
        return float4(0,0,0,0);
    }
    float2 da = params.amplitude;
    float  a = atan2(p.y, p.x);
    float2 d = t.sample(ss,float2(l*0.5,0)).rg;
    float2 la = float2(l,a) + d * da;
    float2 pd = float2(cos(la.y), sin(la.y)) * la.x;
    return float4(pd-p,0,1)*v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
fragment float4 fxDynamicCartesianFloat2(TextureVertice_float v [[stage_in]], texture2d<float> t [[texture(0)]]) {
    constexpr sampler ss = sampler(filter::linear, address::clamp_to_edge);
    float2 p = v.uv;
    float2 d = float2(t.sample(ss,float2(p.x,0)).r,t.sample(ss,float2(p.y,0)).r);
    return float4(d,0,1)*v.color;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
struct FluidDiffuseParams {
    float a;
    float c;
};
//////////////////////////////////////////////////////////////////////////////////////////////////////////
kernel void kernelFluidDiffuse(
    texture2d<float, access::write> output [[texture(0)]],
    texture2d<float, access::read> input [[texture(1)]],
    uint2 gpos [[thread_position_in_grid]],
    constant FluidDiffuseParams &p[[buffer(0)]])
{
    uint w = input.get_width();
    uint h = input.get_height();
    if (gpos.x >= w-1 || gpos.y >= h-1 || gpos.x == 0 || gpos.y == 0) {
        return;
    }
    float4 current = input.read(gpos);
    float4 left = input.read(gpos-uint2(-1,0));
    float4 right = input.read(gpos-uint2(1,0));
    float4 top = input.read(gpos-uint2(0,-1));
    float4 bottom = input.read(gpos-uint2(0,1));
    current.xy = (current.xy + p.a * (top.xy + left.xy + right.xy + bottom.xy)) / p.c;
    output.write(current, gpos);
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

