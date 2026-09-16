import { defineConfig } from 'vite';

// Relative assets support both a domain root and GitHub Pages repository paths.
export default defineConfig({ base: './', build: { chunkSizeWarningLimit: 650 } });
