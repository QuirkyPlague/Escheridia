#ifndef SSR_GLSL
#define SSR_GLSL

//taken fromn Blemu's training raytracer found at https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3
#define BINARY_REFINEMENT 1 //[0 1]
#define BINARY_COUNT 4
#define BINARY_DECREASE 0.5
uint binarySteps = uint(BINARY_COUNT);

const float handDepth = MC_HAND_DEPTH * 0.5 + 0.5;

float getDepth(vec2 pos, sampler2D depthBuffer) {
  return texelFetch(depthBuffer, ivec2(pos * vec2(viewWidth, viewHeight)), 0).r;
}

vec3 diagonal(mat4 mat) {
  return vec3(mat[0].x, mat[1].y, mat[2].z);
}
vec3 projectionOrthogonal(mat4 mat, vec3 v) {
  return diagonal(mat) * v + mat[3].xyz;
}

vec3 viewToScreen(vec3 viewPos) {
  return projectionOrthogonal(gbufferProjection, viewPos) / -viewPos.z * 0.5 +
  0.5;
}

// Takes the minimum of 3 values
float minOf(vec3 x) {
  return min(x.x, min(x.y, x.z));
}

float minOf(vec2 x) {
  return min(x.x, x.y);
}

// Binary refinement to improve sampled quality by stepping back and forth until it is closer to the actual result
vec2 binaryRefinement(in vec3 screenRayPos, in vec3 screenRayDir, in float sampledDepth, in bool intersection){
    // Reuse stored sampled depth and intersection to use 1 less depth sample
    for(uint i = 1u; i <= binarySteps; i++){
        // Refine ray direction
        screenRayDir *= 0.5;
        screenRayPos += intersection ? -screenRayDir : screenRayDir;

        // Return early if we're on the last iteration
        if(i == binarySteps) return screenRayPos.xy;

        // Get current texture depth
        sampledDepth = texelFetch(depthtex0, ivec2(screenRayPos.xy), 0).x;
        // Check intersection
        intersection = sampledDepth <= screenRayPos.z;
    }

    // Alas, the ray has reached the end of its journey :,)
    return screenRayPos.xy;
}

// This raytracer is stupid fast I swear...

// With the help of @Lipesto the goat on ShaderLABs
// Based from Belmu's raytracer https://github.com/BelmuTM/NobleRT
// Basically an upgrade to Shadax's raytracer https://github.com/Shadax-stack/MinecraftSSR
//THANKS ELDESTON!!!!
vec3 rayTraceScene(in vec3 screenPos, in vec3 viewPos, in vec3 rayDir, in float dither){
    // Fix for the blob when player is near a surface. From BÃ¡lint#1673
    if(rayDir.z > -viewPos.z) return vec3(0);

    // Get screenspace ray direction
    vec3 screenRayDir =  viewToScreen(viewPos + rayDir) - screenPos;

    // This code prevents oversampling/undersampling of a ray
    screenRayDir *= minOf((step(vec2(0), screenRayDir.xy) - screenPos.xy) / screenRayDir.xy);

    // Calculate ray length and normalize ray direction
    float rayLength = max(abs(screenRayDir.x), abs(screenRayDir.y)) * SSR_STEPS;
    screenRayDir /= rayLength;

    // Scale to screen size
    screenRayDir.xy *= vec2(viewWidth, viewHeight);

    // Apply dithering
    vec3 screenRayPos = vec3(gl_FragCoord.xy, screenPos.z) + screenRayDir * dither;
    float depthLenience = max(
    abs(screenRayDir.z) * 1.0,
    0.02 / (viewPos.z * viewPos.z)
    ); // From Dr Desten
    // Keep track of depth
    float sampledDepth = 0.0;
    // Keep track of intersections
    bool intersection = false;

    // ULTRA FAST RAT RACING!!!111!!1!
    // https://www.youtube.com/watch?v=atuFSv2bLa8
    for(uint i = 0u; i < uint(rayLength); i++){
        // We continue ray tracing
        screenRayPos += screenRayDir;

        // If current pos is out of bounds, exit immediately
        if(screenRayPos.x < 0 || screenRayPos.y < 0 || screenRayPos.x > viewWidth || screenRayPos.y > viewHeight) return vec3(0);

        // Get current texture depth
        sampledDepth = texelFetch(depthtex0, ivec2(screenRayPos.xy), 0).x;

        // If hand return immediately
        if(sampledDepth <= 0.56) return vec3(0);

        // Check intersection
        intersection = sampledDepth <= screenRayPos.z && abs(depthLenience - (screenRayPos.z - sampledDepth)) < depthLenience ;

        // If intersection
        if(intersection) break;
    }

    // If sky or no intersection has been found return immediately
    if(sampledDepth == 1 || !intersection) return vec3(0);

    // Do binary refinement
    return vec3(binaryRefinement(screenRayPos, screenRayDir, sampledDepth, intersection), 1);
}

// A simple pseudo-random number generator function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Generate a random vec3
vec3 randomVec3(vec2 seed) {
    float x = random(seed);
    float y = random(seed + vec2(1.0, 0.0)); // Slightly different seed for Y
    float z = random(seed + vec2(0.0, 1.0)); // Slightly different seed for Z
    return vec3(x, y, z);
}


      
#endif //SSR_GLSL
