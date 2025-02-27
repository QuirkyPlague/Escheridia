#version 410 compatibility

#include "/lib/util.glsl"



uniform float exposure;


vec3 uncharted2Tonemap(vec3 x) {
   float A = U2_SHOULDER;
   float B = U2_LINEAR_STRENGTH;
   float C = U2_LINEAR_ANGLE;
   float D = U2_TOE;
   float E = U2_TOE_NUMERATOR;
   float F = U2_TOE_DENOMINATOR;
  float W = 11.2;
  return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

vec3 uncharted2(vec3 y) {
  const float W = 11.2;
  float exposureBias = 2.0;
  vec3 curr = uncharted2Tonemap(exposureBias * y);
  vec3 whiteScale = 1.0 / uncharted2Tonemap(vec3(W));
  return curr * whiteScale;
}


vec3 aces(vec3 v)
{
    v *= 0.6;
    float a = 1.55;
    float b = 0.23;
    float c = 1.43;
    float d = 1.39;
    float e = 0.84;
    return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0, 1.0);
}
vec3 aces_approx(vec3 y) {
  const float W = 11.2;
  float exposureBias = 2.0;
  vec3 curr = aces(exposureBias * y);
  vec3 whiteScale = 1.0 / aces(vec3(W));
  return curr * whiteScale;
}



in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
    
    vec3 exposureCompensation = vec3 (1.0/2.2);
    
   
   
    
    #if TONEMAPPING_TYPE == 1
    
        color.rgb = uncharted2(pow(color.rgb, exposureCompensation));
    
    #elif TONEMAPPING_TYPE == 0
    
         color.rgb = aces_approx(pow(color.rgb, exposureCompensation));
    #else 
    
        color.rgb = (pow(color.rgb, exposureCompensation));
    #endif
   
   	 color.rgb = CSB(color.rgb, brightness, saturation, contrast);
    
}