#ifndef DRAWSHADOWS_GLSL
#define DRAWSHADOWS_GLSL

#include "/lib/uniforms.glsl"

vec3 getShadow(vec3 shadowScreenPos) {
  float transparentShadow = step(
    shadowScreenPos.z,
    texture(shadowtex0, shadowScreenPos.xy).r
  ); // sample the shadow map containing everything

  /*
  note that a value of 1.0 means 100% of sunlight is getting through
  not that there is 100% shadowing
  */

  if (transparentShadow == 1.0) {
    /*
    since this shadow map contains everything,
    there is no shadow at all, so we return full sunlight
    */
    return vec3(1.0);
  }

  float opaqueShadow = step(
    shadowScreenPos.z,
    texture(shadowtex1, shadowScreenPos.xy).r
  ); // sample the shadow map containing only opaque stuff

  if (opaqueShadow == 0.0) {
    // there is a shadow cast by something opaque, so we return no sunlight
    return vec3(0.0, 0.0, 0.0);
  }

  // contains the color and alpha (transparency) of the thing casting a shadow
  vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);

  /*
  we use 1 - the alpha to get how much light is let through
  and multiply that light by the color of the caster
  */
  return shadowColor.rgb * (2.0 - shadowColor.a);
}

#endif //DRAWSHADOWS_GLSL
