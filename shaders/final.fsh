
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;  // Main color
uniform sampler2D colortex4;  // Bloom
uniform sampler2D colortex6;  // God rays
uniform sampler2D depthtex0;  // Depth
uniform sampler2D noisetex;

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float centerDepthSmooth;
uniform float near;
uniform float far;

uniform int isEyeInWater;
uniform int dimensionId;

#ifdef NETHER_HEAT_DISTORTION
vec2 getHeatDistortion(vec2 uv, float time) {
    float distortionX = sin(uv.y * 20.0 + time * 3.0) * 0.002;
    float distortionY = sin(uv.x * 15.0 + time * 2.5) * 0.001;
    
    distortionX += sin(uv.y * 40.0 + time * 5.0) * 0.001;
    distortionY += cos(uv.x * 30.0 + time * 4.0) * 0.0005;
    
    return vec2(distortionX, distortionY);
}
#endif

#ifdef DOF_ENABLED
vec3 getDoF(sampler2D colorTex, sampler2D depthTex, vec2 uv, vec2 texelSize) {
    float depth = texture(depthTex, uv).r;
    float centerDepth = centerDepthSmooth;
    float linearDepth = linearizeDepth(depth, near, far);
    float linearCenterDepth = linearizeDepth(centerDepth, near, far);
    
    float coc = abs(linearDepth - linearCenterDepth) / linearCenterDepth;
    coc = clamp(coc * DOF_STRENGTH * 10.0, 0.0, 1.0);
    
    if (coc < 0.01) {
        return texture(colorTex, uv).rgb;
    }
    
    vec3 colorSum = vec3(0.0);
    float weightSum = 0.0;
    
    const int samples = 16;
    float radius = coc * DOF_APERTURE * 100.0;
    
    for (int i = 0; i < samples; i++) {
        float angle = float(i) * GOLDEN_RATIO * TAU;
        float r = sqrt(float(i) + 0.5) / sqrt(float(samples));
        
        vec2 offset = vec2(cos(angle), sin(angle)) * r * radius * texelSize;
        vec3 sampleColor = texture(colorTex, uv + offset).rgb;
        
        float weight = 1.0 + getLuminance(sampleColor) * 2.0;
        colorSum += sampleColor * weight;
        weightSum += weight;
    }
    
    return colorSum / weightSum;
}
#endif

#ifdef CHROMATIC_ABERRATION
vec3 chromaticAberration(sampler2D tex, vec2 uv) {
    vec2 direction = uv - 0.5;
    float distFromCenter = length(direction);
    
    float aberrationAmount = distFromCenter * CHROMATIC_ABERRATION_STRENGTH;
    
    float r = texture(tex, uv + direction * aberrationAmount).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv - direction * aberrationAmount).b;
    
    return vec3(r, g, b);
}
#endif

float getVignette(vec2 uv) {
    #ifdef VIGNETTE_ENABLED
        vec2 center = uv - 0.5;
        float dist = length(center);
        float vignette = 1.0 - dist * dist * VIGNETTE_STRENGTH * 2.0;
        return clamp(vignette, 0.0, 1.0);
    #else
        return 1.0;
    #endif
}

#ifdef FILM_GRAIN
float getFilmGrain(vec2 uv, float time) {
    vec2 noise = hash22(uv * 1000.0 + time * 100.0);
    return (noise.x + noise.y) * 0.5 - 0.5;
}
#endif

void main() {
    vec2 texelSize = 1.0 / vec2(viewWidth, viewHeight);
    vec2 uv = texcoord;
    vec3 color;

    #ifdef NETHER_HEAT_DISTORTION
        if (dimensionId == -1) {
            uv += getHeatDistortion(texcoord, frameTimeCounter);
        }
    #endif

    #ifdef DOF_ENABLED
        color = getDoF(colortex0, depthtex0, uv, texelSize);
    #else
        color = texture(colortex0, uv).rgb;
    #endif

    #ifdef CHROMATIC_ABERRATION
        color = chromaticAberration(colortex0, uv);
    #endif
    
    #ifdef BLOOM_ENABLED
        vec3 bloom = texture(colortex4, uv).rgb;
        color += bloom * BLOOM_STRENGTH;
    #endif

    #ifdef GOD_RAYS
        vec3 godRays = texture(colortex6, uv).rgb;
        color += godRays * 0.5;
    #endif

    color *= EXPOSURE;

    #if TONEMAPPER == 0
        color = saturate(color);
    #elif TONEMAPPER == 1
        color = tonemapReinhard(color);
    #elif TONEMAPPER == 2
        color = tonemapACES(color);
    #elif TONEMAPPER == 3
        color = tonemapUncharted2(color);
    #endif

    color = adjustSaturation(color, SATURATION);
    color = adjustContrast(color, CONTRAST);
    color = pow(color, vec3(1.0 / GAMMA));

    color = linearToSRGB(color);

    float vignette = getVignette(uv);
    color *= vignette;
    
    #ifdef FILM_GRAIN
        float grain = getFilmGrain(uv, frameTimeCounter);
        color += grain * FILM_GRAIN_STRENGTH;
    #endif

    if (isEyeInWater == 1) {
        color *= vec3(0.6, 0.8, 1.0);
        
        vec2 distortion = vec2(
            sin(texcoord.y * 20.0 + frameTimeCounter * 2.0) * 0.002,
            cos(texcoord.x * 20.0 + frameTimeCounter * 2.0) * 0.002
        );
        color = texture(colortex0, texcoord + distortion).rgb;
        color *= vec3(0.6, 0.8, 1.0);
    }

    if (dimensionId == -1) {
        color.r *= 1.15;
        color.g *= 0.95;
        color.b *= 0.75;
        
        vec2 center = texcoord - 0.5;
        float dist = length(center);
        vec3 netherVignette = mix(vec3(1.0), vec3(0.8, 0.3, 0.1), dist * dist * 0.8);
        color *= netherVignette;
        
        color = adjustContrast(color, 1.1);
        
        float flicker = sin(frameTimeCounter * 8.0) * 0.02 + sin(frameTimeCounter * 13.0) * 0.01;
        color *= 1.0 + flicker;
    }

    if (dimensionId == 1) {
        color.r *= 0.9;
        color.g *= 0.85;
        color.b *= 1.1;
        
        vec2 center = texcoord - 0.5;
        float dist = length(center);
        color *= 1.0 - dist * dist * 0.5;
    }

    color = saturate(color);

    float dither = bayer8(gl_FragCoord.xy) / 255.0;
    color += dither;

    gl_FragColor = vec4(color, 1.0); 
}