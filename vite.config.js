import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        admin: resolve(__dirname, 'admin.html'),
        auth: resolve(__dirname, 'auth.html'),
        community: resolve(__dirname, 'community.html'),
        faults: resolve(__dirname, 'faults.html'),
        notices: resolve(__dirname, 'notices.html'),
        profile: resolve(__dirname, 'profile.html'),
      },
    },
  },
});
