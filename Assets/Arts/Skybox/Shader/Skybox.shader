Shader "Custom/Skybox"
{
    Properties
    {
        [NoScaleOffset] _SunZenithGrad ("Sun-Zenith gradient", 2D) = "white" {}
        [NoScaleOffset] _ViewZenithGrad ("View-Zenith gradient", 2D) = "white" {}
        [NoScaleOffset] _SunViewGrad ("Sun-View gradient", 2D) = "white" {}
        [NoScaleOffset] _MoonCubeMap ("Moon Cube Map", Cube) = "black" {}
        [NoScaleOffset] _StarCubeMap ("Star Cube Map", Cube) = "black" {}
        
        _SunRadius ("Sun radius", Range(0,1)) = 0.05
        _MoonRadius ("Moon radius", Range(0,1)) = 0.05
        _MoonExposure ("Moon Exposure", Range(-16, 16)) = 0
        _StarExposure ("Star Exposure", Range(-16, 16)) = 0
        _StarPower ("Star Power", Range(1,5)) = 1
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

            float sphIntersect(float3 rayDir, float3 spherePos, float radius)
            {
                float3 oc = -spherePos;
                float b = dot(oc, rayDir);
                float c = dot(oc,oc) - radius * radius;
                float h = b*b - c;
                if (h<0.0) return -1.0;
                h = sqrt(h);
                return -b -h;
            }

            float GetSunMask(float sumViewDot, float sunRadius)
            {
                float stepRadius = 1 - sunRadius * sunRadius;
                return step(stepRadius, sumViewDot);
            }

            TEXTURE2D(_SunZenithGrad);  SAMPLER(sampler_SunZenithGrad);
            TEXTURE2D(_ViewZenithGrad);  SAMPLER(sampler_ViewZenithGrad);
            TEXTURE2D(_SunViewGrad);  SAMPLER(sampler_SunViewGrad);
            TEXTURECUBE(_MoonCubeMap); SAMPLER(sampler_MoonCubeMap);
            TEXTURECUBE(_StarCubeMap); SAMPLER(sampler_StarCubeMap);
            
            float3 _SunDir, _MoonDir;
            float4x4 _MoonSpaceMatrix;
            // shader global variable
            // global variable sunDir and MoonDir was normalized in C# script

            float _SunRadius, _MoonRadius;
            float _MoonExposure, _StarExposure;
            float _StarPower;

            float3 GetMoonTexture(float3 normal)
            {
                float3 uvw = mul(_MoonSpaceMatrix, float4(normal, 0)).xyz;
                float3x3 correctionMatrix = float3x3( 0, -0.24869, 0.968583, 0, 0.968583, 0.24869, -1, 0, 0);
                uvw = mul(correctionMatrix, uvw);
                return SAMPLE_TEXTURECUBE(_MoonCubeMap, sampler_MoonCubeMap, uvw).rgb;
            }

            float3x3 AngleAxis3x3(float angle, float3 axis)
            {
                float c, s;
                sincos(angle, s, c);

                float t = 1 - c;
                float x = axis.x;
                float y = axis.y;
                float z = axis.z;

                return float3x3(
                    t * x * x + c, t * x * y - s * z, t * x * z + s * y,
                    t * x * y + s * z, t * y * y + c, t * y * z - s * x,
                    t * x * z - s * y, t * y * z + s * x, t * z * z + c
                    );
            }

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
                
                float3 sunZenithColor = SAMPLE_TEXTURE2D(_SunZenithGrad, sampler_SunZenithGrad, float2(sunZenithDot01, 0.5)).rgb;

                float3 viewZenithColor = SAMPLE_TEXTURE2D(_ViewZenithGrad, sampler_ViewZenithGrad, float2(sunZenithDot01, 0.5)).rgb;
                float vzMask = pow(saturate(1.0 - viewZenithDot), 4);
                // horizon mask

                float3 sunViewColor = SAMPLE_TEXTURE2D(_SunViewGrad, sampler_SunViewGrad, float2(sunZenithDot01, 0.5)).rgb;
                float svMask = pow(saturate(sunViewDot), 4);
                
                float3 skyColor = sunZenithColor + vzMask * viewZenithColor + svMask * sunViewColor;

                float sunMask = GetSunMask(sunViewDot, _SunRadius);
                float3 sunColor = _MainLightColor.rgb * sunMask;

                float moonIntersect = sphIntersect(viewDir, _MoonDir, _MoonRadius);
                float moonMask = moonIntersect > -1 ? 1 : 0;
                float3 moonNormal = normalize(viewDir * moonIntersect - _MoonDir);
                float moonNdotL = saturate(dot(moonNormal, _SunDir));
                float3 moonTexture = GetMoonTexture(moonNormal);
                float3 moonColor = moonMask * moonNdotL * exp2(_MoonExposure) * moonTexture;

                // star map
                float3 starUVW = viewDir;
                float3 starColor = SAMPLE_TEXTURECUBE_BIAS(_StarCubeMap, sampler_StarCubeMap, starUVW, -1).rgb;
                starColor = pow(abs(starColor), _StarPower);

                float starStrength = (1 - sunViewDot01) * (saturate(-sunZenithDot));
                starColor = starColor * (1 - sunMask) * (1 - moonMask) * exp2(_StarExposure) * starStrength;
                
                float3 col = skyColor + sunColor + moonColor + starColor;
                
                return float4(col, 1);
            }



            ENDHLSL
        }
    }
}
