Shader "Custom/RGBShaderCustom"
{
    Properties
    {
        _Speed ("Speed", Float) = 1.0
        _Alpha ("Alpha", Range(0,1)) = 1.0
        _EmissionIntensity ("Emission Intensity", Float) = 2.0

        [KeywordEnum(Back, Front, Off)] _CullingMode ("Culling Mode", Float) = 0
        [KeywordEnum(Opaque, Cutout, Transparent, Additive)] _BlendMode ("Blend Mode", Float) = 2
        _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5

        _Saturation ("Saturation", Range(0,2)) = 1.0
        _Brightness ("Brightness", Range(0,2)) = 1.0
        _Contrast ("Contrast", Range(0,2)) = 1.0

        [KeywordEnum(Random, Custom)] _ColorMode ("Color Mode", Float) = 0
        _TransitionSpeed ("Transition Speed", Range(0,5)) = 1.0

        _Color1 ("Color  1", Color) = (1,0,0,1)
        _Color2 ("Color  2", Color) = (0,1,0,1)
        _Color3 ("Color  3", Color) = (0,0,1,1)
        _Color4 ("Color  4", Color) = (1,0,1,1)
        _Color5 ("Color  5", Color) = (1,1,0,1)

        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100

        Cull [_CullingMode]
        ZWrite [_BlendMode]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _CULLINGMODE_BACK _CULLINGMODE_FRONT _CULLINGMODE_OFF
            #pragma multi_compile _BLENDMODE_OPAQUE _BLENDMODE_CUTOUT _BLENDMODE_TRANSPARENT _BLENDMODE_ADDITIVE
            #pragma multi_compile _COLORMODE_RANDOM _COLORMODE_CUSTOM

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float _Speed;
            float _Alpha;
            float _EmissionIntensity;
            float _Cutoff;

            float _Saturation;
            float _Brightness;
            float _Contrast;
            float _TransitionSpeed;

            fixed4 _Color1;
            fixed4 _Color2;
            fixed4 _Color3;
            fixed4 _Color4;
            fixed4 _Color5;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y * _Speed;
                fixed4 finalColor;

                #ifdef _COLORMODE_RANDOM
                    float r = sin(time) * 0.5 + 0.5;
                    float g = sin(time + 2) * 0.5 + 0.5;
                    float b = sin(time + 4) * 0.5 + 0.5;
                    finalColor = fixed4(r, g, b, _Alpha);
                #endif

                #ifdef _COLORMODE_CUSTOM
                    float colorIndex = frac(time * _TransitionSpeed);
                    if (colorIndex < 0.2) finalColor = _Color1;
                    else if (colorIndex < 0.4) finalColor = _Color2;
                    else if (colorIndex < 0.6) finalColor = _Color3;
                    else if (colorIndex < 0.8) finalColor = _Color4;
                    else finalColor = _Color5;
                    
                    finalColor.a = _Alpha;
                #endif

                // Ajuste de saturación
                float luminance = dot(finalColor.rgb, float3(0.3, 0.59, 0.11));
                finalColor.rgb = lerp(float3(luminance, luminance, luminance), finalColor.rgb, _Saturation);

                // Ajuste de brillo y contraste
                finalColor.rgb = (finalColor.rgb - 0.5) * _Contrast + 0.5;
                finalColor.rgb *= _Brightness;

                // Multiplicar con la textura
                fixed4 texColor = tex2D(_MainTex, i.uv);
                finalColor *= texColor;

                // Modo Cutout
                #ifdef _BLENDMODE_CUTOUT
                if (finalColor.a < _Cutoff) discard;
                #endif

                return finalColor * _EmissionIntensity;
            }
            ENDCG
        }
    }
}
