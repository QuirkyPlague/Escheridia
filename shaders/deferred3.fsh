#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"
#include "/lib/atmosphere/clouds.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);
    
     vec2 lightmap=texture(colortex1,texcoord).rg;
    float depth=texture(depthtex0,texcoord).r;
    
  
    
    vec4 SpecMap=texture(colortex3,texcoord);
    bool isMetal=SpecMap.g>=230./255.;
    vec3 surfNorm=texture(colortex4,texcoord).rgb;
    vec3 normal=normalize((surfNorm-.5)*2.);
    //space conversions
    vec3 NDCPos=vec3(texcoord.xy,depth)*2.-1.;
    vec3 viewPos=projectAndDivide(gbufferProjectionInverse,NDCPos);
    vec3 feetPlayerPos=(gbufferModelViewInverse*vec4(viewPos,1.)).xyz;
    vec3 eyePlayerPos=feetPlayerPos-gbufferModelViewInverse[3].xyz;
    vec3 worldPos=feetPlayerPos+cameraPosition;
    vec4 waterMask=texture(colortex5,texcoord);
    int blockID=int(waterMask)+100;
    bool isWater=blockID==WATER_ID;
    vec3 noise;
    for(int i=0;i<STBN_SAMPLES;i++){
        noise+=blue_noise(floor(gl_FragCoord.xy),frameCounter,i);
    }

    
    vec3 startPos=vec3(0.,0.,0.);
    vec3 endPos=worldPos;
    vec3 fog=color.rgb;
    
    vec3 start = cameraPosition;
    #ifdef CLOUDS
    color.rgb = cloudRaymarch(worldPos, noise, color.rgb);
    #endif
  
}
