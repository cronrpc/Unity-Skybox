Shader "Custom/SkyboxCloudEasy"
{
    Properties
    {
        [NoScaleOffset] _MoonCubeMap ("Moon Cube Map", Cube) = "black" {}
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "white" {}
        
        _CloudCutOff ("Cloud Cut Off", Range(0,1)) = 0.5
        _StarSpeed ("Star Speed", Range(0,1)) = 0.1
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
            TEXTURECUBE(_MoonCubeMap); SAMPLER(sampler_MoonCubeMap);
            
            float3 _SunDir, _MoonDir;
            // shader global variable
            // global variable sunDir and MoonDir was normalized in C# script

            float _CloudCutOff;
            float _StarSpeed;

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

                float2 skyuv = viewDir.xz / saturate(viewDir.y);
                float3 starsColor = SAMPLE_TEXTURE2D(_CloudMap, sampler_CloudMap, skyuv + float2(_StarSpeed, _StarSpeed) * _Time.y).rgb;
                float3 col = step(_CloudCutOff, starsColor);

                
                
                
                return float4(col, 1);
            }



            ENDHLSL
        }
    }
}
