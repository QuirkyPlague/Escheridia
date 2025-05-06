#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL


vec3 getShadow(vec3 shadowScreenPos)
{
  float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r); // sample the shadow map containing everything

  /*
  note that a value of 1.0 means 100% of sunlight is getting through
  not that there is 100% shadowing
  */

  if(transparentShadow == 1.0){
    /*
    since this shadow map contains everything,
    there is no shadow at all, so we return full sunlight
    */
	
    return vec3(1.0, 1.0, 1.0);
  }

  float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r); // sample the shadow map containing only opaque stuff

  if(opaqueShadow == 0.0){
    // there is a shadow cast by something opaque, so we return no sunlight
    return vec3(0.0, 0.0, 0.0);
  }

  // contains the color and alpha (transparency) of the thing casting a shadow
  vec4 shadowColor = texture(shadowcolor1, shadowScreenPos.xy);
  /*
  we use 1 - the alpha to get how much light is let through
  and multiply that light by the color of the caster
  */
	return shadowColor.rgb * (1.0 - shadowColor.a);
}



#if DO_SOFT_SHADOW == 1
//soft shadow calculation
  vec3 getSoftShadow(vec4 shadowClipPos, vec2 texcoord, vec3 geoNormal, vec3 feetPlayerPos){
 
  
  vec3 shadowClipNormal = mat3(shadowProjection) * (mat3(shadowModelView) * geoNormal) * 0.4;

  //feetPlayerPos += 0.09 * geoNormal; 
  vec4 shadowViewPos = mat4(shadowModelView) * vec4(feetPlayerPos, 1.0);
  
  shadowClipPos = mat4(shadowProjection) * shadowViewPos; 
  shadowClipPos.w = 0.0;
  shadowClipPos += vec4(shadowClipNormal, 1.0);
    vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
  float noise = IGN(floor(gl_FragCoord.xy), frameCounter);

  vec3 shadowAccum = vec3(0.0, 0.0, 0.0); // sum of all shadow samples
   float sampleRadius = SHADOW_SOFTNESS * 0.0007;
  
   
 for(int i = 0; i < SHADOW_SAMPLES; i++){
      vec2 offset = vogelDisc(i, SHADOW_SAMPLES, noise) * sampleRadius; 
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadowAccum += getShadow(shadowScreenPos); // take shadow sample
    
  }
 return shadowAccum / float(SHADOW_SAMPLES); // divide sum by count, getting average shadow
}
#endif

#endif //SHADOWS_GLSL