#version 330 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/skyColor.glsl"
#include "/lib/blockID.glsl"


in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location=0)out vec4 color;

void main(){
  color=texture(colortex0,texcoord);
  vec4 waterMask=texture(colortex4,texcoord);
  vec2 lightmap=texture(colortex1,texcoord).rg;
  int blockID=int(waterMask)+100;
  
  bool isWater=blockID==WATER_ID;
  bool inWater=isEyeInWater==1.;
  
  float depth=texture(depthtex0,texcoord).r;
  float depth1=texture(depthtex1,texcoord).r;
  
  vec3 encodedNormal=texture(colortex2,texcoord).rgb;
  vec3 normal=normalize((encodedNormal-.5)*2.);// we normalize to make sure it is of unit length
  normal=mat3(gbufferModelView)*normal;
  vec3 NDCPos=vec3(texcoord.xy,depth)*2.-1.;
  vec3 viewPos=projectAndDivide(gbufferProjectionInverse,NDCPos);
  vec3 viewDir=normalize(viewPos);
  vec3 reflectedColor=calcSkyColor((reflect(viewDir,normal)));
  
;

  // Fog calculations
  //float dist = length(viewPos) / far;
  float dist0=length(screenToView(texcoord,depth));
  float dist1=length(screenToView(texcoord,depth1));
  float dist=max(0,dist1-dist0);
  
  vec3 absorption= WATER_EXTINCTION;
  vec3 inscatteringAmount= WATER_SCATTERING;
  inscatteringAmount *= 0.1;
  

  if(inWater)
  {
      dist=dist0;
      vec3 absorptionFactor=exp(-absorption*WATER_FOG_DENSITY*(dist*.44));
      color.rgb*=absorptionFactor;
      color.rgb+= inscatteringAmount  /absorption*(1.-absorptionFactor);
    
  }
 


  
}