#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"

in vec2 texcoord;
vec4 waterMask=texture(colortex4,texcoord);
int blockID=int(waterMask)+100;
bool isWater=blockID==WATER_ID;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	color.rgb = pow(color.rgb, vec3(2.2));
	
	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
	vec3 encodedNormal=texture(colortex2,texcoord).rgb;
  	vec3 normal=normalize((encodedNormal-.5)*2.);// we normalize to make sure it is of unit length
	normal=mat3(gbufferModelView)*normal;
	float depth = texture(depthtex0, texcoord).r;
	float depth1 = texture(depthtex1, texcoord).r;
	vec3 NDCPos=vec3(texcoord.xy,depth)*2.-1.;
 	vec3 viewPos=projectAndDivide(gbufferProjectionInverse,NDCPos);
  	vec3 viewDir=normalize(viewPos);
  	vec3 reflectedColor=calcSkyColor((reflect(viewDir,normal)));
	 vec3 V=normalize((-viewDir));
	if(isWater && !inWater)
	{
		color.rgb = waterExtinction(color.rgb, texcoord, lightmap, depth, depth1);
		vec3 F0=vec3(.02);
    	vec3 F=fresnelSchlick(max(dot(normal,V),0.),F0);
		color.rgb=mix(color.rgb, lightmap.g *0.24 * reflectedColor, F);
	}
	
	
	
	
}