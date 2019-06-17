Shader "Custom/WaveSurface" {
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
        #pragma surface surf Scattering vertex:vert fullforwardshadows addshadow
        #pragma target 3.0

        #pragma multi_compile _ ENABLE_GERSTNER
        #include "WaveSurface.cginc"
        
        ENDCG
    }
    FallBack "Diffuse"
}
