import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: '/focusflow/',   // 👈 this is the key change
  server: {
    proxy: {
      '/api': 'http://localhost:4877',
    },
  },
})
