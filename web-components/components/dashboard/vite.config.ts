import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import { resolve } from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  
  // 开发服务器配置
  server: {
    port: 3001,
    cors: true,
    headers: {
      // 允许被飞书嵌入
      'X-Frame-Options': 'ALLOWALL',
      'Content-Security-Policy': 
        "frame-ancestors 'self' https://*.feishu.cn https://*.larksuite.com https://*.bytedance.feishu.cn"
    }
  },
  
  // 构建配置
  build: {
    lib: {
      entry: resolve(__dirname, 'src/main.tsx'),
      name: 'DashboardComponent',
      fileName: 'dashboard-component',
      formats: ['es', 'umd']
    },
    rollupOptions: {
      // 确保外部化依赖
      external: ['react', 'react-dom'],
      output: {
        globals: {
          react: 'React',
          'react-dom': 'ReactDOM'
        }
      }
    },
    // 生成sourcemap用于调试
    sourcemap: true,
    // 输出目录
    outDir: 'dist'
  },
  
  // 路径解析
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@shared': resolve(__dirname, '../../shared/src')
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
    include: ['react', 'react-dom', 'recharts', 'date-fns']
  }
})