Shader "Custom/WaveSurface" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        [Header(Wave 1)]
        _WaveHeight1 ("Wave Height", float) = 0.1
        _WaveParam1 ("Direction (XY), Wave Length (Y), Speed (W)", Vector) = (1, 0, 1, 1)

        [Header(Wave 2)]
        _WaveHeight2 ("Wave Height", float) = 0.1
        _WaveParam2 ("Direction (XY), Wave Length (Y), Speed (W)", Vector) = (1, 0, 1, 1)

        [Header(Wave 3)]
        _WaveHeight3 ("Wave Height", float) = 0.1
        _WaveParam3 ("Direction (XY), Wave Length (Y), Speed (W)", Vector) = (1, 0, 1, 1)
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows addshadow
        #pragma target 3.0

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        half4 _Color;

        float _WaveHeight1, _WaveHeight2, _WaveHeight3;
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

        void vert (inout appdata_full v) {
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
