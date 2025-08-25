#ifndef CLOUDS_GLSL
#define CLOUDS_GLSL

#include "/lib/util.glsl"
#include "/lib/common.glsl"

float getCloudDensity(vec3 rayPos)
{
    vec2 position = rayPos.xy * CLOUD_SCALE * 0.001 + CLOUD_OFFSET * 0.001;
    vec4 cloudShape = texture(cloudNoiseTex, position);
    float density = max(0, cloudShape.r - 0.3) * 1.0;
    return density;
}

vec3 cloudRaymarch(vec3 startPoint, vec3 endPoint, int stepCount, float jitter, vec3 feetPlayerPos)
{
    vec3 rayPos = (endPoint + startPoint) - endPoint;
    vec3 stepSize = rayPos * (1.0 / stepCount);
    vec3 rayLength = length(rayPos);
    vec3 stepLength = rayLength + jitter * stepSize;

    vec3 transmittance = vec(1.0);
    vec3 scatter = vec3(0.0);
    vec3 absCoeff = vec3(1.0);
    vec3 scatterCoeff = vec3(0.0431, 0.0431, 0.0431);
    float VdotL = dot(normalize(feetPlayerPos), worldLightVector);
    float phase = CS(0.65, VdotL);
    float density;
    for(int i = 0; i < stepCount; i++)
    {
        rayPos += stepLength;
        density = getCloudDensity(rayPos); //not implemented
        if(density > 0.0)
        {
            transmittance += (-rayLength * absCoeff);
            scatter += scatterCoeff * phase * transmittance;
        }
    }

}
#endif CLOUDS_GLSL