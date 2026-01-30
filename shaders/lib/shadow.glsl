
#ifndef SHADOW_GLSL
#define SHADOW_GLSL

#include "/lib/settings.glsl"
#include "/lib/common.glsl"


// SHADOW DISTORTION

vec3 distortShadowClipPos(vec3 shadowClipPos) {
    float distortionFactor = length(shadowClipPos.xy);
    distortionFactor += 0.1;
    
    shadowClipPos.xy /= distortionFactor;
    shadowClipPos.z *= 0.5;
    
    return shadowClipPos;
}

vec3 undistortShadowClipPos(vec3 shadowClipPos) {
    shadowClipPos.z *= 2.0;
    float distortionFactor = length(shadowClipPos.xy);
    distortionFactor = 1.0 / (1.0 - distortionFactor);
    shadowClipPos.xy *= distortionFactor;
    
    return shadowClipPos;
}


// SHADOW SAMPLING

float getShadowSample(sampler2D shadowMap, vec3 shadowScreenPos) {
    return step(shadowScreenPos.z, texture(shadowMap, shadowScreenPos.xy).r);
}

vec3 getTransparentShadow(sampler2D shadowtex0, sampler2D shadowtex1, sampler2D shadowcolor0, vec3 shadowScreenPos) {
    float transparentShadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);

    if (transparentShadow >= 1.0) {
        return vec3(1.0);
    }

    float opaqueShadow = step(shadowScreenPos.z, texture(shadowtex1, shadowScreenPos.xy).r);

    if (opaqueShadow < 0.5) {
        return vec3(0.0);
    }

    vec4 shadowColor = texture(shadowcolor0, shadowScreenPos.xy);
    return shadowColor.rgb * (1.0 - shadowColor.a);
}

vec3 getPCFShadow(sampler2D shadowtex0, sampler2D shadowtex1, sampler2D shadowcolor0, 
    sampler2D noisetex, vec4 shadowClipPos, vec2 texcoord, 
    vec2 screenSize, mat4 shadowProjection) {
    
    ivec2 screenCoord = ivec2(texcoord * screenSize);
    ivec2 noiseCoord = screenCoord % 64;
    float noise = texelFetch(noisetex, noiseCoord, 0).r;
    
    float theta = noise * TAU;
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);
    mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
    
    vec3 shadowAccum = vec3(0.0);
    
    #if SHADOW_QUALITY == 1
        const int samples = 4;
        const float radius = 0.5;
    #elif SHADOW_QUALITY == 2
        const int samples = 8;
        const float radius = 1.0;
    #elif SHADOW_QUALITY == 3
        const int samples = 16;
        const float radius = 1.5;
    #else
        const int samples = 32;
        const float radius = 2.0;
    #endif

    for (int i = 0; i < samples; i++) {
        float angle = float(i) * GOLDEN_RATIO * TAU;
        float r = sqrt(float(i) + 0.5) / sqrt(float(samples));
        
        vec2 offset = vec2(cos(angle), sin(angle)) * r * radius * SHADOW_SOFTNESS;
        offset = rotation * offset;
        offset /= float(shadowMapResolution);
        
        vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0);
        offsetShadowClipPos.z -= SHADOW_BIAS;
        offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz);
        
        vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w;
        vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
        
        shadowAccum += getTransparentShadow(shadowtex0, shadowtex1, shadowcolor0, shadowScreenPos);
    }
    
    return shadowAccum / float(samples);
}

vec3 getPCSSShadow(sampler2D shadowtex0, sampler2D shadowtex1, sampler2D shadowcolor0, sampler2D noisetex, vec4 shadowClipPos, vec2 texcoord, vec2 screenSize, mat4 shadowProjection) {
    
    ivec2 screenCoord = ivec2(texcoord * screenSize);
    ivec2 noiseCoord = screenCoord % 64;
    float noise = texelFetch(noisetex, noiseCoord, 0).r;
    
    float theta = noise * TAU;
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);
    mat2 rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta);
    
    float blockerSum = 0.0;
    int blockerCount = 0;
    
    const int blockerSamples = 8;
    const float searchRadius = 3.0;
    
    for (int i = 0; i < blockerSamples; i++) {
        float angle = float(i) * GOLDEN_RATIO * TAU;
        float r = sqrt(float(i) + 0.5) / sqrt(float(blockerSamples));
        
        vec2 offset = vec2(cos(angle), sin(angle)) * r * searchRadius;
        offset = rotation * offset;
        offset /= float(shadowMapResolution);
        
        vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0);
        offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz);
        
        vec3 shadowNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w;
        vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
        
        float shadowDepth = texture(shadowtex0, shadowScreenPos.xy).r;
        
        if (shadowScreenPos.z > shadowDepth + SHADOW_BIAS) {
            blockerSum += shadowDepth;
            blockerCount++;
        }
    }
    
    if (blockerCount == 0) {
        return vec3(1.0);
    }
    
    float avgBlockerDepth = blockerSum / float(blockerCount);
    
    vec4 distortedShadowClipPos = shadowClipPos;
    distortedShadowClipPos.xyz = distortShadowClipPos(distortedShadowClipPos.xyz);
    vec3 shadowNDCPos = distortedShadowClipPos.xyz / distortedShadowClipPos.w;
    vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;
    
    float penumbraSize = (shadowScreenPos.z - avgBlockerDepth) / avgBlockerDepth;
    penumbraSize = clamp(penumbraSize * 32.0, 0.5, 4.0) * SHADOW_SOFTNESS;
    
    vec3 shadowAccum = vec3(0.0);
    
    #if SHADOW_QUALITY >= 3
        const int samples = 24;
    #else
        const int samples = 12;
    #endif
    
    for (int i = 0; i < samples; i++) {
        float angle = float(i) * GOLDEN_RATIO * TAU;
        float r = sqrt(float(i) + 0.5) / sqrt(float(samples));
        
        vec2 offset = vec2(cos(angle), sin(angle)) * r * penumbraSize;
        offset = rotation * offset;
        offset /= float(shadowMapResolution);
        
        vec4 offsetShadowClipPos = shadowClipPos + vec4(offset, 0.0, 0.0);
        offsetShadowClipPos.z -= SHADOW_BIAS;
        offsetShadowClipPos.xyz = distortShadowClipPos(offsetShadowClipPos.xyz);
        
        vec3 sampleNDCPos = offsetShadowClipPos.xyz / offsetShadowClipPos.w;
        vec3 sampleScreenPos = sampleNDCPos * 0.5 + 0.5;
        
        shadowAccum += getTransparentShadow(shadowtex0, shadowtex1, shadowcolor0, sampleScreenPos);
    }
    
    return shadowAccum / float(samples);
}

#endif