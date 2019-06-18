#include "UnityPBSLighting.cginc"
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct appdata members height)
#pragma exclude_renderers d3d11
#include "Tessellation.cginc"

sampler2D _MainTex;
sampler2D _BumpMap;
half _Glossiness;
half _Metallic;
half4 _Color;

half4 _ScatterColor;
float _ScatterFalloff;
float _TessellationMinDist;
float _TessellationMaxDist;
float _Tessellation;

float _WaveHeight1, _WaveHeight2, _WaveHeight3;
float _WaveSteepness1, _WaveSteepness2, _WaveSteepness3;
float4 _WaveParam1, _WaveParam2, _WaveParam3;

// structure define
struct appdata {
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
    float4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Input {
    float2 uv_MainTex;
    float2 uv_BumpMap;
    float4 color : COLOR; // use this to pass custome data in tessellate shader
};

struct SurfaceOutputScattering {
    // Standard
    fixed3 Albedo;      // base (diffuse or specular) color
    float3 Normal;      // tangent space normal, if written
    half3 Emission;
    half Metallic;      // 0=non-metal, 1=metal
    half Smoothness;    // 0=rough, 1=smooth
    half Occlusion;     // occlusion (default 1)
    fixed Alpha;        // alpha for transparencies
    // Custom
    half Thickness;
};

float SineWave (float2 pos, float amplitude, float4 param, out float3 normal, out float3 tangent) {
    float2 direction = param.xy;
    float frequency = 1.0 / param.z;
    float phase = param.w * frequency;

    float f = dot(pos, direction) * frequency - phase * _Time.y;
    float h = amplitude * sin(f);
    float2 derivative = direction * (frequency * amplitude * cos(f));

    normal = float3(derivative.x, derivative.y, -1);
    tangent = float3(0, -1, -derivative.y);
    return h;
}

// methods
float3 GerstnerWave (float2 pos, float amplitude, float steepness, float4 param, out float3 normal, out float3 tangent) {
    float2 direction = param.xy;
    float frequency = 1.0 / param.z;
    float phase = param.w * frequency;
    steepness = clamp(0, param.z / amplitude, steepness);

    float f = dot(pos, direction) * frequency - phase * _Time.y;
    float sin_f = sin(f);
    float cos_f = cos(f);
    float qa = steepness * amplitude;
    float wa = frequency * amplitude;
    float qwa = steepness * wa;

    float3 displacement;
    displacement.x = direction.x * qa * cos_f;
    displacement.y = direction.y * qa * cos_f;
    displacement.z = amplitude * sin_f;

    normal.xy = direction * (wa * cos_f);
    normal.z = qwa * sin_f - 1;
    tangent.x = qwa * direction.x * direction.y * sin_f;
    tangent.y = qwa * direction.y * direction.y * sin_f - 1;
    tangent.z = -wa * direction.y * cos_f;
    return displacement;
}

void vert (inout appdata v) {
#ifdef ENABLE_GERSTNER
    // gerstner wave
    float3 displacement = 0, normal = 0, tangent = 0;
    float3 tmp_normal, tmp_tangent;

    // Wave 1
    displacement += GerstnerWave(v.vertex.xy, _WaveHeight1, _WaveSteepness1, _WaveParam1, tmp_normal, tmp_tangent);
    normal += tmp_normal;
    tangent += tmp_tangent;

    // Wave 2
    displacement += GerstnerWave(v.vertex.xy, _WaveHeight2, _WaveSteepness2, _WaveParam2, tmp_normal, tmp_tangent);
    normal += tmp_normal;
    tangent += tmp_tangent;

    // Wave 3
    displacement += GerstnerWave(v.vertex.xy, _WaveHeight3, _WaveSteepness3, _WaveParam3, tmp_normal, tmp_tangent);
    normal += tmp_normal;
    tangent += tmp_tangent;

    // Normalize
    float3 bitangent = cross(v.normal, v.tangent.xyz) * v.tangent.w;
    v.vertex.xyz += v.tangent.xyz * displacement.x;
    v.vertex.xyz += bitangent * displacement.y;
    v.vertex.xyz += v.normal * displacement.z;

    v.normal = normalize(normal);
    v.tangent.xyz = normalize(tangent);

    v.color.r = 1 - displacement.z / (_WaveHeight1 + _WaveHeight2 + _WaveHeight3);
#else
    // sine wave
    float h = 0;
    float3 normal = 0, tangent = 0;
    float3 tmp_normal, tmp_tangent;

    // Wave 1
    h += SineWave(v.vertex.xy, _WaveHeight1, _WaveParam1, tmp_normal, tmp_tangent);
    normal += tmp_normal;
    tangent += tmp_tangent;

    // Wave 2
    h += SineWave(v.vertex.xy, _WaveHeight2, _WaveParam2, tmp_normal, tmp_tangent);
    normal += tmp_normal;
    tangent += tmp_tangent;

    // Wave 3
    h += SineWave(v.vertex.xy, _WaveHeight3, _WaveParam3, tmp_normal, tmp_tangent);
    normal += tmp_normal;
    tangent += tmp_tangent;

    // Normalize
    v.vertex.xyz += v.normal * h;
    v.normal = normalize(normal);
    v.tangent.xyz = normalize(tangent);

    v.color.r = 1 - h / (_WaveHeight1 + _WaveHeight2 + _WaveHeight3);
#endif

}

float4 tess (appdata v0, appdata v1, appdata v2) {
    return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, _TessellationMinDist, _TessellationMaxDist, _Tessellation);
}

void surf (Input IN, inout SurfaceOutputScattering o) {
    half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
    o.Albedo = c.rgb;
    o.Metallic = _Metallic;
    o.Smoothness = _Glossiness;
    o.Alpha = c.a;
    o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
    o.Thickness = IN.color.r;
}

inline half4 LightingScattering (SurfaceOutputScattering s, float3 viewDir, UnityGI gi) {
    s.Normal = normalize(s.Normal);

    half oneMinusReflectivity;
    half3 specColor;
    s.Albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

    // shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
    // this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
    half outputAlpha;
    s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

    float scatterFactor = pow(saturate(dot(-gi.light.dir, viewDir)) * s.Thickness, _ScatterFalloff);
    s.Albedo = s.Albedo + gi.light.color * _ScatterColor * scatterFactor;

    half4 c = UNITY_BRDF_PBS (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
    c.a = outputAlpha;
    return c;
}

inline void LightingScattering_GI (SurfaceOutputScattering s, UnityGIInput data, inout UnityGI gi) {
#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
    gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
#else
    Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
    gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal, g);
#endif
}