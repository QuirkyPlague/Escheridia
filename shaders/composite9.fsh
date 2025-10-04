#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/clouds.glsl"

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  
  float depth = texture(depthtex0, texcoord).r;
  vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

  vec3 origin = cameraPosition;
  vec3 endPos = feetPlayerPos;
  int cloudSteps = 40;
  vec3 noise =  blue_noise(floor(gl_FragCoord.xy), frameCounter, cloudSteps);

  vec3 clouds = cloudRaymarch(origin, endPos, cloudSteps,noise.x, feetPlayerPos);
  

}

