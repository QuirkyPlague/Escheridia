#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/atmosphere/distanceFog.glsl"
#include "/lib/atmosphere/clouds.glsl"
in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    color = texture(colortex0, texcoord);

    //space conversions
    float depth=texture(depthtex0,texcoord).r;
    vec3 NDCPos=vec3(texcoord.xy,depth)*2.-1.;
    vec3 viewPos=projectAndDivide(gbufferProjectionInverse,NDCPos);
    vec3 feetPlayerPos=(gbufferModelViewInverse*vec4(viewPos,1.)).xyz;
    vec3 eyePlayerPos=feetPlayerPos-gbufferModelViewInverse[3].xyz;
    vec3 worldPos=feetPlayerPos+cameraPosition;
    vec3 noise;
    for(int i=0;i<STBN_SAMPLES;i++){
        noise+=blue_noise(floor(gl_FragCoord.xy),frameCounter,i);
    }

  
  
}
