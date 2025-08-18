/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
    "../components/*/src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      // 飞书适配色彩系统
      colors: {
        // 背景色系
        bg: {
          primary: 'rgb(255, 255, 255)',
          secondary: 'rgb(247, 248, 250)', 
          tertiary: 'rgb(235, 238, 245)',
          elevated: 'rgb(255, 255, 255)',
          hover: 'rgb(242, 243, 245)'
        },
        
        // 文本色系
        text: {
          primary: 'rgb(31, 35, 41)',
          secondary: 'rgb(100, 106, 115)',
          tertiary: 'rgb(143, 149, 158)',
          disabled: 'rgb(201, 205, 212)',
          link: 'rgb(51, 112, 255)'
        },
        
        // 科技绿强调色系
        accent: {
          primary: 'rgb(0, 185, 107)',
          secondary: 'rgb(82, 196, 26)',
          hover: 'rgb(0, 154, 87)',
          pressed: 'rgb(0, 138, 74)',
          light: 'rgb(246, 255, 237)',
          background: 'rgba(0, 185, 107, 0.06)'
        },
        
        // 飞书状态色系
        status: {
          success: 'rgb(0, 185, 107)',
          warning: 'rgb(255, 136, 0)',
          error: 'rgb(245, 34, 45)',
          info: 'rgb(24, 144, 255)',
          processing: 'rgb(114, 46, 209)'
        },
        
        // 边界和分割
        border: {
          primary: 'rgb(229, 230, 235)',
          secondary: 'rgb(235, 238, 245)',
          focus: 'rgb(51, 112, 255)',
          accent: 'rgb(0, 185, 107)'
        }
      },
      
      // 字体系统
      fontFamily: {
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace']
      },
      
      // 字体大小
      fontSize: {
        'xs': ['0.75rem', { lineHeight: '1.5' }],
        'sm': ['0.875rem', { lineHeight: '1.5' }],
        'base': ['1rem', { lineHeight: '1.5' }],
        'lg': ['1.125rem', { lineHeight: '1.5' }],
        'xl': ['1.25rem', { lineHeight: '1.4' }],
        '2xl': ['1.5rem', { lineHeight: '1.3' }],
        '3xl': ['1.875rem', { lineHeight: '1.25' }],
        '4xl': ['2.25rem', { lineHeight: '1.25' }]
      },
      
      // 阴影系统 - 飞书风格
      boxShadow: {
        'card': '0 2px 8px 0 rgba(31, 35, 41, 0.08)',
        'hover': '0 4px 16px 0 rgba(31, 35, 41, 0.12)',
        'modal': '0 8px 32px 0 rgba(31, 35, 41, 0.16)',
        'focus': '0 0 0 2px rgba(51, 112, 255, 0.2)'
      },
      
      // 间距系统
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem'
      },
      
      // 动画
      animation: {
        'fade-in': 'fadeIn 0.2s ease-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'pulse-green': 'pulseGreen 2s infinite'
      },
      
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' }
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        },
        pulseGreen: {
          '0%, 100%': { boxShadow: '0 0 0 0 rgba(0, 185, 107, 0.4)' },
          '70%': { boxShadow: '0 0 0 10px rgba(0, 185, 107, 0)' }
        }
      }
    },
  },
  plugins: [],
}