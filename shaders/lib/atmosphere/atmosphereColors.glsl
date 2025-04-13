#ifndef ATMOSPHERE_COLORS
#define ATMOSPHERE_COLORS

vec3 getDawnColor(vec3 color)
{
    color = vec3(1.0, 0.2353, 0.0627);
    return color;
}

vec3 getDayColor(vec3 color)
{
    color = vec3(1.0, 0.6039, 0.2784);
    return color;
}

vec3 getDuskColor(vec3 color)
{
    color = vec3(1.0, 0.0667, 0.0);
    return color;
}

vec3 getNightColor(vec3 color)
{
    color = vec3(0.1608, 0.2941, 0.9608);
    return color;
}

vec3 getRainColor(vec3 color)
{
    color = vec3(0.5882, 0.5882, 0.5882);
    return color;
}

vec3 getWaterTint(vec3 color)
{
   color = vec3(0.0, 1.0, 0.851);
    return color;
}

#endif