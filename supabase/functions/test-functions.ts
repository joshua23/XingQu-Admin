// Edge Functions 测试脚本
// 用于测试部署的Edge Functions是否正常工作

const SUPABASE_URL = 'https://wqdpqhfqrxvssxifpmvt.supabase.co'
const SUPABASE_ANON_KEY = 'your_anon_key_here'
const FUNCTIONS_URL = `${SUPABASE_URL}/functions/v1`

// 测试用户Token（需要从实际登录获取）
const TEST_USER_TOKEN = 'your_test_user_jwt_token'

// 测试AI对话函数
async function testAIChat() {
  console.log('🧪 测试AI对话函数...')
  
  const response = await fetch(`${FUNCTIONS_URL}/ai-chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${TEST_USER_TOKEN}`,
    },
    body: JSON.stringify({
      message: '你好，请介绍一下星趣APP',
      stream: false,
      temperature: 0.7,
      maxTokens: 500
    })
  })

  if (response.ok) {
    const data = await response.json()
    console.log('✅ AI对话测试成功:')
    console.log('  - Session ID:', data.sessionId)
    console.log('  - Message ID:', data.messageId)
    console.log('  - Tokens Used:', data.tokensUsed)
    console.log('  - Cost:', data.cost)
    console.log('  - Content:', data.content.substring(0, 100) + '...')
  } else {
    console.error('❌ AI对话测试失败:', await response.text())
  }
}

// 测试音频内容函数
async function testAudioContent() {
  console.log('\n🧪 测试音频内容函数...')
  
  // 测试获取列表
  const listResponse = await fetch(`${FUNCTIONS_URL}/audio-content`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${TEST_USER_TOKEN}`,
    },
    body: JSON.stringify({
      action: 'list',
      category: 'all',
      page: 1,
      pageSize: 10
    })
  })

  if (listResponse.ok) {
    const data = await listResponse.json()
    console.log('✅ 音频列表测试成功:')
    console.log('  - Total Contents:', data.data.pagination.total)
    console.log('  - Current Page:', data.data.pagination.page)
    console.log('  - Contents Count:', data.data.contents.length)
    
    // 测试获取详情
    if (data.data.contents.length > 0) {
      const audioId = data.data.contents[0].id
      const detailResponse = await fetch(`${FUNCTIONS_URL}/audio-content`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${TEST_USER_TOKEN}`,
        },
        body: JSON.stringify({
          action: 'detail',
          audioId: audioId
        })
      })

      if (detailResponse.ok) {
        const detailData = await detailResponse.json()
        console.log('✅ 音频详情测试成功:')
        console.log('  - Title:', detailData.data.title)
        console.log('  - Stream URL:', detailData.data.streamConfig.primaryUrl)
      }
    }
  } else {
    console.error('❌ 音频内容测试失败:', await listResponse.text())
  }
}

// 测试用户权限函数
async function testUserPermission() {
  console.log('\n🧪 测试用户权限函数...')
  
  const response = await fetch(`${FUNCTIONS_URL}/user-permission`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${TEST_USER_TOKEN}`,
    },
    body: JSON.stringify({
      action: 'check',
      apiType: 'llm'
    })
  })

  if (response.ok) {
    const data = await response.json()
    console.log('✅ 权限检查测试成功:')
    console.log('  - Allowed:', data.allowed)
    console.log('  - Membership:', data.data.permissions.membership.planType)
    console.log('  - LLM Quota:', data.data.permissions.quotas.llm)
    console.log('  - Features:', data.data.permissions.features)
  } else {
    console.error('❌ 权限验证测试失败:', await response.text())
  }
}

// 运行所有测试
async function runAllTests() {
  console.log('🚀 开始测试 Edge Functions...\n')
  
  try {
    await testAIChat()
    await testAudioContent()
    await testUserPermission()
    
    console.log('\n✅ 所有测试完成!')
  } catch (error) {
    console.error('\n❌ 测试过程中出现错误:', error)
  }
}

// 如果直接运行此文件
if (import.meta.main) {
  runAllTests()
}