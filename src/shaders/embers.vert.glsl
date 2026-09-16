uniform float uTime;
uniform float uCollapse;
uniform float uDarkness;
uniform float uPixelRatio;
uniform float uAspect;
attribute float aSeed;
varying float vAlpha;
void main() {
  float shrink = 1.0 - uCollapse * 0.92;
  float sphereRadius = 0.230 * shrink;
  float orbitalRadius = (0.253 + position.z * 0.085) * shrink;
  float angle = position.x + uTime * (0.12 + position.z * 0.10);
  float tilt = 0.65 + aSeed * 0.65;
  vec3 orbit = orbitalRadius * vec3(cos(angle), sin(angle)*cos(tilt), sin(angle)*sin(tilt));
  float orientation = aSeed * 2.4 - 1.2;
  vec2 projected = mat2(cos(orientation),sin(orientation),-sin(orientation),cos(orientation)) * orbit.xy;

  // Analytic sphere occlusion: back-orbit particles disappear behind the body.
  float projectedRadius = length(projected);
  float surfaceZ = sqrt(max(0.0,sphereRadius*sphereRadius-dot(projected,projected)));
  float visible = projectedRadius >= sphereRadius || orbit.z >= surfaceZ ? 1.0 : 0.0;
  float twinkle = 0.65 + 0.35 * sin(uTime * 0.7 + aSeed * 30.0);
  vAlpha = visible * twinkle * (1.0-uCollapse) * (0.25+position.z*0.45);
  float reach = length(vec2(max(uAspect,1.0),max(1.0/uAspect,1.0))) * 0.62;
  if (uDarkness > 0.0) {
    vAlpha *= smoothstep(uDarkness*reach-0.035,uDarkness*reach+0.035,projectedRadius);
  }
  vec2 p = projected + vec2(0.0,0.02);
  vec2 scale = vec2(min(1.0,1.0/uAspect),min(1.0,uAspect));
  gl_Position = vec4(p*2.0*scale,0.0,1.0);
  gl_PointSize = (1.8+position.z*2.2) * uPixelRatio;
}
