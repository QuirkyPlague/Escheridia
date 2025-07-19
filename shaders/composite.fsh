#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"

in vec2 texcoord;



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
    color.rgb = pow(color.rgb, vec3(2.2));
	
float depth = texture(depthtex0, texcoord).r;
	if(depth==1.0)
	{
	
		color += texture(colortex8, texcoord) ;
		
	}

	//buffer assignments
	vec4 SpecMap = texture(colortex5, texcoord);
	vec3 albedo = texture(colortex0, texcoord).rgb;
	vec3 encodedNormal = texture(colortex2,texcoord).rgb;
	vec4 sssMask = texture(colortex11, texcoord);
	vec4 waterMask=texture(colortex4,texcoord);
	vec4 translucentMask=texture(colortex7,texcoord);
	
	//block IDs
	int blockID=int(waterMask)+100;
	int blockID2=int(translucentMask)+102;
	int blockID3=int(sssMask)+103;

	//bools
	bool canScatter = blockID3 == SSS_ID;
	bool isTranslucent=blockID2==TRANSLUCENT_ID;
	bool isWater=blockID==WATER_ID;
	bool isMetal = SpecMap.g >= 230.0/255.0;

	//normal assignments
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	normal = mat3(gbufferModelView) * normal;
	vec3 baseNormal = texture(colortex6, texcoord).rgb;
	vec3 geoNormal = normalize((baseNormal - 0.5) * 2.0); 
	
	//space conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 worldPos = cameraPosition + feetPlayerPos;
	vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
	vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
	vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
	
	float sss;
	float roughness;
 	vec3  f0;
	#if RESOURCE_PACK_SUPPORT == 1
	if(canScatter)
	{sss = 1.0;}
	else
	{
		sss = 0.0;
		if(!isWater)
		{
		roughness = 255.0/255.0;
		f0 = vec3(0.02);
		}
	if(isMetal)
  	{f0 = albedo;}
	else if(isWater)
	{f0 = vec3(0.02);}
	else
	{f0 = vec3(SpecMap.g);}
		
	}
	#else
	sss = SpecMap.b;
	roughness = pow(1.0 - SpecMap.r, 2.0);
	#endif
if(isWater)
	{roughness = 0.05;}
	//sun and shadow
	vec3 lightVector = normalize(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	vec3 shadow = getSoftShadow(feetPlayerPos, geoNormal, sss);

	const vec3 V = normalize(-viewPos);
  	const vec3 L = normalize(lightVector);
  	const vec3 H = normalize(V + L);

	vec3 sunlight;
	const vec3 currentSunlight = getCurrentSunlight(sunlight, normal, shadow, worldLightVector, sss, feetPlayerPos, isWater);
	
	const vec3 specular = brdf(albedo, f0, L, currentSunlight, normal, H, V, roughness, SpecMap);
	
	if(!isWater) color.rgb += specular;
	

}