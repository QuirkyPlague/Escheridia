#version 420 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/blur.glsl" 
#include "/lib/lighting/lighting.glsl"
#include "/lib/water/waterFog.glsl"
in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() 
{
	
	color = texture(colortex0, texcoord);
	float depth = texture(depthtex1, texcoord).r;
	float depth1 = texture(depthtex1, texcoord).r;
	vec2 lightmap = texture(colortex1, texcoord).rg; // we only need the r and g components
	if(inWater)
	{
	 depth = texture(depthtex1, texcoord).r;
	}
	const vec3 encodedNormal = texture(colortex2,texcoord).rgb;
	vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // we normalize to make sure it is of unit length
	normal=mat3(gbufferModelView)*normal;
	//space conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
	vec3 lightVector = normalize(shadowLightPosition);
	const vec3 sunlightColor = vec3(0.0);
	const vec3 sunColor = currentSunColor(sunlightColor);
	if(depth==1.0)
	{
		vec3 sun = skyboxSun(lightVector, normalize(viewPos), sunColor);
	float smoothColor = (color.rgb, sun, 0.5);
	//color.rgb = mix(color.rgb, sun, smoothColor);
		color += texture(colortex8, texcoord);
	}

	
}
