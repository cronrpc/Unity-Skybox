Shader "Custom/SkyboxCloudEasy"
{
    Properties
    {
        [NoScaleOffset] _MoonCubeMap ("Moon Cube Map", Cube) = "black" {}
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "white" {}
        [NoScaleOffset] _StarMap ("Star Map", 2D) = "white" {}
        [NoScaleOffset] _NoiseDistort ("Noise Distort", 2D) = "white" {}
        [NoScaleOffset] _CloudNoise ("Second Distort", 2D) = "white" {}
        
        _CloudColorDayEdge("Cloud Color Day Edge", Color) = (0.1,0.1,0.1,0.1)
        _CloudColorDayMain("Cloud Color Day Main", Color) = (0.1,0.1,0.1,0.1)
        
        _CloudCutOff ("Cloud Cut Off", Range(0,1)) = 0.5
        _StarCutOff ("Star Cut Off", Range(0,1)) = 0.5
        _CloudSpeed ("Cloud Speed", Range(0,1)) = 0.1
        _Fuzziness ("Fuzziness", Range(0,1)) = 0.1
        _DistortSpeed ("Distort Speed", Range(0,1)) = 0.1
        _DistortScale ("Distort Scale", Float) = 0.1
        
        _CloudNoiseScale ("Cloud Noise Scale", Float) = 0.1
        _StarSpeed ("Star Speed", Vector) = (0.1, 0.2, 0, 0)
    }
    SubShader
    {
        Tags {"Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox"}
        Cull Off
        ZWrite Off
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 posOS : POSITION;
            };

            struct v2f
            {
                float4 posCS     : SV_POSITION;
                float3 viewDirWS : TEXCOORD0;
            };

            v2f Vertex(Attributes IN)
            {
                v2f OUT = (v2f)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.posOS.xyz);

                OUT.posCS = vertexInput.positionCS; // not NDC, just clip
                OUT.viewDirWS = vertexInput.positionWS;

                return OUT;
            }
            
            TEXTURE2D(_CloudMap);  SAMPLER(sampler_CloudMap);
            TEXTURE2D(_StarMap);  SAMPLER(sampler_StarMap);
            TEXTURE2D(_NoiseDistort); SAMPLER(sampler_NoiseDistort);
            TEXTURE2D(_CloudNoise); SAMPLER(sampler_CloudNoise);
            TEXTURECUBE(_MoonCubeMap); SAMPLER(sampler_MoonCubeMap);
            
            float3 _SunDir, _MoonDir;
            // shader global variable
            // global variable sunDir and MoonDir was normalized in C# script

            float _CloudCutOff;
            float _StarCutOff;
            float _CloudSpeed;
            float _DistortSpeed, _DistortScale, _CloudNoiseScale;
            float3 _StarSpeed;
            float _Fuzziness;
            float4 _CloudColorDayEdge, _CloudColorDayMain;

            float4 Fragment (v2f IN) : SV_TARGET
            {
                float3 viewDir = normalize(IN.viewDirWS);

                // Main angles
                float sunViewDot = dot(_SunDir, viewDir);
                float sunZenithDot = _SunDir.y;
                float viewZenithDot = viewDir.y;
                float sunMoonDot = dot(_SunDir, _MoonDir);

                float sunViewDot01 = (sunViewDot + 1.0) * 0.5;
                float sunZenithDot01 = (sunZenithDot + 1.0) * 0.5;
                
                // Hook

                float2 staruv = viewDir.xz / saturate(viewDir.y);
                float3 starColor = SAMPLE_TEXTURE2D(_StarMap, sampler_StarMap, staruv + _StarSpeed.xy * _Time.x).rgb;
                starColor = step(_StarCutOff, starColor);
                
                float2 skyuv = viewDir.xz / saturate(viewDir.y);
                
                float cloudColor = SAMPLE_TEXTURE2D(_CloudMap, sampler_CloudMap, (skyuv - _CloudSpeed * _Time.x) * _DistortScale);
                float distort = SAMPLE_TEXTURE2D(_NoiseDistort, sampler_NoiseDistort, (skyuv + cloudColor - _CloudSpeed * _Time.x) * _DistortScale);
                float cloudNoise = SAMPLE_TEXTURE2D(_CloudNoise, sampler_CloudNoise, (skyuv + distort - _CloudSpeed * _Time.x) * _DistortScale);
                
                float finalNoise = saturate(distort * cloudNoise) * saturate(viewDir.y * 0.7) * lerp(distort, cloudNoise, _SinTime.x); // 让远处的渐渐消失

                float clouds = saturate(smoothstep(_CloudCutOff, _CloudCutOff + _Fuzziness, finalNoise));

                float4 cloudsColored = lerp(_CloudColorDayEdge,  _CloudColorDayMain , clouds) * clouds;

                float cloudsNegative = 1 - clouds;
                
                starColor *= cloudsNegative;
                float3 baseSky = float3(0.2, 0.5, 0.6);
                baseSky *= cloudsNegative;
                
                float4 col = cloudsColored + float4(starColor + baseSky, 0);
                
                return col;
            }



            ENDHLSL
        }
    }
}
