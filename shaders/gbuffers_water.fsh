
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 normal;
in vec3 viewPos;
in vec3 worldPos;
in float isWater;

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float alphaTestRef;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 skyColor;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float sunAngle;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
    vec4 color = texture(gtexture, texcoord) * glcolor;
    vec3 normalOut = normalize(normal);

    vec3 lightmapColor = texture(lightmap, lmcoord).rgb;

    if (isWater > 0.5) {
        vec3 waterBaseColor = vec3(0.05, 0.15, 0.3);
    
        waterBaseColor = mix(waterBaseColor, glcolor.rgb * 0.5, 0.4);
        
        vec3 viewDir = normalize(-viewPos);
        vec3 worldViewDir = mat3(gbufferModelViewInverse) * viewDir;
        
        float NdotV = max(dot(normalOut, worldViewDir), 0.0);
        float fresnel = pow(1.0 - NdotV, 4.0);
        fresnel = mix(0.02, 0.8, fresnel);
        
        vec3 reflectDir = reflect(-worldViewDir, normalOut);
        
        float skyGradient = reflectDir.y * 0.5 + 0.5;
        float dayFactor = smoothstep(-0.1, 0.2, sunAngle);
        
        vec3 skyReflectColor = mix(
            vec3(0.02, 0.03, 0.05),
            mix(vec3(0.5, 0.6, 0.7), vec3(0.3, 0.5, 0.9), skyGradient),
            dayFactor
        );
        
        vec3 sunDir = normalize((gbufferModelViewInverse * vec4(sunPosition, 0.0)).xyz);
        float sunSpec = pow(max(dot(reflectDir, sunDir), 0.0), 256.0);
        vec3 sunColor = mix(vec3(0.3, 0.4, 0.5), vec3(1.0, 0.95, 0.8), dayFactor);
        skyReflectColor += sunColor * sunSpec * 2.0 * dayFactor;
        
        vec3 waterColor = mix(waterBaseColor, skyReflectColor, fresnel);
        
        waterColor *= mix(vec3(0.3), vec3(1.0), lmcoord.y);
        
        float alpha = mix(0.5, 0.85, fresnel);
        
        color = vec4(waterColor, alpha);
    } else {
        if (color.a < alphaTestRef) {
            discard;
        }

        color.rgb *= lightmapColor;
    }
    
    outColor = color;
}