#version 410 compatibility

#include "/lib/util.glsl"




uniform float near;
uniform float far;

uniform float frameTime;
uniform float waterEnterTime;

in vec2 texcoord;


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  vec4 waterMask = texture(colortex6, texcoord);

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
  float fogFactor = exp2(-WATER_FOG_DENSITY * (0.8 - dist));
  vec4 fogColor = vec4(0.0667, 0.1608, 0.502, 1.0);
  vec4 darkFogColor = vec4(0.0157, 0.0471, 0.2196, 1.0);
  vec4 distantFogColor = exp(fogColor * (darkFogColor - dist));

  if(!inWater)
	{
    if(isWater)
    {
    fogColor = mix(fogColor, darkFogColor, clamp(distantFogColor, 0.0, 1.0));
    color = mix(color, fogColor, clamp(fogFactor, 0.0, 1.0));
    }
	}

	if(inWater)
	{
    if(!isWater)
    {
    fogColor = mix(fogColor, darkFogColor, clamp(distantFogColor, 0.0, 1.0));
    color = mix(color, fogColor, clamp(fogFactor, 0.0, 1.0));
    }
    else
    {
      fogColor = mix(fogColor, vec4(0.1412, 0.8471, 0.6941, 1.0), clamp(distantFogColor, 0.0, 1.0));
      color = mix(color, fogColor, clamp(fogFactor, 0.0, 1.0));
    }
   
	}
  #endif

  

}