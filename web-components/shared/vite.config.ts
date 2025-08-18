import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import { resolve } from 'path'
import dts from 'vite-plugin-dts'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react(),
    dts({
      insertTypesEntry: true,
    })
  ],
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: '@xingqu/shared',
      formats: ['es', 'umd'],
      fileName: (format) => `xingqu-shared.${format}.js`
    },
    rollupOptions: {
      external: [
        'react',
        'react-dom',
        'react-router-dom',
        'lucide-react',
        'recharts',
        'swr',
        'date-fns',
        'react-hook-form',
        '@hookform/resolvers',
        'zod',
        '@supabase/supabase-js'
      ],
      output: {
        globals: {
          react: 'React',
          'react-dom': 'ReactDOM',
          'react-router-dom': 'ReactRouterDOM',
          'lucide-react': 'LucideReact',
          recharts: 'Recharts',
          swr: 'SWR',
          'date-fns': 'dateFns',
          'react-hook-form': 'ReactHookForm',
          '@hookform/resolvers': 'HookFormResolvers',
          zod: 'Zod',
          '@supabase/supabase-js': 'Supabase'
        }
      }
    },
    sourcemap: true
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src')
    }
  }
})