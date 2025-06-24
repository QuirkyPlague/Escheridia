#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"

in vec2 texcoord;



/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
    color.rgb = pow(color.rgb, vec3(2.2));
	
	vec4 waterMask=texture(colortex4,texcoord);
	vec4 translucentMask=texture(colortex7,texcoord);
	int blockID=int(waterMask)+100;
	int blockID2=int(translucentMask)+102;
	bool isWater=blockID==WATER_ID;
	bool isTranslucent=blockID2==TRANSLUCENT_ID;
	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components

	float depth = texture(depthtex0, texcoord).r;
	float depth1 = texture(depthtex1, texcoord).r;


	if(isWater && !inWater && !isTranslucent)
	{
		color.rgb = waterExtinction(color.rgb, texcoord, lightmap, depth, depth1);
		
	}        

}