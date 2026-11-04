// Island module: z.js calls this with the element and its data-props. Returns a cleanup function.
import * as THREE from 'three';

export default function mount(el, { speed = 1 }) {
  const accent = getComputedStyle(el).getPropertyValue('--accent').trim() || '#007aff';
  const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  el.append(renderer.domElement);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(40, 1, 0.1, 100);
  camera.position.set(0, 0, 6);
  scene.add(new THREE.HemisphereLight(0xffffff, 0x444466, 1.6));
  const key = new THREE.DirectionalLight(0xffffff, 2);
  key.position.set(3, 4, 5);
  scene.add(key);

  const mesh = new THREE.Mesh(
    new THREE.IcosahedronGeometry(1.4, 0),
    new THREE.MeshStandardMaterial({ color: accent, flatShading: true, roughness: 0.35, metalness: 0.1 }),
  );
  scene.add(mesh);

  const resize = () => {
    const { width, height } = el.getBoundingClientRect();
    renderer.setSize(width, height, false);
    camera.aspect = width / height;
    camera.updateProjectionMatrix();
  };
  const observer = new ResizeObserver(resize);
  observer.observe(el);
  resize();

  const still = matchMedia('(prefers-reduced-motion: reduce)').matches;
  renderer.setAnimationLoop((t) => {
    if (!still) mesh.rotation.set(t * 0.0004 * speed, t * 0.0006 * speed, 0);
    renderer.render(scene, camera);
  });

  return () => {
    renderer.setAnimationLoop(null);
    observer.disconnect();
    mesh.geometry.dispose();
    mesh.material.dispose();
    renderer.dispose();
    renderer.domElement.remove();
  };
}
