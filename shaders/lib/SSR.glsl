#ifndef SSR_GLSL
#define SSR_GLSL

//taken fromn Blemu's training raytracer found at https://gist.github.com/BelmuTM/af0fe99ee5aab386b149a53775fe94a3
#define BINARY_REFINEMENT 1 //[0 1]
#define BINARY_COUNT 4 //[2 4 6 8 10 12 14 16 18 20 22 24 28 32 36 40]
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



void binarySearch(inout vec3 rayPosition, vec3 rayDirection) {
  for (int i = 0; i < BINARY_COUNT; i++) {
    rayPosition +=
      sign(
        texelFetch(
          depthtex0,
          ivec2(rayPosition.xy * vec2(viewWidth, viewHeight)),
          0
        ).r -
          rayPosition.z
      ) *
      rayDirection;
    // Going back and forth using the delta of the 2 different depths as a parameter for sign()
    rayDirection *= BINARY_DECREASE;
    // Decreasing the step length (to slowly tend towards the intersection)
  }
}

// The favorite raytracer of your favorite raytracer
bool raytrace(
  vec3 viewPosition,
  vec3 rayDirection,
  int stepCount,
  float smoothLightmap,
  float dither,
  out vec3 rayPosition
) {
if (rayDirection.z > 0.0 && rayDirection.z >= -viewPosition.z) {
    return false;
  }

  rayPosition = viewToScreen(viewPosition);

  rayDirection = viewToScreen(viewPosition + rayDirection) - rayPosition;

  rayDirection = normalize(rayDirection);
  
  rayDirection *=
    minOf(
      abs(sign(rayDirection) - rayPosition) / max(abs(rayDirection), 0.00001)
    ) *
    (1.0 / stepCount);

 float depthLenience = max(
    abs(rayDirection.z) * 1.0,
    0.02 / (viewPosition.z * viewPosition.z)
  );
 
  bool intersect = false;
 
  vec2 texelSize = 1.0 /resolution;
  rayPosition += rayDirection * dither;
  
 const float THICKNESS = 0.01;
      float viewThickness = max(THICKNESS * (1.0 + abs(rayDirection.z) * 5.0), 1e-4);
  vec3 prevRayPosition;
  
  for (int i = 0; i < stepCount; i++) {
  
    prevRayPosition = rayPosition;
    rayPosition += rayDirection;
    
    if (clamp(rayPosition, 0, 1) != rayPosition) return false;

    float depth = texelFetch(
      depthtex0,
      ivec2(rayPosition.xy * resolution),
      0
    ).r;
  
    float initialDepth = texelFetch(
      depthtex0,
      ivec2(prevRayPosition.xy * resolution),
      0
    ).r;
    

    if (
      rayPosition.z > depth &&
      abs(depthLenience - (rayPosition.z - depth)) < depthLenience &&
      rayPosition.z > handDepth &&
      depth < 1.0 
    ) {
      intersect = true;
    } 
    else {
      intersect = false;
    }

    if(smoothLightmap < 13.5 / 15.0)
    {
       if (
      rayPosition.z > depth &&
      abs(depthLenience - (rayPosition.z - depth)) < depthLenience &&
      rayPosition.z > handDepth  
    ) {
      intersect = true;
    } 
    else {
      intersect = false;
    }
    }

    if (intersect) {
      break;
    }
    
  }

  
   #if BINARY_REFINEMENT == 1
  binarySearch(rayPosition, rayDirection);
  #endif


  return intersect;

}


// Binary refinement to improve sampled quality by stepping back and forth until it is closer to the actual result
vec2 binaryRefinement(in vec3 screenRayPos, in vec3 screenRayDir, in float sampledDepth, in bool intersection){
    // Reuse stored sampled depth and intersection to use 1 less depth sample
    for(uint i = 1u; i <= uint(BINARY_COUNT); i++){
        // Refine ray direction
        screenRayDir *= 0.5;
        screenRayPos += intersection ? -screenRayDir : screenRayDir;

        // Return early if we're on the last iteration
        if(i == uint(BINARY_COUNT)) return screenRayPos.xy;

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


#endif //SSR_GLSL