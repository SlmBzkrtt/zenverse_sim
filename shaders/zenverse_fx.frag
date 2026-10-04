#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uYaw;
uniform float uPitch;
uniform float uAtmosphere;
uniform float uWorldId;
uniform float uMode;

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / max(uSize, vec2(1.0));
  vec2 centered = uv - 0.5;
  float aspect = uSize.x / max(uSize.y, 1.0);
  centered.x *= aspect;

  // Horizon shift from pitch (-38..38 degrees)
  float horizonY = 0.52 + (uPitch / 90.0) * 0.35;
  float yawRad = uYaw * 0.0174532925;

  vec3 col = vec3(0.0);
  float alpha = 0.0;

  // 1. Volumetric God-Rays / Sunburst / Moonbeam from sky
  vec2 lightPos = vec2(0.5 + sin(yawRad) * 0.28, clamp(horizonY - 0.26, 0.08, 0.55));
  vec2 toLight = uv - lightPos;
  toLight.x *= aspect;
  float distLight = length(toLight);
  float angle = atan(toLight.y, toLight.x);

  float rayPattern = sin(angle * 14.0 + uTime * 0.55 + yawRad * 2.0) * 0.5 + 0.5;
  rayPattern *= sin(angle * 7.0 - uTime * 0.35) * 0.5 + 0.5;
  float rayMask = smoothstep(0.95, 0.0, distLight) * smoothstep(horizonY + 0.18, horizonY - 0.35, uv.y);

  vec3 rayColor = vec3(1.0, 0.92, 0.72);
  if (uAtmosphere > 0.5 && uAtmosphere < 1.5) {
    // Sunset golden-magenta rays
    rayColor = vec3(1.0, 0.58, 0.36);
  } else if (uAtmosphere >= 1.5 && uAtmosphere < 2.5) {
    // Night moonlit cyan-indigo glow
    rayColor = vec3(0.42, 0.68, 1.0);
  } else if (uWorldId > 4.5) {
    // Cologne Christmas warm cathedral gold
    rayColor = vec3(1.0, 0.80, 0.45);
  }

  float godRayStrength = rayPattern * rayMask * (uMode > 1.5 ? 0.22 : 0.16);
  col += rayColor * godRayStrength;
  alpha += godRayStrength * 0.85;

  // 2. Lower-half Water / Ground Caustics & Heat Shimmer
  if (uv.y > horizonY - 0.02) {
    float depth = clamp((uv.y - horizonY) / max(1.0 - horizonY, 0.001), 0.0, 1.0);
    float waveX = (uv.x + yawRad * 0.3) * 28.0 / max(depth + 0.25, 0.25);
    float waveY = depth * 36.0 - uTime * 1.8;
    float caustic1 = sin(waveX + sin(waveY * 0.7 + uTime)) * cos(waveY - cos(waveX * 0.5));
    float caustic2 = sin(waveX * 1.7 - uTime * 1.3) * sin(waveY * 1.4 + uTime * 0.9);
    float shimmer = pow( clamp((caustic1 + caustic2) * 0.5 + 0.5, 0.0, 1.0), 3.0 );

    vec3 shimmerCol = mix(rayColor, vec3(0.55, 0.92, 1.0), 0.45);
    if (uWorldId > 0.5 && uWorldId < 1.5) {
      // Desert heat mirage tint
      shimmerCol = vec3(1.0, 0.82, 0.55);
    } else if (uWorldId > 4.5) {
      // Rhine river golden reflection
      shimmerCol = vec3(1.0, 0.78, 0.38);
    }

    float shimmerAlpha = shimmer * (1.0 - depth * 0.65) * 0.14;
    col += shimmerCol * shimmerAlpha;
    alpha += shimmerAlpha;
  }

  // 3. Mode 2: Aurora / Dreamy Bokeh Ribbon in Sky
  if (uMode > 1.5 && uMode < 2.5 && uv.y < horizonY + 0.05) {
    float skyY = clamp(uv.y / max(horizonY, 0.01), 0.0, 1.0);
    float ribbon = sin(uv.x * 8.0 + yawRad * 1.5 + sin(uTime * 0.6 + skyY * 4.0) * 1.5);
    float auroraBand = smoothstep(0.65, 1.0, ribbon) * (1.0 - skyY) * smoothstep(0.0, 0.25, skyY);
    vec3 auroraCol = mix(vec3(0.20, 0.95, 0.72), vec3(0.68, 0.40, 1.0), sin(uTime * 0.4 + uv.x * 3.0) * 0.5 + 0.5);
    float auroraAlpha = auroraBand * 0.20;
    col += auroraCol * auroraAlpha;
    alpha += auroraAlpha;
  }

  // 4. Mode 3 or Rain/Storm Atmosphere: Glass Raindrop Refraction & Cozy Warmth
  if (uMode > 2.5 || (uAtmosphere > 2.5 && uAtmosphere < 3.5) || uAtmosphere > 4.5) {
    vec2 gridUV = uv * vec2(aspect * 12.0, 12.0);
    gridUV.y += uTime * 1.15;
    vec2 cell = floor(gridUV);
    vec2 local = fract(gridUV) - 0.5;
    float rnd = hash21(cell);
    vec2 dropOffset = vec2(sin(uTime * 2.0 + rnd * 6.28) * 0.18, cos(uTime * 1.5 + rnd * 6.28) * 0.18);
    float dropDist = length(local - dropOffset);
    float dropHighlight = smoothstep(0.16, 0.02, dropDist) * step(0.55, rnd);
    vec3 dropCol = mix(vec3(0.75, 0.90, 1.0), rayColor, 0.35);
    col += dropCol * (dropHighlight * 0.18);
    alpha += dropHighlight * 0.16;
  }

  // 5. Subtle Cinematic Lens Vignette & Chromatic Edge Glow
  float radial = length(centered / vec2(aspect * 0.65, 0.65));
  float vignette = smoothstep(0.58, 1.25, radial);
  vec3 vignetteTint = (uAtmosphere >= 1.5 && uAtmosphere < 2.5)
      ? vec3(0.02, 0.05, 0.14)
      : vec3(0.04, 0.02, 0.08);
  float vigAlpha = vignette * 0.22;
  col = mix(col, vignetteTint * vigAlpha, vigAlpha);
  alpha = clamp(alpha + vigAlpha * 0.65, 0.0, 0.55);

  // Premultiplied alpha output
  fragColor = vec4(col, alpha);
}
