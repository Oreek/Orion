
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/shadow.glsl"

out vec2 texcoord;
out vec4 glcolor;
out vec3 worldPos;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    worldPos = (shadowModelViewInverse * viewPos).xyz + cameraPosition;
    
    gl_Position = ftransform();
    
    gl_Position.xyz = distortShadowClipPos(gl_Position.xyz);
}