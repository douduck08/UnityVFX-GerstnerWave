Shader "Custom/WaveSurface (DX11)" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        [Header(Wave)]
        [Toggle(ENABLE_GERSTNER)] _Gerstner ("Gerstner Wave", Int) = 0

        [Header(Wave 1)]
        _WaveHeight1 ("Wave Height", float) = 1
        _WaveSteepness1 ("Wave Steepness", float) = 1
        _WaveParam1 ("Direction (XY), Wave Length (Y), Speed (W)", Vector) = (1, 0, 1, 1)

        [Header(Wave 2)]
        _WaveHeight2 ("Wave Height", float) = 1
        _WaveSteepness2 ("Wave Steepness", float) = 1
        _WaveParam2 ("Direction (XY), Wave Length (Y), Speed (W)", Vector) = (1, 0, 1, 1)

        [Header(Wave 3)]
        _WaveHeight3 ("Wave Height", float) = 1
        _WaveSteepness3 ("Wave Steepness", float) = 1
        _WaveParam3 ("Direction (XY), Wave Length (Y), Speed (W)", Vector) = (1, 0, 1, 1)
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma multi_compile _ ENABLE_GERSTNER

        #pragma surface surf Standard vertex:vert tessellate:tessDistance fullforwardshadows addshadow
        #pragma target 4.6

        #include "Tessellation.cginc"

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        half4 _Color;

        float _WaveHeight1, _WaveHeight2, _WaveHeight3;
        float _WaveSteepness1, _WaveSteepness2, _WaveSteepness3;
        float4 _WaveParam1, _WaveParam2, _WaveParam3;

        struct Input {
            float2 uv_MainTex;
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

        float4 tessDistance (appdata_full v0, appdata_full v1, appdata_full v2) {
            float minDist = 10.0;
            float maxDist = 25.0;
            return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, 5);
        }

        void vert (inout appdata_full v) {
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
#endif
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
