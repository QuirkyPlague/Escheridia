#version 410 compatibility

#include "/lib/util.glsl"

uniform sampler2D colortexN;

in vec2 texcoord;
 float exposure = GODRAYS_EXPOSURE;
 float decay = 1.0;
  float density = 1.0;
float weight = 0.3 * SUN_ILLUMINANCE;
float wetWeight = 0.65 - weight;

vec3 earlyGodrayColor = vec3(1.0, 0.2353, 0.0627);
vec3 duskGodrayColor = vec3(1.0, 0.0667, 0.0);
vec3 godrayColor = vec3(1.0, 0.6039, 0.2784);
vec3 moonrayColor = vec3(0.1608, 0.2941, 0.9608);
vec3 rainGodrayColor = vec3(0.5882, 0.5882, 0.5882);
vec3 waterTint = vec3(0.1176, 0.651, 0.9373);

 vec4 waterMask = texture(colortex8, texcoord);

  int blockID = int(waterMask) + 100;

  bool isWater = blockID == WATER_ID;
  bool inWater = isEyeInWater == 1.0;
  bool isNight = worldTime >= 13000 && worldTime < 24000;
/* RENDERTARGETS: 7 */
layout(location = 0) out vec3 color;

void main() {
	#if GODRAYS_ENABLE ==1
	color = vec3(0);

	vec2 altCoord = texcoord;
	
	float depth = texture(depthtex1, texcoord).r;
	//Space Conversions
	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
 	vec3 worldPos = feetPlayerPos + cameraPosition;
	
	vec3 LightVector = viewSpaceToScreenSpace(shadowLightPosition);
	vec3 worldLightVector = mat3(gbufferModelViewInverse) * LightVector;
	worldLightVector.xy = clamp(worldLightVector.xy, vec2(-0.5), vec2(1.5));
	
	

	vec2 deltaTexCoord = (texcoord - (LightVector.xy));

	vec3 V = normalize(cameraPosition - worldPos);
	vec3 L = normalize(worldLightVector);
 	float LdotV	= max(dot(L,V), 0.0);
	float VoL = dot(normalize(feetPlayerPos), worldLightVector);
	deltaTexCoord *= rcp(GODRAYS_SAMPLES) * density;
	float illuminationDecay = 1.0;

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
			if(isWater)
				{
					samples = texture(depthtex1, altCoord).r == 1.0 ? mix(vec3(0.0, 0.5843, 1.0), godrayColor, waterTint) : vec3(0.0);
				 	exposure = GODRAYS_EXPOSURE;
				} 
			if(inWater)
			{
					density = 0.8;
					samples = texture(depthtex1, altCoord).r == 1.0 ? mix(vec3(0.0, 0.5843, 1.0), godrayColor / 3, waterTint) : vec3(0.0);
				 	exposure = GODRAYS_EXPOSURE * 4;
			}

			if(rainStrength <= 1.0 && rainStrength > 0.0 && !isNight)
			{
				float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
				samples = texture(depthtex0, altCoord).r == 1.0 ? mix(currentGodrayColor, rainGodrayColor, dryToWet) : vec3(0.0);
				 weight = mix(weight, wetWeight, dryToWet);
			}
			else if(rainStrength <= 1.0 && rainStrength > 0.0 && isNight)
			{
				float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
				samples = texture(depthtex0, altCoord).r == 1.0 ? mix(currentGodrayColor, rainGodrayColor / 4, dryToWet) : vec3(0.0);
				 weight = mix(weight, wetWeight, dryToWet);
			}
			
			samples *= illuminationDecay * weight ;
			color += samples ;
			illuminationDecay *= decay;
			altCoord -= deltaTexCoord;
	}	

	color /= GODRAYS_SAMPLES * HG(0.45, -VoL);
	color *= exposure ;

	#endif
}