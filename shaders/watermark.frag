#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec4 uColor;
uniform float uTransparency;
uniform sampler2D uImage;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec4 texColor = texture(uImage, uv);

    // Basic blending demo: overlaying the uColor on the entire image
    // based on transparency.
    // Real implementation would pass a pattern/mask or text coordinates.
    // For now, this demonstrates GPU-powered color grading/overlay.
    
    vec3 mixed = mix(texColor.rgb, uColor.rgb, (1.0 - uTransparency) * uColor.a * 0.5);
    fragColor = vec4(mixed, texColor.a);
}
