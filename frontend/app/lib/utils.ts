import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

/**
 * 格式化日期时间 - 完整显示日期和时间(24小时制)
 * @param dateInput - Date对象、ISO字符串或时间戳
 * @returns 格式化的日期时间字符串,使用用户本地时区和语言设置
 */
export function formatDateTime(dateInput: Date | string | number): string {
  const date = typeof dateInput === 'string' || typeof dateInput === 'number' 
    ? new Date(dateInput) 
    : dateInput

  if (isNaN(date.getTime())) {
    return '-'
  }

  return date.toLocaleString(undefined, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  })
}

/**
 * 格式化时间 - 仅显示时间(24小时制)
 * @param dateInput - Date对象、ISO字符串或时间戳
 * @returns 格式化的时间字符串
 */
export function formatTime(dateInput: Date | string | number): string {
  const date = typeof dateInput === 'string' || typeof dateInput === 'number'
    ? new Date(dateInput)
    : dateInput

  if (isNaN(date.getTime())) {
    return '-'
  }

  return date.toLocaleTimeString(undefined, {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  })
}

/**
 * 格式化日期 - 仅显示日期
 * @param dateInput - Date对象、ISO字符串或时间戳
 * @returns 格式化的日期字符串
 */
export function formatDate(dateInput: Date | string | number): string {
  const date = typeof dateInput === 'string' || typeof dateInput === 'number'
    ? new Date(dateInput)
    : dateInput

  if (isNaN(date.getTime())) {
    return '-'
  }

  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  })
}

/**
 * 格式化图表标签 - 根据时间范围调整显示格式
 * @param dateInput - Date对象、ISO字符串或时间戳
 * @param timeframe - 时间范围('5m', '1h', '1d')
 * @returns 格式化的图表标签字符串
 */
export function formatChartLabel(dateInput: Date | string | number, timeframe: '5m' | '1h' | '1d'): string {
  const date = typeof dateInput === 'string' || typeof dateInput === 'number'
    ? new Date(dateInput)
    : dateInput

  if (isNaN(date.getTime())) {
    return '-'
  }

  if (timeframe === '5m') {
    // 5分钟粒度:显示时:分(24小时制)
    return date.toLocaleTimeString(undefined, {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    })
  } else if (timeframe === '1h') {
    // 1小时粒度:显示月-日 时(24小时制)
    return date.toLocaleString(undefined, {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      hour12: false
    })
  } else {
    // 1天粒度:显示月-日
    return date.toLocaleDateString(undefined, {
      month: 'short',
      day: 'numeric'
    })
  }
}
