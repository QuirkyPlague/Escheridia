#version 330 compatibility

#include "/lib/uniforms.glsl"

uniform int renderStage;

const vec3 horizonColor = vec3(0.6353, 0.8314, 0.8706);
const vec3 zenithColor = vec3(0.4392, 0.6157, 0.7608);
const vec3 earlyHorizon = vec3(0.7216, 0.5882, 0.3451);
const vec3 earlyZenith =  vec3(0.2941, 0.5922, 0.7412);
const vec3 lateHorizon = vec3(0.7098, 0.4235, 0.3216);
const vec3 lateZenith = vec3(0.3922, 0.4941, 0.6588);
const vec3 nightHorizon = vec3(0.2863, 0.3765, 0.5176);
const vec3 nightZenith = vec3(0.0588, 0.102, 0.3412); 
vec3 horizon;
vec3 zenith;
in vec3 modelPos;
in vec3 viewPos;
in vec4 glcolor;

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
    float time = smoothstep(23000, 24000, float(worldTime));
	horizon = mix(nightHorizon, earlyHorizon, time);
   	zenith = mix(nightZenith, earlyZenith,time);
	  
  }
	
	
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(zenith, horizon, fogify(max(upDot, 0.0), 0.02));
}


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
if (renderStage == MC_RENDER_STAGE_STARS) {
		color = glcolor * 2.2;
    
	} else {
		vec3 pos = viewPos;
		color = vec4(calcSkyColor(normalize(pos)), 1.0);
      color.rgb = pow(color.rgb, vec3(2.2));
	}
}
