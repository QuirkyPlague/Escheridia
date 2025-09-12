#ifndef DRAWSHADOWS_GLSL
#define DRAWSHADOWS_GLSL

#include "/lib/uniforms.glsl"

vec3 getShadow(vec3 shadowScreenPos) {
  float transparentShadow = step(
    shadowScreenPos.z,
    texture(shadowtex0, shadowScreenPos.xy).r
  );
  if (transparentShadow == 1.0) {
    return vec3(1.0);
  }

  float opaqueShadow = step(
    shadowScreenPos.z,
    texture(shadowtex1, shadowScreenPos.xy).r
  );

  if (opaqueShadow == 0.0) {
    return vec3(0.0, 0.0, 0.0);
  }

  vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);

  return shadowColor.rgb * (1.0 - shadowColor.a);
}

#endif //DRAWSHADOWS_GLSL
