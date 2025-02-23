#version 410 compatibility

#include "/lib/util.glsl"


in vec2 texcoord;

//soft shadow calculation
vec3 getSoftShadow(vec4 shadowClipPos){
  const float range = SHADOW_SOFTNESS / 2; // how far away from the original position we take our samples from
  const float increment = range / SHADOW_QUALITY; // distance between each sample

  float noise = IGN(floor(gl_FragCoord.xy), frameCounter);

  float theta = noise * radians(360.0); // random angle using noise value
  float cosTheta = cos(theta);
  float sinTheta = sin(theta);

  mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta); // matrix to rotate the offset around the original position by the angle

  vec3 shadowAccum = vec3(0.0, 0.0, 0.0); // sum of all shadow samples
  int samples = 0;

  for(float x = -range; x <= range; x += increment){
    for (float y = -range; y <= range; y+= increment){
      vec2 offset = rotation * vec2(x, y) / shadowMapResolution; // offset in the rotated direction by the specified amount. We divide by the resolution so our offset is in terms of pixels
      vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0); // add offset
      offsetShadowClipPos.z -= 0.0013; // apply bias
      offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz); // apply distortion
      vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w; // convert to NDC space
      vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5; // convert to screen space
      shadowAccum += getShadow(shadowScreenPos); // take shadow sample
      samples++;
    }
  }
 return shadowAccum / float(samples); // divide sum by count, getting average shadow
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	color.rgb += texture(colortex7, texcoord).rgb;
	

	
}