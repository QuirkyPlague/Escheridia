#ifndef SPHERICAL_HARMONICS_GLSL
#define SPHERICAL_HARMONICS_GLSL

#include "/lib/atmosphere/sky.glsl"


vec3 computeSkylight(vec3 n)
{
    vec3 up = vec3(0.0, 1.0, 0.0);

    // Build tangent basis
    vec3 right = normalize(cross(up, n));
    vec3 forward = normalize(cross(n, right));

    vec3 result = vec3(0.3);

    // Sample directions around the normal
    vec3 dirs[6];
    dirs[0] = normalize(n + vec3(0, 1, 0)); // straight up from surface
    dirs[1] = normalize(n - vec3(0, -1, 0) + 0.5); // bottom facing surface
    dirs[2] = normalize(n + right + 0.5);
    dirs[3] = normalize(n - right - 0.5);
    dirs[4] = normalize(n + forward + 0.5);
    dirs[5] = normalize(n - forward - 0.5);

    for (int i = 0; i < 6; i++)
    {
        vec3 d = dirs[i];
        float w = max(dot(n, d), 0.0);
        result += skyScattering(d) * w;
    }

    return result / 6.0;
}

#endif