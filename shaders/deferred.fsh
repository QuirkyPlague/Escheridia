#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/blockID.glsl"

in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	float depth = texture(depthtex0, texcoord).r;
	if (depth == 1.0) 
	{
		return;
	}
	//buffers
	vec4 SpecMap = texture(colortex5, texcoord);
	vec4 sssMask = texture(colortex11, texcoord);
	vec4 waterMask=texture(colortex4,texcoord);
	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components	
	vec3 encodedNormal = texture(colortex2, texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	vec3 baseNormal = texture(colortex6, texcoord).rgb;
	vec3 geoNormal = normalize((baseNormal - 0.5) * 2.0); 
	vec3 albedo = texture(colortex0,texcoord).rgb;

	//id masks
	int blockID2=int(waterMask)+100;
	int blockID=int(sssMask)+103;
	bool isMetal = SpecMap.g >= 230.0/255.0;

	//bools
	bool isWater=blockID2==WATER_ID;
	bool canScatter = blockID == SSS_ID;	
	
	//space conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 worldPos = cameraPosition + feetPlayerPos;
	vec3 viewDir = normalize(viewPos);
	
	//pbr 
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
		roughness = 185.0/255.0;
		f0 = vec3(0.0);
		}
	if(isMetal)
  	{f0 = albedo;}
	else if(isWater)
	{f0 = vec3(0.02);}
	else
	{f0 = vec3(SpecMap.g);}
		
	}
	#else
	sss = mix(SpecMap.b, 0.3, wetness);
	roughness = pow(1.0 - SpecMap.r, 2.0);
	#endif

	const float emission = SpecMap.a;
	vec3 emissive;
	
	if (emission >= 0.0/255.0 && emission < 255.0/255.0)
	{
		emissive += albedo * (emission * 2 )  * EMISSIVE_MULTIPLIER;
  
	}

	
	const vec3 shadow = getSoftShadow(feetPlayerPos, geoNormal, sss);
	const vec3 lightVector = normalize(shadowLightPosition);
	const vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
	
	const vec3 V = normalize(cameraPosition - worldPos);
  	const vec3 L = normalize(worldLightVector);
  	const vec3 H = normalize(V + L);
	
	const float ao = 1.0;
	vec3 diffuse = doDiffuse(texcoord, lightmap, normal, worldLightVector, shadow, viewPos, sss, feetPlayerPos, isMetal, ao);
	vec3 sunlight;
	vec3 currentSunlight = getCurrentSunlight(sunlight, normal, shadow, worldLightVector, sss, feetPlayerPos, isWater);
	vec3 specular = brdf(albedo, f0, L, currentSunlight, normal, H, V, roughness, SpecMap, diffuse);
	vec3 lighting;
	
	#if RESOURCE_PACK_SUPPORT == 0
	if(!isMetal)
	{
		lighting = specular + emissive ;
	}
	else
	{
		lighting =  specular + emissive;
	}
	#else
	
	 lighting =  specular ;
	#endif
	
	#if LIGHTING_GLSL == 1
	color.rgb = lighting;
	#endif
	
}