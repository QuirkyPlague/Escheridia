#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/FXAA.glsl" 
#include "/lib/atmosphere/skyColor.glsl" 
#include "/lib/lighting/lighting.glsl"
in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	float depth = texture(depthtex0, texcoord).r;

	vec3 LightVector=normalize(shadowLightPosition);
	vec3 worldLightVector=mat3(gbufferModelViewInverse)*LightVector;
	vec3 sunlightColor;
	vec3 sunColor = currentSunColor(sunlightColor);
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	
	if(depth==1.0)
	{
	
		color += texture(colortex8, texcoord) ;
		
	}
	
	color += texture(colortex10, texcoord) * vec4(0.2235, 0.2235, 0.2235, 1.0);
}