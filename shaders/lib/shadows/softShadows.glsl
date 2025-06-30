#ifndef SOFTSHADOWS_GLSL
#define SOFTSHADOWS_GLSL

#include "/lib/util.glsl"
#include "/lib/common.glsl"
#include "/lib/shadows/drawShadows.glsl"
#include "/lib/shadows/distort.glsl"
 
 vec3 getSoftShadow(vec4 shadowClipPos, vec3 normal, float SSS)
 {   
   float sampleRadius = SHADOW_SOFTNESS * 0.00034;
   float noise = IGN(floor(gl_FragCoord.xy), frameCounter);

   vec3 shadowNormal = mat3(shadowModelView) * normal;
   float shadowMapPixelSize = 1.0 / float(SHADOW_RESOLUTION);
   const vec3 biasAdjustFactor = vec3(shadowMapPixelSize * 2.0, shadowMapPixelSize * 2.0, -0.00006103515625);

   if(SSS > 64.0/255.0)
   {
      sampleRadius *= SSS;
   }   
   
   vec3 shadowAccum = vec3(0.0); // sum of all shadow samples
   for(int i = 0; i < SHADOW_SAMPLES; i++)
   {
      vec2 offset = vogelDisc(i, SHADOW_SAMPLES, noise) * sampleRadius; 
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadowScreenPos += shadowNormal * biasAdjustFactor;
      shadowAccum += getShadow(shadowScreenPos); // take shadow sample
        
   }

  return shadowAccum / float(SHADOW_SAMPLES); // divide sum by count, getting average shadow
}




#endif // SOFTSHADOWS_GLSL