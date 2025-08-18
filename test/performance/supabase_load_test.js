import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// 自定义指标
const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

// 测试配置
export const options = {
  stages: [
    { duration: '2m', target: 100 }, // 2分钟内逐渐增加到100用户
    { duration: '5m', target: 100 }, // 维持100用户5分钟
    { duration: '2m', target: 200 }, // 2分钟内增加到200用户
    { duration: '5m', target: 200 }, // 维持200用户5分钟
    { duration: '2m', target: 0 },   // 2分钟内降到0用户
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95%的请求应在2秒内完成
    http_req_failed: ['rate<0.05'],    // 错误率应低于5%
    errors: ['rate<0.1'],              // 自定义错误率应低于10%
  },
};

// Supabase配置
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-key';

const headers = {
  'Content-Type': 'application/json',
  'apikey': SUPABASE_ANON_KEY,
  'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
};

// 测试用户数据
const testUsers = [
  { email: 'test1@example.com', password: 'testpass123' },
  { email: 'test2@example.com', password: 'testpass123' },
  { email: 'test3@example.com', password: 'testpass123' },
];

export default function() {
  // 随机选择测试用户
  const user = testUsers[Math.floor(Math.random() * testUsers.length)];
  
  // 1. 用户认证测试
  authenticationLoadTest(user);
  
  // 2. 交互菜单API测试
  interactionMenuLoadTest();
  
  // 3. 记忆簿API测试
  memoryBookLoadTest();
  
  // 4. 推荐系统API测试
  recommendationLoadTest();
  
  // 5. 订阅管理API测试
  subscriptionLoadTest();
  
  sleep(1); // 请求间隔
}

/**
 * 用户认证压力测试
 */
function authenticationLoadTest(user) {
  const loginPayload = JSON.stringify({
    email: user.email,
    password: user.password,
  });
  
  const loginResponse = http.post(
    `${SUPABASE_URL}/auth/v1/token?grant_type=password`,
    loginPayload,
    { headers }
  );
  
  const loginSuccess = check(loginResponse, {
    '认证请求状态为200': (r) => r.status === 200,
    '认证响应时间<1s': (r) => r.timings.duration < 1000,
    '返回访问令牌': (r) => JSON.parse(r.body).access_token !== undefined,
  });
  
  responseTime.add(loginResponse.timings.duration);
  errorRate.add(!loginSuccess);
}

/**
 * 交互菜单API压力测试
 */
function interactionMenuLoadTest() {
  // 获取交互菜单配置
  const menuResponse = http.post(
    `${SUPABASE_URL}/functions/v1/interaction-menu`,
    JSON.stringify({
      page_type: 'ai_interaction',
      action: 'get'
    }),
    { headers }
  );
  
  const menuSuccess = check(menuResponse, {
    '菜单API状态为200': (r) => r.status === 200,
    '菜单响应时间<500ms': (r) => r.timings.duration < 500,
    '返回菜单配置': (r) => {
      const body = JSON.parse(r.body);
      return body.success && body.data.menu_items;
    },
  });
  
  responseTime.add(menuResponse.timings.duration);
  errorRate.add(!menuSuccess);
  
  // 记录交互日志
  const logResponse = http.post(
    `${SUPABASE_URL}/functions/v1/interaction-menu`,
    JSON.stringify({
      page_type: 'ai_interaction',
      action: 'log_interaction',
      interaction_data: {
        type: 'click',
        target: 'menu_item_1',
        timestamp: new Date().toISOString()
      }
    }),
    { headers }
  );
  
  check(logResponse, {
    '交互日志状态为200': (r) => r.status === 200,
    '日志响应时间<300ms': (r) => r.timings.duration < 300,
  });
}

/**
 * 记忆簿API压力测试
 */
function memoryBookLoadTest() {
  // 获取记忆列表
  const listResponse = http.post(
    `${SUPABASE_URL}/functions/v1/memory-book`,
    JSON.stringify({
      action: 'list',
      filters: {
        category: 'work',
        priority: 'high'
      },
      pagination: {
        page: 1,
        limit: 20
      }
    }),
    { headers }
  );
  
  const listSuccess = check(listResponse, {
    '记忆列表状态为200': (r) => r.status === 200,
    '列表响应时间<800ms': (r) => r.timings.duration < 800,
    '返回记忆数据': (r) => {
      const body = JSON.parse(r.body);
      return body.success && Array.isArray(body.data);
    },
  });
  
  responseTime.add(listResponse.timings.duration);
  errorRate.add(!listSuccess);
  
  // 创建新记忆
  const createResponse = http.post(
    `${SUPABASE_URL}/functions/v1/memory-book`,
    JSON.stringify({
      action: 'create',
      memory_data: {
        title: `测试记忆 ${Math.random().toString(36).substr(2, 9)}`,
        content: '这是一个性能测试创建的记忆项目',
        category: 'test',
        priority: 'medium',
        tags: ['performance', 'test']
      }
    }),
    { headers }
  );
  
  check(createResponse, {
    '创建记忆状态为200': (r) => r.status === 200,
    '创建响应时间<1s': (r) => r.timings.duration < 1000,
  });
}

/**
 * 推荐系统API压力测试
 */
function recommendationLoadTest() {
  // 获取推荐内容
  const recommendResponse = http.post(
    `${SUPABASE_URL}/functions/v1/recommendation`,
    JSON.stringify({
      action: 'get_recommendations',
      user_preferences: {
        categories: ['ai', 'tech', 'story'],
        interaction_history: ['click', 'like', 'share']
      },
      algorithm: 'collaborative_filtering',
      limit: 10
    }),
    { headers }
  );
  
  const recommendSuccess = check(recommendResponse, {
    '推荐API状态为200': (r) => r.status === 200,
    '推荐响应时间<1.5s': (r) => r.timings.duration < 1500,
    '返回推荐内容': (r) => {
      const body = JSON.parse(r.body);
      return body.success && Array.isArray(body.data.recommendations);
    },
  });
  
  responseTime.add(recommendResponse.timings.duration);
  errorRate.add(!recommendSuccess);
  
  // 更新用户偏好
  const preferenceResponse = http.post(
    `${SUPABASE_URL}/functions/v1/recommendation`,
    JSON.stringify({
      action: 'update_preferences',
      preferences: {
        categories: ['ai', 'tech'],
        weights: { 'content_based': 0.6, 'collaborative': 0.4 }
      }
    }),
    { headers }
  );
  
  check(preferenceResponse, {
    '偏好更新状态为200': (r) => r.status === 200,
    '偏好响应时间<500ms': (r) => r.timings.duration < 500,
  });
}

/**
 * 订阅管理API压力测试
 */
function subscriptionLoadTest() {
  // 获取订阅列表
  const subscriptionsResponse = http.post(
    `${SUPABASE_URL}/functions/v1/subscription`,
    JSON.stringify({
      action: 'list',
      status: 'active'
    }),
    { headers }
  );
  
  const subscriptionSuccess = check(subscriptionsResponse, {
    '订阅列表状态为200': (r) => r.status === 200,
    '订阅响应时间<600ms': (r) => r.timings.duration < 600,
    '返回订阅数据': (r) => {
      const body = JSON.parse(r.body);
      return body.success && Array.isArray(body.data);
    },
  });
  
  responseTime.add(subscriptionsResponse.timings.duration);
  errorRate.add(!subscriptionSuccess);
  
  // 更新订阅状态
  const updateResponse = http.post(
    `${SUPABASE_URL}/functions/v1/subscription`,
    JSON.stringify({
      action: 'update',
      subscription_id: '12345',
      status: 'paused'
    }),
    { headers }
  );
  
  check(updateResponse, {
    '订阅更新状态为200': (r) => r.status === 200,
    '更新响应时间<400ms': (r) => r.timings.duration < 400,
  });
}

/**
 * 数据库查询性能测试
 */
export function databasePerformanceTest() {
  // 复杂查询测试
  const complexQueryResponse = http.get(
    `${SUPABASE_URL}/rest/v1/memory_items?select=*,memory_categories(name)&category=eq.work&priority=eq.high&order=created_at.desc&limit=50`,
    { headers }
  );
  
  check(complexQueryResponse, {
    '复杂查询状态为200': (r) => r.status === 200,
    '复杂查询时间<2s': (r) => r.timings.duration < 2000,
  });
  
  // 聚合查询测试
  const aggregateResponse = http.get(
    `${SUPABASE_URL}/rest/v1/rpc/get_memory_statistics`,
    { headers }
  );
  
  check(aggregateResponse, {
    '聚合查询状态为200': (r) => r.status === 200,
    '聚合查询时间<1s': (r) => r.timings.duration < 1000,
  });
  
  // 全文搜索测试
  const searchResponse = http.get(
    `${SUPABASE_URL}/rest/v1/rpc/search_memories?query=测试`,
    { headers }
  );
  
  check(searchResponse, {
    '搜索查询状态为200': (r) => r.status === 200,
    '搜索响应时间<1.5s': (r) => r.timings.duration < 1500,
  });
}

/**
 * 测试结束时的清理工作
 */
export function teardown() {
  console.log('负载测试完成！');
  console.log(`总请求数: ${__VU * __ITER}`);
  console.log('性能测试报告已生成');
}