#ifndef SKY_COLOR_GLSL
#define SKY_COLOR_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"

const vec3 horizonColor = vec3(0.3294, 0.6353, 0.702);
const vec3 zenithColor = vec3(0.2627, 0.4353, 0.7098);
const vec3 earlyHorizon = vec3(0.4314, 0.2745, 0.0);
const vec3 earlyZenith =  vec3(0.0431, 0.3647, 0.3765);
const vec3 lateHorizon = vec3(0.3804, 0.1765, 0.098);
const vec3 lateZenith = vec3(0.2706, 0.451, 0.5529);
const vec3 nightHorizon = vec3(0.0353, 0.1059, 0.2118);
const vec3 nightZenith = vec3(0.0118, 0.0118, 0.0118);
const vec3 rainHorizon = vec3(0.8157, 0.8157, 0.8157);
const vec3 rainZenith = vec3(0.5333, 0.5333, 0.5333); 
vec3 horizon;
vec3 zenith;


float fogify(float x, float w) {
	return w / (x * x + w);
}

vec3 calcSkyColor(vec3 pos) {
	 if (worldTime >= 0 && worldTime < 1000)
  {
    //smoothstep equation allows interpolation between times of day
    float time = smoothstep(0, 1000, float(worldTime));
   horizon = mix(earlyHorizon, horizonColor, time);
   zenith = mix(earlyZenith, zenithColor,time);
  }
   else if (worldTime >= 1000 && worldTime < 11500)
  {
     float time = smoothstep(10000, 11500, float(worldTime));
	horizon = mix(horizonColor, lateHorizon, time);
   	zenith = mix(zenithColor, lateZenith,time);
  }
  else if (worldTime >= 11500 && worldTime < 13000)
  {
     float time = smoothstep(11500, 13000, float(worldTime));
    horizon = mix(lateHorizon, nightHorizon, time);
   	zenith = mix(lateZenith, nightZenith,time);
  }
   else if (worldTime >= 13000 && worldTime < 24000)
  {
    float time = smoothstep(23215, 24000, float(worldTime));
	horizon = mix(nightHorizon, earlyHorizon, time);
   	zenith = mix(nightZenith, earlyZenith,time);
	  
  }
  if(rainStrength <= 1.0 && rainStrength > 0.0)
  {
    vec3 currentZenithColor = zenith;
    vec3 currentHorizonColor = horizon;
    if(worldTime >= 13000 && worldTime < 24000)
    {
      currentZenithColor *=  0.03;
      currentHorizonColor *=  0.03;
    }
    float dryToWet = smoothstep(0.0, 1.0, float(rainStrength));
    zenith = mix(currentZenithColor, rainZenith, dryToWet);
    horizon = mix(currentHorizonColor, rainHorizon, dryToWet);
  }
    
	 horizon = pow(horizon, vec3(2.2));
	 zenith = pow(zenith, vec3(2.2));
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(zenith, horizon, fogify(max(upDot, 0.0), 0.02));
}


#endif //SKY_COLOR_GLSL