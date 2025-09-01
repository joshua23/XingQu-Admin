import { useEffect, useRef } from 'react'

interface UseAutoRefreshOptions {
  interval?: number // 刷新间隔（毫秒）
  enabled?: boolean // 是否启用自动刷新
  immediate?: boolean // 是否立即执行一次
}

export const useAutoRefresh = (
  callback: () => void,
  options: UseAutoRefreshOptions = {}
) => {
  const {
    interval = 15 * 60 * 1000, // 默认15分钟
    enabled = true,
    immediate = true
  } = options

  const callbackRef = useRef(callback)
  const intervalRef = useRef<NodeJS.Timeout>()

  // 更新回调引用
  useEffect(() => {
    callbackRef.current = callback
  }, [callback])

  useEffect(() => {
    if (!enabled) {
      if (intervalRef.current) {
        clearInterval(intervalRef.current)
      }
      return
    }

    // 立即执行一次
    if (immediate) {
      callbackRef.current()
    }

    // 设置定时器
    intervalRef.current = setInterval(() => {
      callbackRef.current()
    }, interval)

    // 清理函数
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current)
      }
    }
  }, [interval, enabled, immediate])

  // 手动刷新函数
  const refresh = () => {
    callbackRef.current()
  }

  // 清理函数
  const cleanup = () => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current)
    }
  }

  return { refresh, cleanup }
}