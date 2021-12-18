﻿#ifndef KK_LIGHTING_INC
#define KK_LIGHTING_INC


float GetLambert(float3 lightPos, float3 normal){
    return max(dot(lightPos, normal), 0.0);
}

float GetLightRamp(float3 worldLightPos, float3 normal){
    float lambert = GetLambert(worldLightPos, normal);
	float2 rampUV = lambert * _RampG_ST.xy + _RampG_ST.zw;
	float4 ramp = tex2D(_RampG, rampUV);
    return ramp.x;
}



//Specular
float GetDrawnSpecular(Varyings i, float4 detailMask, float shadowAttenuation, float3 viewDir, out float3 drawnSpecularColor){
	float specularHeight = _SpeclarHeight  - 1.0;
	specularHeight *= 0.800000012;
	float2 detailSpecularOffset;
	detailSpecularOffset.x = dot(i.tanWS, viewDir);
	detailSpecularOffset.y = dot(i.bitanWS, viewDir);

	float2 detailMaskUV2 = specularHeight * detailSpecularOffset + i.uv0;
	detailMaskUV2 = detailMaskUV2 * _DetailMask_ST.xy + _DetailMask_ST.zw;
	float4 detailMask2 = tex2D(_DetailMask, detailMaskUV2);
	float detailSpecular = saturate(detailMask2.x * 1.66666698);
	float squaredDetailSpecular = detailSpecular * detailSpecular;
	float specularUnder = -detailSpecular * squaredDetailSpecular + detailSpecular;
	detailSpecular *= squaredDetailSpecular;

	drawnSpecularColor = detailSpecular * _SpecularColor.xyz;
	float bodySpecular = detailMask.a * _SpecularPower;
	float nailSpecular = detailMask.g * _SpecularPowerNail;
	float specularIntensity = max(bodySpecular, nailSpecular);
	float specular = specularIntensity * specularUnder;
	drawnSpecularColor *= specularIntensity;

	float dotSpecCol = dot(drawnSpecularColor.rgb, float3(0.300000012, 0.589999974, 0.109999999));
	dotSpecCol = min(dotSpecCol, specular);
	dotSpecCol = min(dotSpecCol, shadowAttenuation);
	dotSpecCol = min(dotSpecCol, detailMask.a);
	return dotSpecCol;
}

float GetMeshSpecular(float3 normal, float3 viewDir, float3 worldLightPos, out float specularPowerMesh){
	float3 halfVector = normalize(viewDir + worldLightPos);
	float specularMesh = max(dot(halfVector, normal), 0.0);
	specularMesh = log2(specularMesh);
	specularPowerMesh = _SpecularPower * 256;
	specularPowerMesh = specularPowerMesh * specularMesh;
	specularPowerMesh = saturate(exp2(specularPowerMesh) * _SpecularPower * _SpecularColor.a);
	specularMesh = exp2(specularMesh * 256) * 0.5;

	return specularMesh;
}


//Shadows
float GetShadowAttenuation(Varyings i, float3 normal, float3 worldLightPos, float3 viewDir){

	//Normal adjustment for the face I suppose it keeps the face more lit?
	float3 viewNorm = viewDir - normal;
	float2 normalMaskUV = i.uv0 * _NormalMask_ST.xy + _NormalMask_ST.zw;
	float3 normalMask = tex2D(_NormalMask, normalMaskUV).rgb;
	normalMask.xy = normalMask.yz * float2(_FaceNormalG, _FaceShadowG);
	viewNorm = normalMask.x * viewNorm + normal;
	float maskG = max(normalMask.g, 1.0);
	float lightRamp = GetLightRamp(worldLightPos, viewNorm);

    //Shadow map
	#ifdef SHADOWS_SCREEN
		float2 shadowMapUV = i.shadowCoordinate.xy / i.shadowCoordinate.ww;
		float4 shadowMap = tex2D(_ShadowMapTexture, shadowMapUV);
		float shadowAttenuation = saturate(shadowMap.x * 2.0 - 1.0);
		shadowAttenuation = max(shadowAttenuation, normalMask.y);
		shadowAttenuation *= lightRamp;
	#else
		float shadowAttenuation = maskG * lightRamp;
	#endif
    
	
    return shadowAttenuation;


}



#endif