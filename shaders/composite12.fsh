#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/spaceConversions.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/shadows.glsl"
#include "/lib/brdf.glsl"
#include "/lib/lighting.glsl"

  bool inWater = isEyeInWater == 1.0;
in vec2 texcoord;
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

	float depth = texture(depthtex0, texcoord).r;

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  	vec3 viewDir = normalize(viewPos);
	vec3 encodedViewNormal = texture(colortex2, texcoord).rgb;
  	vec3 viewNormal = normalize((encodedViewNormal - 0.5) * 2.0); 
  	viewNormal = mat3(gbufferModelView) * viewNormal;

	
	vec3 start_point;
	vec3 end_point;
	vec3 reflectionDir = normalize(end_point - start_point);
	float dist = distance(start_point, end_point);

	
	vec3 ray_step = reflectionDir * dist / SSR_STEPS;
	
	vec3 rayPos = start_point;

	for(int i = 0; i < SSR_STEPS; i++)
	{
		

	}

	

}