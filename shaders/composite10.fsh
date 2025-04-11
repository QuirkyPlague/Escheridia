#version 410 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/sky.glsl"
uniform float far;
vec3 dayDistFogColor;
vec3 earlyDistFogColor;
vec3 duskDistFogColor;
vec3 nightDistFogColor;
in vec2 texcoord;

vec4 waterMask = texture(colortex8, texcoord);

int blockID = int(waterMask) + 100;
  
  bool isWater = blockID == WATER_ID;
 bool inWater = isEyeInWater == 1.0;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex1, texcoord).r;
 

if(isWater)
{
    depth = texture(depthtex0, texcoord).r;
    if(depth == 0.0){
    return;
  }
}
  
 if(depth == 1.0){
    return;
  }

  vec2 lightmap = texture(colortex1, texcoord).rg;
  #if DO_DISTANCE_FOG == 1
  float farPlane = far * 4;
  
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

  // Fog calculations
  float dist = length(viewPos) / far;
  float fogFactor = exp(-FOG_DENSITY * (0.7 - dist));
  float nightFogFactor = exp(-FOG_DENSITY * (0.97 - dist));
  float rainFogFactor = exp(-FOG_DENSITY * (0.75 - dist));

  vec3 fogColor = applySky(dayDistFogColor);
if(!inWater)
{
  
	

  vec3 currentFogColor = fogColor;

 
  
  if(rainStrength <= 1.0 && rainStrength > 0.0 && !isNight)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    fogFactor = mix(fogFactor, rainFogFactor, dryToWet);
    fogColor = mix(currentFogColor, applySky(rainFogColor), dryToWet);
    color.rgb = mix(color.rgb, fogColor, clamp(fogFactor, 0.0, 1.0));
  }
  else if(rainStrength <= 1.0 && rainStrength > 0.0 && isNight)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    fogFactor = mix(fogFactor, rainFogFactor, dryToWet);
    fogColor = mix(currentFogColor, rainFogColor, dryToWet) / 18;
    color.rgb = mix(color.rgb, fogColor, clamp(fogFactor, 0.0, 1.0));
  }
  color.rgb = mix(color.rgb, fogColor, clamp(fogFactor, 0.0, 1.0));
}
	
#endif
}