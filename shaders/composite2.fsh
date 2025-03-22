#version 410 compatibility

#include "/lib/util.glsl"




uniform float near;
uniform float far;

uniform float frameTime;
uniform float waterEnterTime;

in vec2 texcoord;
bool isNight = worldTime >= 13000 && worldTime < 24000;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  vec4 waterMask = texture(colortex8, texcoord);

  int blockID = int(waterMask) + 100;

  bool isWater = blockID == WATER_ID;
  bool inWater = isEyeInWater == 1.0;
  
  float depth = texture(depthtex1, texcoord).r;
  if(depth == 1.0){
    return;
  }

  

  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);


  #if DO_WATER_FOG == 1
  // Fog calculations
  float dist = length(viewPos) / far;
  float fogFactor = exp(-WATER_FOG_DENSITY * (0.8 - dist));
  vec4 fogColor = vec4(0.0039, 0.1529, 1.0, 1.0);
  vec4 darkFogColor = vec4(0.0118, 0.1412, 0.1216, 1.0);
  vec4 distantFogColor = exp(fogColor * (darkFogColor - dist));

  if(!inWater)
	{
    if(isWater && !isNight)
    {
    fogFactor = exp2(-WATER_FOG_DENSITY * (0.4 - dist));
    fogColor = mix(fogColor, darkFogColor, clamp(distantFogColor, 0.1, 9.0));
    color = mix(color, fogColor, clamp(fogFactor, 0.0, 1.0)) / 3;
    }
    else if (isWater && isNight)
    {
      fogFactor = exp(-WATER_FOG_DENSITY * (0.4 - dist));
    fogColor = mix(fogColor, darkFogColor, clamp(distantFogColor, 0.1, 9.0));
    color = mix(color, fogColor, clamp(fogFactor, 0.0, 1.0)) / 15;
    }
	}

	if(inWater)
	{
    if(!isWater)
    {
    fogFactor = exp2(-WATER_FOG_DENSITY * (0.6 - dist));
    fogColor = mix(fogColor, darkFogColor, clamp(distantFogColor, 0.0, 9.0));
    color = mix(color, fogColor, clamp(fogFactor, 0.0, 1.0)) / 3;
    }
     else if (!isWater && isNight)
    {
      fogFactor = exp(-WATER_FOG_DENSITY * (0.4 - dist));
    fogColor = mix(fogColor, darkFogColor, clamp(distantFogColor, 0.1, 9.0));
    color = mix(color, fogColor, clamp(fogFactor, 0.0, 1.0)) / 15;
    }

    if(rainStrength <= 1.0 && rainStrength > 0.0)
  {
    fogFactor = exp(-WATER_FOG_DENSITY * (0.4 - dist));
    fogColor = mix(fogColor, darkFogColor, clamp(distantFogColor, 0.1, 9.0));
    color = mix(color, fogColor, clamp(fogFactor, 0.0, 1.0)) / 15;
  }
   
	}
  #endif

  

}