const { chromium } = require('playwright');

async function debugPages() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  // 监听页面错误
  page.on('pageerror', (error) => {
    console.error('🚨 页面错误:', error.message);
    console.error('错误堆栈:', error.stack);
  });

  // 监听控制台消息
  page.on('console', (msg) => {
    const type = msg.type();
    if (type === 'error' || type === 'warning') {
      console.log(`${type === 'error' ? '❌' : '⚠️'} 控制台${type}:`, msg.text());
    }
  });

  // 监听网络错误
  page.on('requestfailed', (request) => {
    console.error('🌐 网络请求失败:', request.url(), request.failure()?.errorText);
  });

  try {
    console.log('🔍 开始调试页面...');
    
    // 访问首页
    console.log('📄 访问首页...');
    await page.goto('http://localhost:3001');
    await page.waitForTimeout(3000);
    
    // 检查是否需要登录
    const currentUrl = page.url();
    console.log('当前URL:', currentUrl);
    
    if (currentUrl.includes('/login')) {
      console.log('🔐 需要登录，进行开发模式登录...');
      // 空账密登录（开发模式）
      await page.click('button[type="submit"]');
      await page.waitForTimeout(2000);
    }

    // 测试用户管理页面
    console.log('👥 测试用户管理页面...');
    await page.goto('http://localhost:3001/users');
    
    // 等待页面加载完成
    try {
      await page.waitForSelector('h1', { timeout: 10000 });
      const usersPageTitle = await page.textContent('h1');
      console.log('用户管理页面标题:', usersPageTitle);
      
      // 检查是否有错误信息
      const errorMessages = await page.$$eval('[class*="error"], .text-red-500, .text-destructive', 
        elements => elements.map(el => el.textContent).filter(text => text.trim())
      );
      if (errorMessages.length > 0) {
        console.log('❌ 用户页面错误信息:', errorMessages);
      } else {
        console.log('✅ 用户管理页面加载正常');
      }
    } catch (error) {
      console.error('❌ 用户页面加载超时:', error.message);
    }

    // 测试素材管理页面
    console.log('🎨 测试素材管理页面...');
    await page.goto('http://localhost:3001/materials');
    
    // 等待页面加载完成
    try {
      await page.waitForSelector('h1', { timeout: 10000 });
      const materialsPageTitle = await page.textContent('h1');
      console.log('素材管理页面标题:', materialsPageTitle);
      
      // 检查是否有错误信息
      const errorMessages = await page.$$eval('[class*="error"], .text-red-500, .text-destructive', 
        elements => elements.map(el => el.textContent).filter(text => text.trim())
      );
      if (errorMessages.length > 0) {
        console.log('❌ 素材页面错误信息:', errorMessages);
      } else {
        console.log('✅ 素材管理页面加载正常');
      }
    } catch (error) {
      console.error('❌ 素材页面加载超时:', error.message);
    }

    // 截图保存
    await page.screenshot({ path: 'debug-users-page.png', fullPage: true });
    console.log('📸 已保存用户页面截图: debug-users-page.png');

    await page.goto('http://localhost:3001/materials');
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'debug-materials-page.png', fullPage: true });
    console.log('📸 已保存素材页面截图: debug-materials-page.png');

  } catch (error) {
    console.error('💥 调试过程中出错:', error.message);
    console.error('错误详情:', error.stack);
  } finally {
    console.log('🏁 调试完成，关闭浏览器...');
    await browser.close();
  }
}

debugPages();