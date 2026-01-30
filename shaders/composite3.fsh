
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;
uniform float sunAngle;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

/* RENDERTARGETS: 0,6 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outGodRays;

vec3 distortShadowClipPos(vec3 shadowClipPos) {
    float distortionFactor = length(shadowClipPos.xy);
    distortionFactor += 0.1;
    shadowClipPos.xy /= distortionFactor;
    shadowClipPos.z *= 0.5;
    return shadowClipPos;
}

void main() {
    vec4 color = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).r;

    vec3 godRays = vec3(0.0);

    #ifdef GOD_RAYS

        float dayFactor = smoothstep(-0.05,0.1,sunAngle);

        if (dayFactor > 0.01) {
            vec4 sunClipPos = gbufferProjection * gbufferModelView * vec4(sunPosition, 0.0);
            vec2 sunScreenPos = (sunClipPos.xy / sunClipPos.w) * 0.5 + 0.5;

            vec2 rayDir = sunScreenPos - texcoord;
            float rayLength = length(rayDir);
            rayDir /= rayLength;

            rayLength = min(rayLength, 0.5);

            float stepSize = rayLength / float(GOD_RAYS_QUALITY);
            float accumLight = 0.0;

            for (int i = 0; i < GOD_RAYS_QUALITY; i++) {
                vec2 samplePos = texcoord + rayDir * stepSize * float(i);

                if (samplePos.x < 0.0 || samplePos.x > 1.0 || samplePos.y < 0.0 || samplePos.y > 1.0) {
                    continue;
                }
                
                float sampleDepth = texture(depthtex0, samplePos).r;
                
                if (sampleDepth >= 1.0) {
                    float falloff = 1.0 - float(i) / float(GOD_RAYS_QUALITY);
                    accumLight += falloff * falloff;
                }
            }

            accumLight /= float(GOD_RAYS_QUALITY);

            float sunsetFactor = smoothstep(0.0, 0.3, sunAngle) * smoothstep(0.5, 0.2, sunAngle);
            vec3 rayColor = mix(sunlightColor, skyColorSunset, sunsetFactor * 0.5);

            float sunFalloff = 1.0 - smoothstep(0.0, 0.7, rayLength);
            
            godRays = rayColor * accumLight * sunFalloff * GOD_RAYS_DENSITY * dayFactor;
        }
    
    #endif

    outColor = color;
    outGodRays = vec4(godRays, 1.0);
}