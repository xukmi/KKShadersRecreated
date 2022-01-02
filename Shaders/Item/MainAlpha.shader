﻿Shader "xukmi/MainAlpha"
{
	Properties
	{
		_AnotherRamp ("Another Ramp(LineR)", 2D) = "white" {}
		_MainTex ("MainTex", 2D) = "white" {}
		_RampG ("Ramp", 2D) = "white" {} //TEMP REMOVE
		_linewidthG ("Line", Range(0, 1)) = 0 //TEMPREMOVE
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_DetailMask ("Detail Mask", 2D) = "black" {}
		_LineMask ("Line Mask", 2D) = "black" {}
		_AlphaMask ("Alpha Mask", 2D) = "white" {}
		[Gamma]_ShadowColor ("Shadow Color", Vector) = (0.628,0.628,0.628,1)
		[Gamma]_SpecularColor ("Specular Color", Vector) = (1,1,1,0)
		_SpeclarHeight ("Speclar Height", Range(0, 1)) = 0.98
		_SpecularPower ("Specular Power", Range(0, 1)) = 0
		_SpecularPowerNail ("Specular Power Nail", Range(0, 1)) = 0
		_ShadowExtend ("Shadow Extend", Range(0, 1)) = 1
		_ShadowExtendAnother ("Shadow Extend Another", Range(0, 1)) = 0
		_rimpower ("Rim Width", Range(0, 1)) = 0.5
		_rimV ("Rim Strength", Range(0, 1)) = 0.5
		[MaterialToggle] _alpha_a ("alpha_a", Float) = 1
		[MaterialToggle] _alpha_b ("alpha_b", Float) = 1
		[MaterialToggle] _DetailBLineG ("DetailB LineG", Float) = 0
		[MaterialToggle] _DetailRLineR ("DetailR LineR", Float) = 0
		[MaterialToggle] _notusetexspecular ("not use tex specular", Float) = 0
		_liquidmask ("Liquid Mask", 2D) = "black" {}
		_Texture2 ("Liquid Tex", 2D) = "black" {}
		_Texture3 ("Liquid Normal", 2D) = "bump" {}
		_LiquidTiling ("Liquid Tiling (u/v/us/vs)", Vector) = (0,0,2,2)
		_liquidftop ("liquidftop", Range(0, 2)) = 0
		_liquidfbot ("liquidfbot", Range(0, 2)) = 0
		_liquidbtop ("liquidbtop", Range(0, 2)) = 0
		_liquidbbot ("liquidbbot", Range(0, 2)) = 0
		_liquidface ("liquidface", Range(0, 2)) = 0
		[HideInInspector] _Cutoff ("Alpha cutoff", Range(0, 1)) = 0.5
	}
	SubShader
	{
		LOD 600
		Tags { "Queue" = "Transparent+40" "RenderType" = "TransparentCutout" }
		//Outline
		Pass
		{
			Name "Outline"
			LOD 600
			Tags {"Queue" = "Transparent+40" "RenderType" = "TransparentCutout" "ShadowSupport" = "true" }
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			#include "KKItemInput.cginc"
			#include "KKItemDiffuse.cginc"

			Varyings vert (VertexData v)
			{
				Varyings o;
				
				o.posWS = mul(unity_ObjectToWorld, v.vertex);
				float3 viewDir = _WorldSpaceCameraPos.xyz - o.posWS.xyz;
				float viewVal = dot(viewDir, viewDir);
				viewVal = sqrt(viewVal);
				viewVal = viewVal * 0.0999999866 + 0.300000012;
				float lineVal = _linewidthG * 0.00499999989;
				viewVal *= lineVal;
				float2 detailMaskUV = v.uv0 * _DetailMask_ST.xy + _DetailMask_ST.zw;
				float4 detailMask = tex2Dlod(_DetailMask, float4(detailMaskUV, 0, 0));
				float detailB = 1 - detailMask.b;
				viewVal *= detailB;
				float3 invertSquare;
				float3 x;
				float3 y;
				float3 z;
				x.x = unity_WorldToObject[0].x;
				x.y = unity_WorldToObject[1].x;
				x.z = unity_WorldToObject[2].x;
				float xLen = rsqrt(dot(x, x));
				y.x = unity_WorldToObject[0].y;
				y.y = unity_WorldToObject[1].y;
				y.z = unity_WorldToObject[2].y;
				float yLen = rsqrt(dot(y, y));
				z.x = unity_WorldToObject[0].z;
				z.y = unity_WorldToObject[1].z;
				z.z = unity_WorldToObject[2].z;
				float zLen = rsqrt(dot(z, z));
				float3 view = viewVal / float3(xLen, yLen,zLen);
				view = v.normal * view + v.vertex;
				o.posCS = UnityObjectToClipPos(view);
				o.uv0 = v.uv0;
				return o;
			}
			

			

			fixed4 frag (Varyings i) : SV_Target
			{
				float4 mainTex = tex2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw);
				AlphaClip(i.uv0, mainTex.a);

				float3 diffuse = mainTex.rgb;
				float3 shadingAdjustment = ShadeAdjust(diffuse);


				bool3 compTest = 0.555555582 < shadingAdjustment.xyz;
				float3 diffuseShaded = shadingAdjustment.xyz * 0.899999976 - 0.5;
				diffuseShaded = -diffuseShaded * 2 + 1;
				float4 ambientShadow = 1 - _ambientshadowG.wxyz;
				float3 ambientShadowIntensity = -ambientShadow.x * ambientShadow.yzw + 1;
				float ambientShadowAdjust = _ambientshadowG.w * 0.5 + 0.5;
				float ambientShadowAdjustDoubled = ambientShadowAdjust + ambientShadowAdjust;
				bool ambientShadowAdjustShow = 0.5 < ambientShadowAdjust;
				ambientShadow.rgb = ambientShadowAdjustDoubled * _ambientshadowG.rgb;
				float3 finalAmbientShadow = ambientShadowAdjustShow ? ambientShadowIntensity : ambientShadow.rgb;
				finalAmbientShadow = saturate(finalAmbientShadow);
				float3 invertFinalAmbientShadow = 1 - finalAmbientShadow;

				shadingAdjustment.xyz *= finalAmbientShadow;
				shadingAdjustment.xyz *= 1.79999995;
				diffuseShaded = -diffuseShaded * invertFinalAmbientShadow + 1;
				{
					float3 hlslcc_movcTemp = shadingAdjustment;
					hlslcc_movcTemp.x = (compTest.x) ? diffuseShaded.x : shadingAdjustment.x;
					hlslcc_movcTemp.y = (compTest.y) ? diffuseShaded.y : shadingAdjustment.y;
					hlslcc_movcTemp.z = (compTest.z) ? diffuseShaded.z : shadingAdjustment.z;
					shadingAdjustment = saturate(hlslcc_movcTemp);
				}
				float2 detailMaskUV = i.uv0 * _DetailMask_ST.xy + _DetailMask_ST.zw;
				float4 detailMask = tex2D(_DetailMask, detailMaskUV);
				float2 lineMaskUV = i.uv0 * _LineMask_ST.xy + _LineMask_ST.zw;
				float4 lineMask = tex2D(_LineMask, lineMaskUV);

				float detailLine = detailMask.x - lineMask.x;
				detailLine = _DetailRLineR * detailLine + lineMask;
				detailLine = 1 - detailLine;
				float shadowExtendAnother = 1 - _ShadowExtendAnother;
				detailLine = max(detailLine, shadowExtendAnother);

				float3 finalDiffuse = saturate(detailLine * shadingAdjustment) * diffuse; 
				float3 halfDiffuse = finalDiffuse * 0.5;
				finalDiffuse = -finalDiffuse * 0.5 + 1.0;

				float outlineADoubled = _LineColorG.w * 2;
				halfDiffuse *= outlineADoubled;
				float outlineAAdjust = _LineColorG.w - 0.5;
				outlineAAdjust = -outlineAAdjust * 2.0 + 1.0;
				finalDiffuse = -outlineAAdjust * finalDiffuse + 1;

				finalDiffuse = 0.5 < _LineColorG.w ? finalDiffuse : halfDiffuse;
				finalDiffuse = saturate(finalDiffuse);
				float3 outLineCol = _LightColor0.rgb * float3(0.600000024, 0.600000024, 0.600000024) + float3(0.400000006, 0.400000006, 0.400000006);

				return float4(finalDiffuse * outLineCol, 0.0);


			}

			
			ENDCG
		}

		//Main Pass
		Pass
		{
			Name "Forward"
			LOD 600
			Tags { "LightMode" = "ForwardBase" "Queue" = "Transparent+40" "RenderType" = "TransparentCutout" "ShadowSupport" = "true" }
			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
			Cull Off


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ SHADOWS_SCREEN
			
			//Unity Includes
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"


			#include "KKItemInput.cginc"
			#include "KKItemDiffuse.cginc"
			#include "KKItemNormals.cginc"
			#include "KKItemCoom.cginc"


			Varyings vert (VertexData v)
			{
				Varyings o;
				o.posWS = mul(unity_ObjectToWorld, v.vertex);
				o.posCS = mul(UNITY_MATRIX_VP, o.posWS);
				o.normalWS = UnityObjectToWorldNormal(v.normal);
				o.tanWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				float3 biTan = cross(o.tanWS, o.normalWS);
				o.bitanWS = normalize(biTan);
				o.uv0 = v.uv0;
				
			#ifdef SHADOWS_SCREEN
				float4 projPos = o.posCS;
				projPos.y *= _ProjectionParams.x;
				float4 projbiTan;
				projbiTan.xyz = biTan;
				projbiTan.xzw = projPos.xwy * 0.5;
				o.shadowCoordinate.zw = projPos.zw;
				o.shadowCoordinate.xy = projbiTan.zz + projbiTan.xw;
			#endif
				return o;
			}

			fixed4 frag (Varyings i, int faceDir : VFACE) : SV_Target
			{
				//Clips based on alpha texture
				float4 mainTex = tex2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw);


				float3 worldLightPos = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
				float3 halfDir = normalize(viewDir + worldLightPos);

				float3 diffuse = mainTex.rgb;
				float3 shadingAdjustment = ShadeAdjust(diffuse);
				float3 normal = GetNormal(i);

				float liquidFinalMask;
				float3 liquidNormal;
				GetCumVals(i.uv0, liquidFinalMask, liquidNormal);

				normal = lerp(normal, liquidNormal, liquidFinalMask);
				normal = NormalAdjust(i, normal, faceDir);

				float lambert = dot(worldLightPos, normal);

				float3 cumCol = (lambert + 0.5) * float3(0.149999976, 0.199999988, 0.300000012) + float3(0.850000024, 0.800000012, 0.699999988);

				float specular = dot(halfDir, normal);
				float fresnel = 1 - max(dot(viewDir, normal), 0.0);

				float2 rampUV = lambert * _RampG_ST.xy + _RampG_ST.zw;
				float ramp = tex2D(_RampG, rampUV);
				
				float2 anotherRampUV = abs(specular) * _AnotherRamp_ST.xy + _AnotherRamp_ST.zw;
				float anotherRamp = tex2D(_AnotherRamp, anotherRampUV);
				float finalRamp = anotherRamp - ramp;

				specular = log2(max(specular, 0.0));

				float2 detailUV = i.uv0 * _DetailMask_ST.xy + _DetailMask_ST.zw;
				float4 detailMask = tex2D(_DetailMask, detailUV);
				float2 lineMaskUV = i.uv0 * _LineMask_ST.xy + _LineMask_ST.zw;
				float4 lineMask = tex2D(_LineMask, lineMaskUV);
				lineMask.r = _DetailRLineR * (detailMask.r - lineMask.r) + lineMask.r;
				finalRamp = lineMask.r * finalRamp + ramp;
				
				#ifdef SHADOWS_SCREEN
					float2 shadowMapUV = i.shadowCoordinate.xy / i.shadowCoordinate.ww;
					float4 shadowMap = tex2D(_ShadowMapTexture, shadowMapUV);
					float shadowAttenuation = saturate(shadowMap.x * 2.0 - 1.0);
					finalRamp *= shadowAttenuation;
				#endif


				float shadowExtend = _ShadowExtend * -1.20000005 + 1.0;

				lineMask.rb = 1 - lineMask.rb;
				float4 detailMaskAdjust = 1 - detailMask.yxwz;

				float specularNail = max(detailMask.w, _SpecularPowerNail);
				float drawnShadow = min(lineMask.b, detailMaskAdjust.x);
				drawnShadow = drawnShadow * (1 - shadowExtend) + shadowExtend;
				finalRamp *= drawnShadow;

				float specularHeight = _SpeclarHeight  - 1.0;
				specularHeight *= 0.800000012;
				float2 detailSpecularOffset;
				detailSpecularOffset.x = dot(i.tanWS, viewDir);
				detailSpecularOffset.y = dot(i.bitanWS, viewDir);
				float2 detailMaskUV2 = specularHeight * detailSpecularOffset + i.uv0;
				detailMaskUV2 = detailMaskUV2 * _DetailMask_ST.xy + _DetailMask_ST.zw;
				float drawnSpecular = tex2D(_DetailMask, detailMaskUV2);
				float drawnSpecularSquared = min(drawnSpecular * drawnSpecular, 1.0);
				drawnSpecular = drawnSpecular - drawnSpecularSquared;
				drawnSpecular = saturate(drawnSpecular);
				drawnSpecular = min(drawnSpecular, _SpecularPower);
				drawnSpecular = min(drawnSpecular, finalRamp);
				float specularIntensity = dot(_SpecularColor.xyz, float3(0.300000012, 0.589999974, 0.109999999)); //???
				drawnSpecular = min(drawnSpecular, specularIntensity);

				float3 diffuseShaded = shadingAdjustment * 0.899999976 - 0.5;
				diffuseShaded = -diffuseShaded * 2 + 1;

				float4 ambientShadow = 1 - _ambientshadowG.wxyz;
				float3 ambientShadowIntensity = -ambientShadow.x * ambientShadow.yzw + 1;
				float ambientShadowAdjust = _ambientshadowG.w * 0.5 + 0.5;
				float ambientShadowAdjustDoubled = ambientShadowAdjust + ambientShadowAdjust;
				bool ambientShadowAdjustShow = 0.5 < ambientShadowAdjust;
				ambientShadow.rgb = ambientShadowAdjustDoubled * _ambientshadowG.rgb;
				float3 finalAmbientShadow = ambientShadowAdjustShow ? ambientShadowIntensity : ambientShadow.rgb;
				finalAmbientShadow = saturate(finalAmbientShadow);
				float3 invertFinalAmbientShadow = 1 - finalAmbientShadow;

				bool3 compTest = 0.555555582 < shadingAdjustment;
				shadingAdjustment *= finalAmbientShadow;
				shadingAdjustment *= 1.79999995;
				diffuseShaded = -diffuseShaded * invertFinalAmbientShadow + 1;
				{
					float3 hlslcc_movcTemp = shadingAdjustment;
					hlslcc_movcTemp.x = (compTest.x) ? diffuseShaded.x : shadingAdjustment.x;
					hlslcc_movcTemp.y = (compTest.y) ? diffuseShaded.y : shadingAdjustment.y;
					hlslcc_movcTemp.z = (compTest.z) ? diffuseShaded.z : shadingAdjustment.z;
					shadingAdjustment = saturate(hlslcc_movcTemp);
				}

				float shadowExtendAnother = 1 - _ShadowExtendAnother;
				lineMask.x = max(lineMask.x, shadowExtendAnother);
				float3 shaded = saturate(lineMask.x * shadingAdjustment);

				float3 remappedShading = lineMask.xzw * 2 - 2;
				remappedShading = drawnSpecular * remappedShading + 1;
				drawnSpecular = _SpecularPower * 256;
				drawnSpecular *= specular;
				specular *= 256;
				specular = exp2(specular);
				specular = min(specular, 1);
				drawnSpecular = exp2(drawnSpecular);
				drawnSpecular *= _SpecularPower * _SpecularColor.w;
				drawnSpecular = saturate(drawnSpecular);

				float specularPower = max(detailMaskAdjust.z, _SpecularPower);
				drawnSpecularSquared = min(drawnSpecularSquared, specularPower);
				specularNail = min(specularNail, drawnSpecularSquared);
				float finalDrawnSpecular = drawnSpecular * detailMaskAdjust.y + specularNail;
				drawnSpecularSquared = detailMaskAdjust.y * drawnSpecular;

				float3 specularDiffuse = _SpecularColor.xyz * drawnSpecularSquared + diffuse;
				float3 specularColor = finalDrawnSpecular * _SpecularColor.xyz;
				specularColor = diffuse * remappedShading + specularColor;
				diffuse *= shaded;
				float3 finalSpecularColor = specularDiffuse - specularColor;
				float3 mergedSpecularDiffuse = saturate(_notusetexspecular * finalSpecularColor + specularColor);

				float3 shadedSpecular = mergedSpecularDiffuse * shaded;
				mergedSpecularDiffuse = -mergedSpecularDiffuse * shaded + mergedSpecularDiffuse;
				mergedSpecularDiffuse = finalRamp * mergedSpecularDiffuse + shadedSpecular;
				float3 liquidDiffuse =  liquidFinalMask * float3(0.300000012, 0.402941108, 0.557352901) + float3(0.5, 0.397058904, 0.242647097);
				liquidDiffuse = liquidDiffuse * cumCol + specular;

				float fresnelAdjust = saturate(fresnel * 2 - 0.800000012);
				fresnel = log2(fresnel);
				float3 fresnelLiquid = saturate(liquidDiffuse + fresnelAdjust);
				fresnelLiquid -= mergedSpecularDiffuse;
				mergedSpecularDiffuse = liquidFinalMask * fresnelLiquid + mergedSpecularDiffuse;

				float rimPow = _rimpower * 9 + 1;
				rimPow *= fresnel;
				rimPow = exp2(rimPow);
				float rimMask = detailMaskAdjust.w * 2.77777791 + -1.77777803;
				rimPow *= rimMask;
				rimPow = min(max(rimPow, 0.0), 0.60000024);
				float3 rimCol = rimPow * _SpecularColor.xyz;
				rimCol *= _rimV;
				float3 diffuseSpecRim = saturate(rimCol * detailMaskAdjust.x + mergedSpecularDiffuse);

				float drawnLines = 1 - detailMaskAdjust.w;
				drawnLines = drawnLines - lineMask.y;
				drawnLines = _DetailBLineG * drawnLines + lineMask.y;

				float3 lightCol =  _LightColor0.xyz * float3(0.600000024, 0.600000024, 0.600000024) + float3(0.400000006, 0.400000006, 0.400000006);
				float3 ambientCol = max(lightCol, _ambientshadowG.xyz);
				diffuseSpecRim = diffuseSpecRim * ambientCol;
			
				float3 invertRemapDiffuse = -diffuse * 0.5 + 1;

				diffuse *= 0.5;
				float lineAlpha = _LineColorG.w - 0.5;
				lineAlpha = -lineAlpha * 2.0 + 1.0;
				invertRemapDiffuse = -lineAlpha * invertRemapDiffuse + 1;
				lineAlpha = _LineColorG.w *2;
				diffuse *= lineAlpha;
				diffuse = 0.5 < _LineColorG.w ? invertRemapDiffuse : diffuse;
				diffuse = saturate(diffuse);
				diffuse *= lightCol;
				
				float3 finalDiffuse = drawnShadow * (1 - shaded) + shaded;
				finalDiffuse = diffuseSpecRim * finalDiffuse - diffuse;

				float lineWidth = 1 - _linewidthG;
				lineWidth = lineWidth * 0.889999986 + 0.00999999978;
				lineWidth = log2(lineWidth);
				lineWidth *= drawnLines;
				lineWidth = exp2(lineWidth);

				finalDiffuse = lineWidth * finalDiffuse + diffuse;

				return float4(finalDiffuse, mainTex.a);
			}

			
			ENDCG
		}

		//ShadowCaster
		Pass
		{
			Name "ShadowCaster"
			LOD 600
			Tags { "LightMode" = "ShadowCaster" "Queue" = "Transparent+40" "RenderType" = "TransparentCutout" "ShadowSupport" = "true" }
			Offset 1, 1
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _AlphaMask;
			float4 _AlphaMask_ST;

			float _alpha_a;
			float _alpha_b;


            struct v2f { 
				float2 uv0 : TEXCOORD1;
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
				o.uv0 = v.texcoord;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
				float2 alphaUV = i.uv0 * _AlphaMask_ST.xy + _AlphaMask_ST.zw;
				float4 alphaMask = tex2D(_AlphaMask, alphaUV);
				float2 alphaVal = -float2(_alpha_a, _alpha_b) + float2(1.0f, 1.0f);
				float mainTexAlpha = tex2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw).a;
				alphaVal = max(alphaVal, alphaMask.xy);
				alphaVal = min(alphaVal.y, alphaVal.x);
				alphaVal *= mainTexAlpha;
				alphaVal.x -= 0.5f;
				float clipVal = alphaVal.x < 0.0f;
				if(clipVal * int(0xffffffffu) != 0)
					discard;

                SHADOW_CASTER_FRAGMENT(i)
            }

			
			ENDCG
		}

		
	}
	Fallback "Unlit/Texture"
}
