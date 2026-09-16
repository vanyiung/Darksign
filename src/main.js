import './style.css';
import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import vertexShader from './shaders/fullscreen.vert.glsl?raw';
import fragmentShader from './shaders/ring.frag.glsl?raw';
import emberVertex from './shaders/embers.vert.glsl?raw';
import emberFragment from './shaders/embers.frag.glsl?raw';
import consumeFragment from './shaders/consume.frag.glsl?raw';

const host = document.querySelector('#scene');
const enter = document.querySelector('#enter');
const hint = document.querySelector('#hint');

try {
  init();
} catch (error) {
  console.error(error);
  document.querySelector('#error').hidden = false;
  enter.disabled = true;
}

function init() {
  const renderer = new THREE.WebGLRenderer({ antialias: false, powerPreference: 'high-performance' });
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.1;
  host.appendChild(renderer.domElement);
  const scene = new THREE.Scene();
  const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  const uniforms = {
    uResolution: { value: new THREE.Vector2() },
    uPointer: { value: new THREE.Vector2(10, 10) },
    uTime: { value: 0 }, uCollapse: { value: 0 }, uPresence: { value: 0 },
  };
  const ringMaterial = new THREE.ShaderMaterial({ vertexShader, fragmentShader, uniforms, depthTest: false, depthWrite: false });
  const ring = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), ringMaterial);
  ring.frustumCulled = false;
  scene.add(ring);

  const geometry = new THREE.BufferGeometry();
  const count = 240;
  const positions = new Float32Array(count * 3);
  const seeds = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    positions[i * 3] = Math.random() * Math.PI * 2;
    positions[i * 3 + 2] = Math.random();
    seeds[i] = Math.random();
  }
  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geometry.setAttribute('aSeed', new THREE.BufferAttribute(seeds, 1));
  const emberUniforms = {
    uTime: uniforms.uTime, uCollapse: uniforms.uCollapse,
    uPixelRatio: { value: 1 }, uAspect: { value: 1 },
  };
  const emberMaterial = new THREE.ShaderMaterial({
    vertexShader: emberVertex, fragmentShader: emberFragment, uniforms: emberUniforms,
    transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, depthTest: false,
  });
  const embers = new THREE.Points(geometry, emberMaterial);
  embers.frustumCulled = false;
  embers.renderOrder = 1;
  const particleScene = new THREE.Scene();
  particleScene.add(embers);

  // Half-float render targets preserve values above 1.0 for HDR bloom.
  const target = new THREE.WebGLRenderTarget(1, 1, { type: THREE.HalfFloatType });
  const composer = new EffectComposer(renderer, target);
  composer.addPass(new RenderPass(scene, camera));
  const bloom = new UnrealBloomPass(new THREE.Vector2(1, 1), 0.55, 0.2, 0.85);
  composer.addPass(bloom);
  const consume = new ShaderPass({
    uniforms: { tDiffuse: { value: null }, uDarkness: { value: 0 }, uCollapse: uniforms.uCollapse, uResolution: uniforms.uResolution },
    vertexShader, fragmentShader: consumeFragment,
  });
  // Shade the dark sphere after bloom, then overlay depth-occluded orbiting embers.
  composer.addPass(consume);
  emberUniforms.uDarkness = consume.uniforms.uDarkness;
  const particlePass = new RenderPass(particleScene, camera);
  particlePass.clear = false;
  composer.addPass(particlePass);
  composer.addPass(new OutputPass());
  // Fixed maximum preset: full particle count and up to 2x device pixel ratio.
  function resize() {
    const { width, height } = host.getBoundingClientRect();
    const dpr = Math.min(devicePixelRatio, 2);
    renderer.setPixelRatio(dpr);
    renderer.setSize(width, height);
    composer.setPixelRatio(dpr);
    composer.setSize(width, height);
    uniforms.uResolution.value.set(width, height);
    consume.uniforms.uResolution.value.set(width, height);
    emberUniforms.uPixelRatio.value = dpr;
    emberUniforms.uAspect.value = width / height;
    geometry.setDrawRange(0, count);
  }
  const observer = new ResizeObserver(resize);
  observer.observe(host);
  resize();
  const pointer = new THREE.Vector2(10, 10);
  let presence = 0;
  host.addEventListener('pointermove', (event) => {
    const rect = host.getBoundingClientRect();
    const size = Math.min(rect.width, rect.height);
    pointer.set((event.clientX - rect.left - rect.width / 2) / size, (rect.height / 2 - event.clientY + rect.top) / size - 0.02);
    presence = 1;
  });
  host.addEventListener('pointerleave', () => { presence = 0; });
  host.addEventListener('pointerup', (event) => { if (event.pointerType !== 'mouse') presence = 0; });
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const motionSpeed = reducedMotion ? 0.35 : 1.0;
  let transition = -1;
  function descend() {
    if (transition >= 0) return;
    transition = 0;
    enter.disabled = true;
    hint.textContent = '万物正在归于黑暗…';
  }
  host.addEventListener('click', descend);
  enter.addEventListener('click', descend);
  const smooth = (a, b, x) => { const v = THREE.MathUtils.clamp((x-a)/(b-a),0,1); return v*v*(3-2*v); };
  let previous = performance.now();
  let contextLost = false;
  renderer.domElement.addEventListener('webglcontextlost', (event) => {
    event.preventDefault(); contextLost = true;
    document.querySelector('#error').textContent = '图形上下文已中断，请刷新页面恢复。';
    document.querySelector('#error').hidden = false;
  });
  renderer.setAnimationLoop((now) => {
    const dt = Math.min((now - previous) / 1000, 0.05);
    previous = now;
    if (document.hidden || contextLost) return;
    uniforms.uTime.value += dt * motionSpeed;
    uniforms.uPointer.value.lerp(pointer, 1 - Math.exp(-dt * 10));
    uniforms.uPresence.value = THREE.MathUtils.damp(uniforms.uPresence.value, presence, 5, dt);
    if (transition >= 0) {
      transition += dt;
      uniforms.uCollapse.value = smooth(0, 1.15, transition) * (1-smooth(2.2,3.3,transition));
      consume.uniforms.uDarkness.value = smooth(0.6,1.65,transition) * (1-smooth(2.1,3.5,transition));
      if (transition > 3.5) {
        transition = -1;
        uniforms.uCollapse.value = 0;
        consume.uniforms.uDarkness.value = 0;
        enter.disabled = false;
        hint.textContent = '余火重燃 · 再次靠近';
      }
    }
    consume.uniforms.uCollapse.value = uniforms.uCollapse.value;
    composer.render();
  });
  if (import.meta.hot) import.meta.hot.dispose(() => {
    renderer.setAnimationLoop(null);
    observer.disconnect();
    ring.geometry.dispose(); ringMaterial.dispose();
    geometry.dispose(); emberMaterial.dispose();
    composer.passes.forEach((pass) => pass.dispose?.());
    composer.dispose(); renderer.dispose();
    renderer.domElement.remove();
  });
}





