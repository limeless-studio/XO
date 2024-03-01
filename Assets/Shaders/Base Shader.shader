Shader "Snowy/BaseShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_NormalTex ("NormalMap", 2D) = "white" {}
        _NormalIntensity("Normal Intensity", Range(0, 1)) = 0
        _BaseColor ("Base Color", color) = (1, 1, 1, 1)
        _Smoothness("Smothness", Range(0, 1)) = 0
        [Gamma] _Metallic("Metallic", Range(0, 1)) = 0
    }
    
    SubShader
    {
        Tags{ "RenderType"= "Obaque" "RenderPipeline"="UniversalRenderPipeline"}
        LOD 200
        
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float4 normal: NORMAL;
                float4 tangent: TANGENT;
                float4 textcoord1: TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 tangent : TEXCOORD5;
                float3 bitangent : TEXCOORD6;
                float3 viewDir : TEXCOORD3;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 4);
            };

            sampler2D _MainTex, _NormalTex;
            float4 _MainTex_ST;

            float4 _BaseColor;
            float _Smoothness, _Metallic, _NormalIntensity;
            

            v2f vert (appdata v)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(v.vertex.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normal.xyz);
                o.viewDir = normalize(_WorldSpaceCameraPos - o.positionWS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vertex = TransformWorldToHClip(o.positionWS);

                o.tangent.xyz = TransformObjectToWorldDir(v.tangent.xyz);
                o.tangent.w = v.tangent.w;
                o.bitangent = cross(o.normalWS, o.tangent.xyz) * o.tangent.w;
                
                OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUV );
                OUTPUT_SH(o.normalWS.xyz, o.vertexSH );

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 normals = UnpackNormalScale(tex2D(_NormalTex, i.uv), _NormalIntensity);
                float3 finalNormals = normals.r * i.tangent + normals.g * i.bitangent + normals.b * i.normalWS;
                
                half4 mainTex = tex2D(_MainTex, i.uv);
                InputData inputdata = (InputData)0;
                inputdata.positionWS = i.positionWS;
                inputdata.normalWS = normalize(finalNormals);
                inputdata.viewDirectionWS = i.viewDir;
                inputdata.bakedGI = SAMPLE_GI(i.lightmapUV, i.vertexSH,inputdata.normalWS);

                SurfaceData surface_data;
                surface_data.albedo = mainTex * _BaseColor;
                surface_data.specular = 0;
                surface_data.metallic = _Metallic;
                surface_data.smoothness = _Smoothness;
                surface_data.normalTS = 0;
                surface_data.emission = 0;
                surface_data.occlusion = 1;
                surface_data.alpha = 0;
                surface_data.clearCoatMask = 0;
                surface_data.clearCoatSmoothness = 0;
                
                return UniversalFragmentPBR(inputdata, surface_data);
            }
            
            ENDHLSL
        }
    }
}
