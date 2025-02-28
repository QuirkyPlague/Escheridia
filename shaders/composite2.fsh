#version 410 compatibility

#include "/lib/distort.glsl"
#include "/lib/common.glsl"


uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform float near;
uniform float far;
uniform int worldTime;
uniform mat4 gbufferProjectionInverse;
uniform int isEyeInWater;
uniform int frameCounter;
uniform float frameTime;
uniform float waterEnterTime;

in vec2 texcoord;
uniform float wetness;
const float wetnessHalflife = 600.0;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex1, texcoord).r;
  if(depth == 1.0){
    return;
  }

  

  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);


  #if DO_WATER_FOG == 1
  // Fog calculations
  float dist = length(viewPos) / far;
  float fogFactor = exp2(-WATER_FOG_DENSITY * (0.3 - dist));
  vec4 fogColor = vec4(0.0667, 0.1608, 0.502, 1.0);
  vec4 darkFogColor = vec4(0.0157, 0.0471, 0.2196, 1.0);
  vec4 distantFogColor = exp2(fogColor * (darkFogColor - dist));

	if(isEyeInWater == 1)
	{
		float time = smoothstep(10,0,float(waterEnterTime));
    fogColor = mix(fogColor, darkFogColor, clamp(distantFogColor, 0.0, 1.0));
		
    color = mix(color, fogColor, clamp(fogFactor, 0.0, 1.0));
	}
  #endif

  

}