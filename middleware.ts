import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createMiddlewareClient({ req, res })
  const { data: { session } } = await supabase.auth.getSession()

  // 检查开发模式
  const isDevelopment = process.env.NODE_ENV === 'development'
  const devUserCookie = req.cookies.get('dev_admin_user')
  const hasDevUser = isDevelopment && devUserCookie

  // 检查是否已认证 (Supabase session 或开发模式用户)
  const isAuthenticated = session || hasDevUser

  // 保护路由，但排除登录页面和根路径
  if (!isAuthenticated && !req.nextUrl.pathname.startsWith('/login') && req.nextUrl.pathname !== '/') {
    return NextResponse.redirect(new URL('/login', req.url))
  }

  if (isAuthenticated && req.nextUrl.pathname === '/login') {
    return NextResponse.redirect(new URL('/', req.url))
  }

  return res
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)']
}
