Shader "Custom/WaveSurface (DX11)" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _BumpMap ("Bumpmap", 2D) = "bump" {}

        [Header(Water Shading)]
        _ScatterColor ("Scatter Color", Color) = (1,1,1,1)
        _ScatterFalloff ("Scatter Falloff", float) = 1

        [Header(Wave Type)]
        [Toggle(ENABLE_GERSTNER)] _Gerstner ("Gerstner Wave", Int) = 0
        _Tessellation ("Tessellation", float) = 5
        _TessellationMinDist ("Tessellation Min Dist", float) = 10
        _TessellationMaxDist ("Tessellation Max Dist", float) = 25

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
        #pragma surface surf Scattering vertex:vert tessellate:tess fullforwardshadows addshadow
        #pragma target 4.6

        #pragma multi_compile _ ENABLE_GERSTNER
        #include "WaveSurface.cginc"

        ENDCG
    }
    FallBack "Diffuse"
}
