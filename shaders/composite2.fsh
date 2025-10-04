#version 400 compatibility

#include "/lib/uniforms.glsl"
#include "/lib/atmosphere/godrays.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;
  float depth1 = texture(depthtex1, texcoord).r;

  vec2 lightmap = texture(colortex1, texcoord).rg;
  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
  vec3 eyePlayerPos = feetPlayerPos - gbufferModelViewInverse[3].xyz; 
  vec3 eyeCameraPosition = cameraPosition + gbufferModelViewInverse[3].xyz; 
  vec3 worldPos = eyePlayerPos + eyeCameraPosition;
  vec3 sunlightColor = vec3(0.0);
  vec3 sunColor = currentSunColor(sunlightColor);
  #if DISTANCE_FOG_GLSL == 1


    vec3 atmosphereFog = atmosphericFog(
    color.rgb,
    eyePlayerPos,
    texcoord,
    depth,
    lightmap
  );
  vec3 fullFog = atmosphereFog;
   
  if (!inWater) {
    color.rgb = mix(color.rgb, fullFog, 0.5);
  }
 
  
  #endif

}

