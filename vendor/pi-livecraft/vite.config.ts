import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const backendPort = process.env.PI_LIVECRAFT_BACKEND_PORT ?? '43121'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    // Tailnet hostname proxies here via `tailscale serve`; Vite otherwise
    // rejects requests whose Host header is not localhost.
    allowedHosts: ['haruka.tailac5b0.ts.net'],
    proxy: {
      '/api': `http://127.0.0.1:${backendPort}`,
    },
  },
})
