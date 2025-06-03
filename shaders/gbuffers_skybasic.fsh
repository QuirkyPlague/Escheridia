#version 330 compatibility

#include "/lib/uniforms.glsl"

uniform int renderStage;

const vec3 horizonColor = vec3(0.5255, 0.6941, 0.7255);
const vec3 zenithColor = vec3(0.2039, 0.4392, 0.8157);
const vec3 earlyHorizon = vec3(0.5608, 0.3529, 0.2235);
const vec3 earlyZenith =  vec3(0.1569, 0.4941, 0.5529);
const vec3 lateHorizon = vec3(0.6588, 0.2549, 0.1098);
const vec3 lateZenith = vec3(0.2706, 0.451, 0.5529);
const vec3 nightHorizon = vec3(0.0392, 0.0784, 0.1373);
const vec3 nightZenith = vec3(0.0078, 0.0196, 0.0824); 
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
    float time = smoothstep(23215, 24000, float(worldTime));
	horizon = mix(nightHorizon, earlyHorizon, time);
   	zenith = mix(nightZenith, earlyZenith,time);
	  
  }
	
	
	float upDot = dot(pos, gbufferModelView[1].xyz); //not much, what's up with you?
	return mix(zenith, horizon, fogify(max(upDot, 0.0), 0.01));
}


/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
if (renderStage == MC_RENDER_STAGE_STARS) {
		color = glcolor * 5.5;
	} else {
		vec3 pos = viewPos;
		color = vec4(calcSkyColor(normalize(pos)), 1.0);
	}
}
