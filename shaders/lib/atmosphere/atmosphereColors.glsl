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

vec3 godrayRGB(vec3 color)
{
    color.r = GODRAY_R;
    color.b = GODRAY_B;
    color.g = GODRAY_G;
    return color;
}

vec3 sunRGB(vec3 color)
{
    color.r = SUN_R;
    color.b = SUN_B;
    color.g = SUN_G;
    return color;
}

vec3 moonRGB(vec3 color)
{
    color.r = MOON_R;
    color.b = MOON_B;
    color.g = MOON_G;
    return color;
}
#endif