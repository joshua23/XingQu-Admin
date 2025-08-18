import type { G2PlotTheme } from '@antv/g2plot'

// 基于经济学人风格的图表主题配置
export const useChartTheme = () => {
  // 经济学人风格主题
  const economistTheme: Partial<G2PlotTheme> = {
    // 默认配色
    defaultColor: '#1890FF',
    
    // 分类配色
    colors10: [
      '#1890FF', // 主蓝色
      '#52C41A', // 成功绿
      '#FAAD14', // 警告黄
      '#F5222D', // 错误红
      '#722ED1', // 紫色
      '#13C2C2', // 青色
      '#FA8C16', // 橙色
      '#A0D911', // 青绿色
      '#EB2F96', // 洋红色
      '#F759AB'  // 粉色
    ],
    
    // AARRR专用配色
    aarrrColors: [
      '#1890FF', // 获取 - 蓝色
      '#13C2C2', // 激活 - 青色
      '#52C41A', // 留存 - 绿色
      '#FAAD14', // 收入 - 黄色
      '#722ED1'  // 推荐 - 紫色
    ],
    
    // 几何图形样式
    geometries: {
      // 间隔图形（柱状图、条形图等）
      interval: {
        rect: {
          default: { 
            fill: '#1890FF', 
            stroke: '#1890FF', 
            lineWidth: 0,
            fillOpacity: 0.8
          },
          active: { 
            stroke: '#1890FF', 
            lineWidth: 2,
            fillOpacity: 1
          },
          inactive: { 
            fillOpacity: 0.3, 
            strokeOpacity: 0.3 
          }
        }
      },
      
      // 线图形
      line: {
        line: {
          default: { 
            stroke: '#1890FF', 
            lineWidth: 2, 
            strokeOpacity: 1,
            lineDash: [0, 0]
          },
          active: { 
            lineWidth: 3,
            strokeOpacity: 1
          },
          inactive: { 
            strokeOpacity: 0.3 
          }
        },
        point: {
          default: { 
            fill: '#1890FF', 
            r: 3, 
            stroke: '#fff', 
            lineWidth: 1,
            fillOpacity: 1
          },
          active: { 
            r: 4, 
            stroke: '#1890FF', 
            lineWidth: 2,
            fillOpacity: 1
          },
          inactive: { 
            fillOpacity: 0.3, 
            strokeOpacity: 0.3 
          }
        }
      },
      
      // 区域图形
      area: {
        area: {
          default: {
            fill: '#1890FF',
            fillOpacity: 0.2,
            stroke: '#1890FF',
            lineWidth: 2
          },
          active: {
            fillOpacity: 0.3,
            lineWidth: 3
          },
          inactive: {
            fillOpacity: 0.1,
            strokeOpacity: 0.3
          }
        }
      }
    },
    
    // 坐标轴样式
    axis: {
      common: {
        // 标题样式
        title: {
          style: {
            fontSize: 12,
            fill: '#8C8C8C',
            fontWeight: 400,
            textAlign: 'center',
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif'
          }
        },
        
        // 标签样式
        label: {
          style: {
            fontSize: 12,
            fill: '#595959',
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif'
          }
        },
        
        // 轴线样式
        line: {
          style: {
            stroke: '#F0F0F0',
            lineWidth: 1
          }
        },
        
        // 刻度线样式
        tickLine: {
          style: {
            stroke: '#F0F0F0',
            lineWidth: 1,
            length: 4
          }
        },
        
        // 网格线样式（经济学人风格：只显示水平网格线）
        grid: {
          line: {
            style: {
              stroke: '#F0F0F0',
              lineWidth: 1,
              lineDash: [0, 0],
              strokeOpacity: 0.7
            }
          }
        },
        
        // 子刻度线
        subTickLine: {
          style: {
            stroke: '#F0F0F0',
            lineWidth: 1,
            length: 2
          }
        }
      }
    },
    
    // 图例样式
    legend: {
      common: {
        // 图例项标记
        marker: {
          style: {
            r: 4
          }
        },
        
        // 图例文本
        text: {
          style: {
            fontSize: 12,
            fill: '#595959',
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif'
          }
        },
        
        // 图例标题
        title: {
          style: {
            fontSize: 12,
            fill: '#262626',
            fontWeight: 500
          }
        }
      }
    },
    
    // 标签样式
    label: {
      style: {
        fontSize: 12,
        fill: '#595959',
        fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif'
      }
    },
    
    // 内边距
    padding: [20, 20, 40, 40] as [number, number, number, number]
  }
  
  // 深色主题
  const darkTheme: Partial<G2PlotTheme> = {
    ...economistTheme,
    backgroundColor: '#1F1F1F',
    
    axis: {
      common: {
        ...economistTheme.axis?.common,
        title: {
          style: {
            ...economistTheme.axis?.common?.title?.style,
            fill: '#A6A6A6'
          }
        },
        label: {
          style: {
            ...economistTheme.axis?.common?.label?.style,
            fill: '#D9D9D9'
          }
        },
        line: {
          style: {
            ...economistTheme.axis?.common?.line?.style,
            stroke: '#404040'
          }
        },
        grid: {
          line: {
            style: {
              ...economistTheme.axis?.common?.grid?.line?.style,
              stroke: '#404040'
            }
          }
        }
      }
    },
    
    legend: {
      common: {
        ...economistTheme.legend?.common,
        text: {
          style: {
            ...economistTheme.legend?.common?.text?.style,
            fill: '#D9D9D9'
          }
        }
      }
    }
  }
  
  // 获取指标颜色
  const getMetricColor = (changeType?: 'increase' | 'decrease' | 'neutral') => {
    switch (changeType) {
      case 'increase':
        return '#52C41A'
      case 'decrease':
        return '#F5222D'
      default:
        return '#8C8C8C'
    }
  }
  
  // 获取AARRR阶段颜色
  const getAARRRColor = (stage: string) => {
    const colorMap: Record<string, string> = {
      'Acquisition': '#1890FF',
      'Activation': '#13C2C2',
      'Retention': '#52C41A',
      'Revenue': '#FAAD14',
      'Referral': '#722ED1'
    }
    
    return colorMap[stage] || '#1890FF'
  }
  
  // 生成渐变色
  const createGradient = (color: string, direction: 'vertical' | 'horizontal' = 'vertical') => {
    const opacity1 = 0.8
    const opacity2 = 0.1
    
    return direction === 'vertical' 
      ? `l(270) 0:${color} 0.5:rgba(${hexToRgb(color)}, ${opacity1}) 1:rgba(${hexToRgb(color)}, ${opacity2})`
      : `l(0) 0:${color} 0.5:rgba(${hexToRgb(color)}, ${opacity1}) 1:rgba(${hexToRgb(color)}, ${opacity2})`
  }
  
  // 颜色工具函数
  const hexToRgb = (hex: string): string => {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    if (!result) return '0, 0, 0'
    
    const r = parseInt(result[1], 16)
    const g = parseInt(result[2], 16)
    const b = parseInt(result[3], 16)
    
    return `${r}, ${g}, ${b}`
  }
  
  // 数字格式化
  const formatNumber = (value: number): string => {
    if (value >= 100000000) {
      return `${(value / 100000000).toFixed(1)}亿`
    } else if (value >= 10000) {
      return `${(value / 10000).toFixed(1)}万`
    } else if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}k`
    }
    
    return value.toLocaleString()
  }
  
  // 百分比格式化
  const formatPercent = (value: number): string => {
    return `${(value * 100).toFixed(1)}%`
  }
  
  // 货币格式化
  const formatCurrency = (value: number): string => {
    return `¥${formatNumber(value)}`
  }
  
  return {
    // 主题配置
    economistTheme,
    darkTheme,
    
    // 颜色工具
    getMetricColor,
    getAARRRColor,
    createGradient,
    
    // 格式化工具
    formatNumber,
    formatPercent,
    formatCurrency,
    
    // 颜色常量
    colors: {
      primary: '#1890FF',
      success: '#52C41A',
      warning: '#FAAD14',
      error: '#F5222D',
      info: '#13C2C2'
    }
  }
}