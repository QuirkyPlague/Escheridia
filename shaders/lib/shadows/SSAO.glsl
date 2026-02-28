#ifndef SSAO_GLSL
#define SSAO_GLSL

#include "/lib/util.glsl"


float SSAO(vec3 viewPos, vec3 normal)
{   
    normal = mat3(gbufferModelView) * normal;
    float viewDist = length(viewPos);
    
   
    float bias = 0.0025;
    
    mat3 tbn;
    tbn[2] = normal;
    tbn[0] = normal.yzx;
    tbn[1] = cross(tbn[0], tbn[2]);  

    float occlusion = 0.0;
   
    
    for(int i = 0; i < SSAO_SAMPLES; i++)
    {   
        vec3 noise = blue_noise(floor(gl_FragCoord.xy), frameCounter, i);
        float cosTheta = sqrt(noise.x);
        float sinTheta = sqrt(1.0 - noise.x);
        float phi = 2.0 * PI * noise.y;
        
        vec3 generatedSample = tbn * vec3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);
       
        float radius = noise.z;
        vec3 samplePos = generatedSample * radius * SSAO_RADIUS; 
        
        vec3 sampleViewPos = viewPos + samplePos;
        vec4 sampledClip = gbufferProjection * vec4(sampleViewPos, 1.0);
        vec3 sampledNDC = sampledClip.xyz / sampledClip.w;
        vec2 sampleScreen = sampledNDC.xy * 0.5 + 0.5;
    
        float sampleScreenDepth = (texture(depthtex0, sampleScreen.xy).r);
        float sampleNDCDepth = sampleScreenDepth * 2.0 - 1.0;
        float sampleViewDepth = gbufferProjectionInverse[3].z / (gbufferProjectionInverse[2].w * sampleNDCDepth + gbufferProjectionInverse[3].w);

        float viewDepth   = abs(viewPos.z);
       float sampleOcclusion =
      float(sampleViewDepth >= sampleViewPos.z + bias) * smoothstep(0.0, 1.0, SSAO_RADIUS / abs(sampleViewDepth - sampleViewPos.z));
      occlusion += 1.0 - sampleOcclusion * SSAO_INTENSITY;
     
    }

    
    
    return occlusion / float(SSAO_SAMPLES);
}
#endif
