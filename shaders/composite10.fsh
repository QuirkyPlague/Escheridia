#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/spaceConversions.glsl"

vec3 dayDistFogColor;
in vec2 texcoord;

vec4 waterMask = texture(colortex8, texcoord);

int blockID = int(waterMask) + 100;
  
  bool isWater = blockID == WATER_ID;
 bool inWater = isEyeInWater == 1.0;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

 float depth = texture(depthtex0, texcoord).r;
  float depth1 = texture(depthtex1, texcoord).r;

 if(depth ==1.0)
 {
  return;
 }


  
  vec2 lightmap = texture(colortex1, texcoord).rg;
  #if DO_DISTANCE_FOG == 1
  float farPlane = far * 4;
  
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

  // Fog calculations
  float dist = length(viewPos) / far;
  float fogFactor = exp(-FOG_DENSITY * (1.1 - dist));
  float nightFogFactor = exp(-FOG_DENSITY * (0.87 - dist));
  float rainFogFactor = exp(-FOG_DENSITY * (0.55 - dist));
vec3 rainFogColor = vec3(0.4);
  vec3 distFog = applySky(dayDistFogColor, texcoord, depth) *1.5;
if(isNight)
{
  distFog = applySky(dayDistFogColor, texcoord, depth) * 0.4;
}


if(!inWater)
{
 vec3 currentFogColor = distFog;
  if(isNight)
  {
    fogFactor = nightFogFactor;
  }

  if(rainStrength <= 1.0 && rainStrength > 0.0 && !isNight)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    fogFactor = mix(fogFactor, rainFogFactor, dryToWet);
    distFog = mix(currentFogColor, applySky(rainFogColor, texcoord, depth), dryToWet);
    color.rgb = mix(color.rgb, distFog, clamp(fogFactor, 0.0, 1.0));
  }
  else if(rainStrength <= 1.0 && rainStrength > 0.0 && isNight)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    fogFactor = mix(fogFactor, rainFogFactor, dryToWet);
    distFog = mix(currentFogColor, rainFogColor, dryToWet) / 18;
    color.rgb = mix(color.rgb, distFog, clamp(fogFactor, 0.0, 1.0));
  }
  color.rgb = mix(color.rgb, distFog, clamp(fogFactor, 0.0, 1.0));
}
	
#endif
}