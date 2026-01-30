
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/atmosphere.glsl"

in vec3 viewDir;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float sunAngle;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormal;

void main() {
    vec3 viewDirNorm = normalize(viewDir);
    
    vec3 sunDir = normalize((gbufferModelViewInverse * vec4(sunPosition, 0.0)).xyz);
    
    vec3 sky = getSky(viewDirNorm, sunDir, sunAngle, frameTimeCounter, cameraPosition);
    
    sky *= EXPOSURE;
    
    outColor = vec4(sky, 1.0);
    outNormal = vec4(0.5, 0.5, 1.0, 1.0);
}