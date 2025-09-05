/**
 * 星趣后台管理系统 - 支付订单管理页面
 * 集成支付订单管理组件
 * Created: 2025-09-05
 */

'use client'

import React from 'react'
import PaymentOrderManager from '@/components/payment/PaymentOrderManager'

export default function PaymentsPage() {
  return (
    <div className="container mx-auto py-6">
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">支付订单</h1>
          <p className="text-muted-foreground">
            管理支付订单、退款处理和财务统计
          </p>
        </div>

        <PaymentOrderManager />
      </div>
    </div>
  )
}