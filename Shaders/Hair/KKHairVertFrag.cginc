﻿#ifndef KK_HAIRVF_INC
#define KK_HAIRVF_INC

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
	o.uv1 = v.uv1;
				
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
			

fixed4 frag (Varyings i) : SV_Target
{
	float3 viewDir = normalize(_WorldSpaceCameraPos - i.posWS);
	float3 worldLight = normalize(_WorldSpaceLightPos0.xyz); //Directional light

	float4 mainTex = tex2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw);
	float alpha = AlphaClip(i.uv0, mainTex.a);

	float3 diffuse = GetDiffuse(i.uv0) * mainTex.rgb;

	float3 ambientShadowExtendAdjust;
	AmbientShadowAdjust(ambientShadowExtendAdjust);

	float2 normalUV = i.uv0 * _NormalMap_ST.xy + _NormalMap_ST.zw;
	float4 normal = tex2D(_NormalMap, normalUV);
	//Adjust to WS
	float2 adjustNormal = normal.wy * 2 - 1;
	float3 adjustedNormal = adjustNormal.y * i.bitanWS;
	adjustedNormal = adjustNormal.x * i.tanWS + adjustedNormal;
	float adjustMagn = dot(adjustNormal, adjustNormal);
	adjustMagn = sqrt(1 - min(adjustMagn, 1.0));
	adjustedNormal = adjustMagn * i.normalWS + adjustedNormal;
	adjustedNormal = normalize(adjustedNormal);

	float fresnel = max(0.0, dot(viewDir, adjustedNormal));
	float anotherRamp = tex2D(_AnotherRamp, fresnel * _AnotherRamp_ST.xy + _AnotherRamp_ST.zw).x;
	fresnel = 1 - fresnel;
	fresnel = log2(fresnel);
	float rimPow = _rimpower * 9.0 + 1.0;
	fresnel *= rimPow;
	fresnel = exp2(fresnel);
	fresnel = saturate(fresnel * 5.0 - 1.5);
				
	ambientShadowExtendAdjust = min(ambientShadowExtendAdjust * fresnel, 0.5);
				
	float lambert = dot(worldLight, adjustedNormal);
	float ramp = tex2D(_RampG, lambert * _RampG_ST.xy + _RampG_ST.zw).x;

	float bitanFres = dot(viewDir, i.bitanWS);
	float specularHeight = _SpeclarHeight - 1.0;
	float3 hairGlossVal;

	//Slightly different values for hair front
#ifdef HAIR_FRONT 
	hairGlossVal.x = lambert * 0.0199999809 + i.uv1.x;
	hairGlossVal.x += 0.99000001;
#else
	hairGlossVal.x = lambert * 0.00499999989 + i.uv1.x;
#endif
	hairGlossVal.z = specularHeight * bitanFres + i.uv1.y;
	hairGlossVal.y = hairGlossVal.z + 0.00800000038;

	float4 hairGlossUV = hairGlossVal.xyxz * _HairGloss_ST.xyxy + _HairGloss_ST.zwzw;
	float4 hairGloss1 = tex2D(_HairGloss, hairGlossUV.xy);
	float4 hairGloss2 = tex2D(_HairGloss, hairGlossUV.zw);
	float hairGloss = (hairGloss1 - hairGloss2) * 0.5f;

	float4 ambientShadow = 1 - _ambientshadowG.wxyz;
	float3 ambientShadowIntensity = -ambientShadow.x * ambientShadow.yzw + 1;
	float ambientShadowAdjust = _ambientshadowG.w * 0.5 + 0.5;
	float ambientShadowAdjustDoubled = ambientShadowAdjust + ambientShadowAdjust;
	bool ambientShadowAdjustShow = 0.5 < ambientShadowAdjust;
	ambientShadow.rgb = ambientShadowAdjustDoubled * _ambientshadowG.rgb;
	float3 finalAmbientShadow = ambientShadowAdjustShow ? ambientShadowIntensity : ambientShadow.rgb;
	finalAmbientShadow = saturate(finalAmbientShadow);
	float3 invertFinalAmbientShadow = 1 - finalAmbientShadow;

	finalAmbientShadow = finalAmbientShadow * _ShadowColor.xyz;
	finalAmbientShadow += finalAmbientShadow;
	float3 shadowCol = _ShadowColor - 0.5;
	shadowCol = -shadowCol * 2 + 1;

	invertFinalAmbientShadow = -shadowCol * invertFinalAmbientShadow + 1;
	bool3 shadeCheck = 0.5 < _ShadowColor.xyz;
	{
	    float3 hlslcc_movcTemp = finalAmbientShadow;
	    hlslcc_movcTemp.x = (shadeCheck.x) ? invertFinalAmbientShadow.x : finalAmbientShadow.x;
	    hlslcc_movcTemp.y = (shadeCheck.y) ? invertFinalAmbientShadow.y : finalAmbientShadow.y;
	    hlslcc_movcTemp.z = (shadeCheck.z) ? invertFinalAmbientShadow.z : finalAmbientShadow.z;
	    finalAmbientShadow = hlslcc_movcTemp;
	}
	finalAmbientShadow = saturate(finalAmbientShadow);
	float minusAmbientShadow = finalAmbientShadow - 1;
	minusAmbientShadow = hairGloss * minusAmbientShadow + 1;
	shadowCol = diffuse * minusAmbientShadow;
	shadowCol *= finalAmbientShadow;
	diffuse = diffuse * minusAmbientShadow - shadowCol;

	float shadowAttenuation = saturate(min(ramp, anotherRamp));
	float rampAdjust = ramp * 0.5 + 0.5;
	#ifdef SHADOWS_SCREEN
		float2 shadowMapUV = i.shadowCoordinate.xy / i.shadowCoordinate.ww;
		float4 shadowMap = tex2D(_ShadowMapTexture, shadowMapUV);
		shadowAttenuation *= shadowMap;
	#endif
	float4 detailMask = tex2D(_DetailMask, i.uv0 * _DetailMask_ST.xy + _DetailMask_ST.zw);
	float2 invertDetailGB = 1 - detailMask.gb;
	float shadowMasked = shadowAttenuation * invertDetailGB.x;
	shadowAttenuation = max(shadowAttenuation, invertDetailGB.x);

	diffuse = shadowMasked * diffuse + shadowCol;
	diffuse = hairGloss2.x * rampAdjust + diffuse;

	float rimVal = invertDetailGB.x * _rimV;
	rimVal *= invertDetailGB.y;

	float3 finalDiffuse  = saturate(rimVal * ambientShadowExtendAdjust + diffuse);

	float shadowExtend = 1 - _ShadowExtend;
	shadowAttenuation = max(shadowAttenuation, shadowExtend);
	float3 shading = 1 - finalAmbientShadow;
	shading = shadowAttenuation * shading + finalAmbientShadow;
	finalDiffuse *= shading;
	shading = _LightColor0.xyz * float3(0.600000024, 0.600000024, 0.600000024) + float3(0.400000006, 0.400000006, 0.400000006);
	shading = max(shading, _ambientshadowG.rgb);
	finalDiffuse *= shading;


	return float4(finalDiffuse, alpha);
}

#endif