Shader "Custom/ProceduralCloud"
{
    Properties
    {
        [NoScaleOffset]_CloudMap ("Cloud Map", 2D) = "white" {}
        [NoScaleOffset]_NoiseMap ("Noise Map", 2D) = "white" {}
        
        [HDR]_CloudShadowColor ("Cloud Shadow Color", Color) = (1,1,1,1)
        [HDR]_CloudBrightColor ("Cloud Bright Color", Color) = (1,1,1,1)
        
        [HDR]_CloudNearSunShadowColor ("Cloud Near Sun Shadow Color", Color) = (1,1,1,1)
        [HDR]_CloudNearSunBrightColor ("Cloud Near Sun Bright Color", Color) = (1,1,1,1)
        
        [HDR]_CloudHighLightColor ("Cloud High Light Color", Color) = (1,1,1,1)
                
        _CloudCutOff ("Cloud Cut Off", Range(0.003, 1.5)) = 0.00
        
        _SunOrMoon ("Sun Or Moon", Range(0,1)) = 0
        
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Background"
            "Queue"="Transparent" "IgnoreProjector"="True"
        }
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_CloudMap);  SAMPLER(sampler_CloudMap);
            TEXTURE2D(_NoiseMap);  SAMPLER(sampler_NoiseMap);

            float _CloudCutOff;
            float _SunOrMoon;
            float4 _CloudShadowColor, _CloudBrightColor, _CloudHighLightColor;
            float4 _CloudNearSunShadowColor, _CloudNearSunBrightColor;
            CBUFFER_END
            
            // Global Variable
            float3 _SunDir, _MoonDir;
            
            struct Attributes
            {
                float4 posOS : POSITION;
                float3 normalOS : NORMAL;
                float4 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 posCS     : SV_POSITION;
                float3 normalWS  : TEXCOORD0;
                float3 viewDirWS : TEXCOORD1;
                float4 uv : TEXCOORD2;
            };

            v2f Vertex(Attributes IN)
            {
                v2f OUT = (v2f)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.posOS.xyz);

                OUT.posCS = vertexInput.positionCS; // not NDC, just clip
                OUT.viewDirWS = vertexInput.positionWS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            float4 Fragment (v2f IN) : SV_TARGET
            {
                float3 viewDir = normalize(IN.viewDirWS);
                float3 LightDirection = lerp(_SunDir, _MoonDir, _SunOrMoon);
                float SunCloudDot = saturate(dot(LightDirection, normalize( - IN.normalWS)));
                SunCloudDot = pow(SunCloudDot, 2);

                float4 uv = IN.uv;
                
                float noise = 0.03 * (SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, uv.xy).r);
                float4 sampleM = SAMPLE_TEXTURE2D(_CloudMap, sampler_CloudMap, uv.xy + noise).rgba;
                
                // clip(sampleM.b - _CloudCutOff);
                // clip(sampleM.a - 0.09);

                float4 ShadowColor = lerp(_CloudShadowColor, _CloudNearSunShadowColor, SunCloudDot);
                float4 BrightColor = lerp(_CloudBrightColor, _CloudNearSunBrightColor, SunCloudDot);
                
                float4 baseColor = lerp(ShadowColor, BrightColor, sampleM.r);
                
                float4 highLightColor = _CloudHighLightColor * sampleM.g * SunCloudDot;

                float4 col = baseColor + highLightColor;
                
                float sdf_smooth = smoothstep(clamp(_CloudCutOff - 0.08 - noise, 0, 1.5), _CloudCutOff, sampleM.b);
                
                col.a = sampleM.a * sdf_smooth;
                
                return col;
            }



            ENDHLSL
        }
    }
}
