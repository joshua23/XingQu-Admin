import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import { resolve } from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  
  // 开发服务器配置
  server: {
    port: 3000,
    host: true,
    cors: true,
    strictPort: false,
    open: false,
    headers: {
      // 允许被飞书嵌入
      'X-Frame-Options': 'ALLOWALL',
      'Content-Security-Policy': 
        "frame-ancestors 'self' https://*.feishu.cn https://*.larksuite.com https://*.bytedance.feishu.cn"
    }
  },
  
  // 构建配置
  build: {
    outDir: 'dist',
    sourcemap: true,
    // 优化构建
    rollupOptions: {
      output: {
        manualChunks: {
          // 将React相关库分离到单独chunk
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
          // 将图表库分离
          'charts': ['recharts'],
          // 将UI图标库分离
          'icons': ['lucide-react'],
          // 将表单相关库分离
          'forms': ['react-hook-form', '@hookform/resolvers', 'zod']
        }
      }
    },
    // 设置chunk大小警告限制
    chunkSizeWarningLimit: 1000
  },
  
  // 路径解析
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@shared': resolve(__dirname, 'shared/src'),
      '@components': resolve(__dirname, 'components')
    }
  },
  
  // 环境变量
  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
    'process.env.VITE_SUPABASE_URL': JSON.stringify(process.env.VITE_SUPABASE_URL),
    'process.env.VITE_SUPABASE_ANON_KEY': JSON.stringify(process.env.VITE_SUPABASE_ANON_KEY)
  },
  
  // 优化配置
  optimizeDeps: {
    include: [
      'react', 
      'react-dom', 
      'react-router-dom',
      'swr',
      'lucide-react',
      'recharts', 
      'date-fns',
      'react-hook-form',
      '@hookform/resolvers',
      'zod'
    ]
  },
  
  // CSS配置
  css: {
    postcss: './postcss.config.js'
  }
})