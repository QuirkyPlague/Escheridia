#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/spaceConversions.glsl"

vec3 dayDistFogColor;
in vec2 texcoord;

vec4 waterMask=texture(colortex8,texcoord);

int blockID=int(waterMask)+100;

bool isWater=blockID==WATER_ID;
bool inWater=isEyeInWater==1.;

/* RENDERTARGETS: 0 */
layout(location=0)out vec4 color;

void main(){
  color=texture(colortex0,texcoord);
  
  float depth=texture(depthtex0,texcoord).r;
  float depth1=texture(depthtex1,texcoord).r;
  
  if(depth==1.)
  {
    return;
  }
  
  vec2 lightmap=texture(colortex1,texcoord).rg;
  #if DO_DISTANCE_FOG==1
  

  vec3 NDCPos=vec3(texcoord.xy,depth)*2.-1.;
  vec3 viewPos=projectAndDivide(gbufferProjectionInverse,NDCPos);
  
  // Fog calculations
  float dist=length(viewPos)/far;
  float fogFactor=exp(-FOG_DENSITY*(1.1-dist));
  float nightFogFactor=exp(-FOG_DENSITY*(.87-dist));
  float rainFogFactor=exp(-FOG_DENSITY*(.55-dist));
  vec3 rainFogColor=vec3(.4);

  vec3 scatterColor;
  vec3 absorption=vec3(1.,1.,1.);
  scatterColor=applySky(scatterColor,texcoord,depth);

  
  if(!inWater)
  {
    
    if(isNight)
    {
      fogFactor=nightFogFactor;
      scatterColor *= 0.5;
    }
    
    if(rainStrength<=1.&&rainStrength>0.&&!isNight)
    {
      float dryToWet=smoothstep(0.,1.,float(rainStrength));
      fogFactor=mix(fogFactor,rainFogFactor,dryToWet);
      scatterColor = mix(scatterColor, vec3(0.4784, 0.4784, 0.4784), dryToWet);
    }
    else if(rainStrength<=1.&&rainStrength>0.&&isNight)
    {
      float dryToWet=smoothstep(0.,1.,float(rainStrength));
      fogFactor=mix(fogFactor,rainFogFactor,dryToWet);
      scatterColor = mix(scatterColor, vec3(0.1647, 0.1647, 0.1647), dryToWet);
    }
    
    vec3 absorptionFactor=exp2(-absorption*fogFactor);
    color.rgb*=absorptionFactor;
    color.rgb+=scatterColor/absorption*(1.-absorptionFactor);
  }
  
  #endif
}