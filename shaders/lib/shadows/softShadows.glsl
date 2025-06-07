#ifndef SOFTSHADOWS_GLSL
#define SOFTSHADOWS_GLSL

#include "/lib/util.glsl"
#include "/lib/common.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/distort.glsl"
 
 vec3 getSoftShadow(vec4 shadowClipPos, vec3 feetPlayerPos, vec3 normal, vec2 texcoord, vec3 shadowScreenPos)
 {
    
    feetPlayerPos += 0.07 * normal;
    vec4 shadowViewPos = mat4(shadowModelView) * vec4(feetPlayerPos, 1.0);
    
    shadowClipPos = mat4(shadowProjection) * shadowViewPos; 
    vec3 shadowClipNormal = mat3(shadowProjection) * (mat3(shadowModelView) * normal) * 0.25;
    shadowClipPos.w = 0.0;
    shadowClipPos += vec4(shadowClipNormal, 1.0);

    
       
    float sampleRadius = SHADOW_SOFTNESS * 0.0007;
    float noise = IGN(floor(gl_FragCoord.xy), frameCounter);

    vec3 shadowAccum = vec3(0.0); // sum of all shadow samples
    for(int i = 0; i < SHADOW_SAMPLES; i++)
    {
        vec2 offset = vogelDisc(i, SHADOW_SAMPLES, noise) * sampleRadius; 
        vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
        offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
        vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
        vec3 shadowScreenPos2 = shadowNDCPos * 0.5 + 0.5; // convert to screen space
        shadowAccum += getShadow(shadowScreenPos2); // take shadow sample
    
  }

  return shadowAccum / float(SHADOW_SAMPLES); // divide sum by count, getting average shadow
}




#endif // SOFTSHADOWS_GLSL