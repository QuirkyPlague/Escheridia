#version 330 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"
#include "/lib/water/waterFog.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
  vec4 SpecMap = texture(colortex5, texcoord);
  vec4 stars = texture(colortex8, texcoord);
  vec4 sun = texture(colortex8, texcoord);
  vec3 moon = texture(colortex8, texcoord).rgb;
  float depth = texture(depthtex0, texcoord).r;
  vec3 NDCPos = vec3(texcoord, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz;
  bool isMetal = SpecMap.g >= 230.0 / 255.0;
  if (depth == 1) {
    color += stars;
    color += sun;
    color.rgb += moon;
  }

}

