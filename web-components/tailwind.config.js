/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
    "./components/*/src/**/*.{js,ts,jsx,tsx}",
    "./shared/src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // 背景色系
        bg: {
          primary: 'rgb(255, 255, 255)',      // 主背景 #ffffff
          secondary: 'rgb(247, 248, 250)',    // 次要背景 #f7f8fa
          tertiary: 'rgb(241, 243, 244)',     // 第三层背景 #f1f3f4
          hover: 'rgb(247, 248, 250)',        // 悬停背景 #f7f8fa
        },
        
        // 文本色系  
        text: {
          primary: 'rgb(31, 35, 41)',         // 主文本 #1f2329
          secondary: 'rgb(100, 106, 115)',    // 次要文本 #646a73
          tertiary: 'rgb(139, 148, 159)',     // 第三层文本 #8b949f
        },
        
        // 边框色系
        border: {
          primary: 'rgb(227, 230, 234)',      // 主边框 #e3e6ea
          secondary: 'rgb(208, 215, 222)',    // 次要边框 #d0d7de
          focus: 'rgb(0, 185, 107)',          // 焦点边框 #00b96b
        },
        
        // 主题色系
        accent: {
          primary: 'rgb(0, 185, 107)',        // 主色调 #00b96b
          hover: 'rgb(0, 169, 96)',           // 悬停色 #00a960
          light: 'rgb(232, 245, 240)',        // 浅色背景 #e8f5f0
          background: 'rgb(240, 249, 255)',   // 背景色 #f0f9ff
        },
        
        // 状态色系
        status: {
          success: 'rgb(0, 185, 107)',        // 成功色 #00b96b
          warning: 'rgb(255, 136, 0)',        // 警告色 #ff8800
          error: 'rgb(245, 34, 45)',          // 错误色 #f5222d
          info: 'rgb(22, 119, 255)',          // 信息色 #1677ff
        }
      },
      
      // 阴影系统
      boxShadow: {
        card: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
        hover: '0 4px 12px 0 rgba(0, 0, 0, 0.15)',
        focus: '0 0 0 3px rgba(0, 185, 107, 0.1)',
      },
      
      // 圆角系统
      borderRadius: {
        sm: '6px',
        md: '8px', 
        lg: '12px',
      },
      
      // 动画系统
      animation: {
        'fade-in': 'fadeIn 0.2s ease-in-out',
        'slide-in': 'slideIn 0.3s ease-out',
        'spin-slow': 'spin 3s linear infinite',
      },
      
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideIn: {
          '0%': { transform: 'translateY(-10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}