#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/lighting/lighting.glsl"
#include "/lib/shadows/distort.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/softShadows.glsl"
#include "/lib/water/waterFog.glsl"
#include "/lib/brdf.glsl"
#include "/lib/blockID.glsl"

in vec2 texcoord;
vec4 SpecMap = texture(colortex5, texcoord);
vec4 waterMask=texture(colortex4,texcoord);
vec4 translucentMask=texture(colortex7,texcoord);
int blockID=int(waterMask)+100;
int blockID2=int(translucentMask)+102;
bool isWater=blockID==WATER_ID;
bool isTranslucent=blockID2==TRANSLUCENT_ID;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	
	if(isWater || isTranslucent)
	{
	
		vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
		vec3 encodedNormal = texture(colortex2, texcoord).rgb;
		vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
		float depth = texture(depthtex0, texcoord).r;
		
		vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
		vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
		vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
		vec3 worldPos = cameraPosition + feetPlayerPos;
		vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
		vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
		vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
		vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

		vec3 shadow = getSoftShadow(shadowClipPos, feetPlayerPos, normal, texcoord, shadowScreenPos);



		vec3 lightVector = normalize(shadowLightPosition);
		vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

		float roughness;
 		roughness = pow(1.0 - SpecMap.r, 2.0);
		if(isWater)
		{
			roughness = 0.05;
		}
	

			
		vec3 V = normalize(cameraPosition - worldPos);
  		vec3 L = normalize(worldLightVector);
  		vec3 H = normalize(V + L);

		vec3 F0;
  		if(SpecMap.g <= 229.0/255.0)
  		{
    		F0 = vec3(SpecMap.g);
  		}
  		else
  		{
    		F0 = color.rgb;
  		}

		vec3 diffuse = doDiffuse(texcoord, lightmap, normal, worldLightVector, shadow);
		vec3 sunlight;
		vec3 currentSunlight = getCurrentSunlight(sunlight, normal, shadow, worldLightVector);
		vec3 specular = brdf(color.rgb, F0, L, currentSunlight, normal, H, V, roughness, SpecMap) * 15;
		vec3 lighting =  color.rgb + specular;
		#if LIGHTING_GLSL == 1
		color.rgb = lighting;
		#endif
	}
	
	
	
	
	
}