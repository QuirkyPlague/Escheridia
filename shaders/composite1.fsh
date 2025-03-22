#version 410 compatibility

#include "/lib/util.glsl"

uniform float far;
vec3 dayDistFogColor = vec3(0.2275, 0.3686, 0.7529);
vec3 earlyDistFogColor = vec3(0.9647, 0.302, 0.1176);
vec3 duskDistFogColor = vec3(0.9765, 0.1216, 0.0588);
vec3 nightDistFogColor = vec3(0.051, 0.051, 0.1451);
vec3 rainFogColor = vec3(0.5373, 0.5373, 0.5373);


in vec2 texcoord;

bool isNight = worldTime >= 13000 && worldTime < 24000;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex1, texcoord).r;
  if(depth == 1.0){
    return;
  }

  #if DO_DISTANCE_FOG == 1
  float farPlane = far * 4;
  
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);

  // Fog calculations
  float dist = length(viewPos) / far;
  float fogFactor = exp(-FOG_DENSITY * (1.2 - dist));
  float nightFogFactor = exp(-FOG_DENSITY * (0.133 / dist));
  float rainFogFactor = exp(-FOG_DENSITY * (0.75 - dist));

  vec3 fogColor = vec3(0);

	//Time of day color changes
  if(worldTime >= 0 && worldTime < 1000)
	{
	 	float time = smoothstep(600, 1000, float(worldTime));
	 	fogColor = mix(earlyDistFogColor, dayDistFogColor, time);
	}
    else if(worldTime >= 1000 && worldTime < 11500)
     {
        float time = smoothstep(10000, 11500, float(worldTime));
        fogColor = mix(dayDistFogColor, duskDistFogColor, time);
       
    }
    else if(worldTime >= 11500 && worldTime < 13000)
     {
        float time = smoothstep(11900, 13000, float(worldTime));
        fogColor = mix(duskDistFogColor, nightDistFogColor/2, time);
        fogFactor = mix(fogFactor, nightFogFactor, time );
    }
    else if (worldTime >= 13000 && worldTime < 24000)
  {
      float time = smoothstep(23215, 24000, float(worldTime));
      fogColor = mix(nightDistFogColor/2, earlyDistFogColor, time);
      fogFactor = mix(nightFogFactor, fogFactor, time );
  }
 
  vec3 currentFogColor = fogColor;

 

  if(rainStrength <= 1.0 && rainStrength > 0.0 && !isNight)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    fogFactor = mix(fogFactor, rainFogFactor, dryToWet);
    fogColor = mix(currentFogColor, rainFogColor, dryToWet);
    color.rgb = mix(color.rgb, fogColor, clamp(fogFactor, 0.0, 1.0));
  }
  else if(rainStrength <= 1.0 && rainStrength > 0.0 && isNight)
  {
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    fogFactor = mix(fogFactor, rainFogFactor, dryToWet);
    fogColor = mix(currentFogColor, rainFogColor, dryToWet) / 18;
    color.rgb = mix(color.rgb, fogColor, clamp(fogFactor, 0.0, 1.0));
  }
  
  

  color.rgb = mix(color.rgb, fogColor, clamp(fogFactor, 0.0, 9.0));
#endif
}