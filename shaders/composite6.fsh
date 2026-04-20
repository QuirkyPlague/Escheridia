#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/blockID.glsl"
#include "/lib/atmosphere/volumetrics.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0,13 */
layout(location=0)out vec4 color;
layout(location = 1) out vec4 history;
void main(){
    color=texture(colortex0,texcoord);
    vec2 lightmap=texture(colortex1,texcoord).rg;
    float depth=texture(depthtex0,texcoord).r;
    
    
   
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

    vec3 noise= blue_noise(floor(gl_FragCoord.xy),frameCounter,STBN_SAMPLES);
    
    vec3 shadowViewPos_start=(shadowModelView*vec4(vec3(0.),1.)).xyz;
    vec4 shadowClipPos_start=shadowProjection*vec4(shadowViewPos_start,1.);
    
    vec3 shadowViewPos_end=(shadowModelView*vec4(feetPlayerPos,1.)).xyz;
    vec4 shadowClipPos_end=shadowProjection*vec4(shadowViewPos_end,1.);
  
    #ifdef VOLUMETRICS
    vec4 history = texture(colortex13, texcoord);
    color.rgb = traceFog(worldPos,color.rgb,history,texcoord);
    #endif
    

    


}

