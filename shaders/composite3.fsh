#version 410 compatibility

#include "/lib/util.glsl"

uniform sampler2D colortexN;

in vec2 texcoord;
 float exposure = GODRAYS_EXPOSURE;
 float decay = 1.0;
  float density = 1.0;
float weight = 0.23 * SUN_ILLUMINANCE;
float wetWeight = 0.65 - weight;

vec3 earlyGodrayColor = vec3(1.0, 0.2353, 0.0627);
vec3 duskGodrayColor = vec3(1.0, 0.0667, 0.0);
vec3 godrayColor = vec3(0.9882, 0.6824, 0.4314);
vec3 moonrayColor = vec3(0.1608, 0.2941, 0.9608);
vec3 rainGodrayColor = vec3(0.5882, 0.5882, 0.5882);
vec3 waterTint = vec3(0.0, 0.0667, 1.0);

/* RENDERTARGETS: 7 */
layout(location = 0) out vec3 color;

void main() {
	#if GODRAYS_ENABLE ==1
	color = vec3(0);

	vec2 altCoord = texcoord;
	float p = HenyeyGreenstein(weight, decay);
	
	vec3 LightVector = viewSpaceToScreenSpace(shadowLightPosition);
	LightVector.xy = clamp(LightVector.xy, vec2(-0.5), vec2(1.5));
	
	vec2 deltaTexCoord = (texcoord - (LightVector.xy));

	
	deltaTexCoord *= 1.0 / float(GODRAYS_SAMPLES) * density;
	float illuminationDecay = 2.0;

	altCoord -= deltaTexCoord * IGN(floor(gl_FragCoord.xy), frameCounter);
	
	for(int i = 0; i < GODRAYS_SAMPLES; i++)
	{
			 vec3 samples = texture(depthtex0, altCoord).r == 1.0 ? vec3(1.0) * godrayColor : vec3(0.0);
			if (worldTime >= 0 && worldTime <  1000) 
			{
				float time = smoothstep(500, 1000, float(worldTime));
				samples = texture(depthtex0, altCoord).r == 1.0 ? mix(earlyGodrayColor, godrayColor, time) : vec3(0.0);
			
			}
			else if (worldTime >= 12350 && worldTime <  23500) 
			{
				float time = smoothstep(12350, 13000, float(worldTime));
				samples = texture(depthtex0, altCoord).r == 1.0 ? vec3(1.0, 1.0, 1.0) * mix(earlyGodrayColor, moonrayColor, time) : vec3(0.0);
				weight = 0.08 * MOON_ILLUMINANCE;
				decay = 1.0;
				
			}
			else if (worldTime >= 1000 && worldTime <  12350) 
			{
				float time = smoothstep(10000, 12350, float(worldTime));
				samples = texture(depthtex0, altCoord).r == 1.0 ?  mix(godrayColor, duskGodrayColor, time) : vec3(0.0);
			}

			
			vec3 currentGodrayColor = samples;
			if(isEyeInWater == 1)
			{
				 samples = texture(depthtex1, altCoord).r == 1.0 ? mix(vec3(0.0941, 0.0392, 0.8275), godrayColor, waterTint) : vec3(0.0);
				 weight = 0.3;
				 decay = 1.0;
				 exposure = GODRAYS_EXPOSURE * 1.2;
			}
			if(rainStrength <= 1.0 && rainStrength > 0.0)
			{
				float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
				samples = texture(depthtex0, altCoord).r == 1.0 ? mix(currentGodrayColor, rainGodrayColor, dryToWet) : vec3(0.0);
				 weight = mix(weight, wetWeight, dryToWet);
				
			}
			
			samples *= illuminationDecay * weight;
			color += samples;
			illuminationDecay *= decay;
			altCoord -= deltaTexCoord;
	}	
	
	color /= GODRAYS_SAMPLES;
	color *= exposure;
	#endif
}