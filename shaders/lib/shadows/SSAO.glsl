#ifndef SSAO_GLSL
#define SSAO_GLSL

#include "/lib/util.glsl"

float linearizeDepth(float depth)
{
  
    float z = depth * 2.0 - 1.0; // Back to NDC
    return (2.0 * near * far) / (far + near - z * (far - near));
}


float ssao(vec3 viewPos, vec3 normal)
{
    vec3 viewNormal = mat3(gbufferModelView) * normal;
    vec3 viewDir = normalize(-viewPos); // from fragment toward camera
    vec3 bentNormal = normalize(mix(viewNormal, viewDir, 0.35)); // 0.35–0.5 works well
    const float radius = 3.5;
    const float bias   = 0.001;
    float occlusion    = 0.0;

    // --- Blue-noise basis ---
    vec3 noise = normalize(blue_noise(floor(gl_FragCoord.xy), frameCounter));
    vec3 tangent   = normalize(noise - bentNormal * dot(noise, bentNormal));
    vec3 bitangent = cross(bentNormal, tangent);
    mat3 TBN = mat3(tangent, bitangent, bentNormal);

    for (int i = 0; i < SSAO_SAMPLES; ++i)
    {
        vec3 sampled = normalize(blue_noise(floor(gl_FragCoord.xy), frameCounter, i));
        sampled.z = abs(sampled.z);
        sampled = TBN * sampled;

        // denser near center
        float scale = float(i) / float(SSAO_SAMPLES);
        float weight = mix(0.1, 1.0, scale * scale);
        sampled *= weight;

        // adaptive reach
        float adaptiveRadius = max(radius / abs(viewPos.z), 0.3);
        vec3 samplePos = viewPos + sampled * adaptiveRadius;

        // pseudo pixel offset (no pixelSize available)
        // 0.001 acts like 1 pixel in normalized projection space
        vec4 offset = gbufferProjection * vec4(samplePos, 1.0);
        offset.xyz /= offset.w;
        offset.xy = offset.xy * 0.5 + 0.5;
        offset.xy += vec2(blue_noise(floor(gl_FragCoord.xy * 0.5), i).xy - 0.5) * 0.002;

        float sampleDepth = linearizeDepth(texture(depthtex0, offset.xy).r);
        float viewDepth   = abs(viewPos.z);
        float samplePosZ  = abs(samplePos.z);

        // softer attenuation
        float rangeCheck = exp(-abs(viewDepth - sampleDepth) * 25.45 / radius);
        occlusion += (sampleDepth < samplePosZ + bias ? 1.0 : 0.0) * rangeCheck;
    }

    occlusion = 1.0 - (occlusion / float(SSAO_SAMPLES));
    occlusion = mix(1.0, occlusion, 0.85); // prevents overly strong darkening
    return occlusion;
}

#endif