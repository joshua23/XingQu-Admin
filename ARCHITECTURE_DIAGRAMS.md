# 星趣App架构图集

## 1. 系统整体架构图

```mermaid
graph TB
    subgraph "客户端层"
        iOS[iOS App]
        Android[Android App]
        Web[Web App]
    end
    
    subgraph "Flutter应用层"
        UI[UI层<br/>Material Design 3]
        Route[路由管理<br/>Named Routes]
        State[状态管理<br/>Provider]
        Cache[本地缓存<br/>SharedPreferences]
    end
    
    subgraph "业务功能层"
        Home[🏠 主页系统]
        Discovery[🔍 发现中心]
        Creation[🎨 创作中心]
        Message[💬 消息中心]
        Profile[👤 个人中心]
    end
    
    subgraph "服务层"
        Auth[认证服务<br/>AuthService]
        API[业务API<br/>ApiService]
        DB[数据库服务<br/>SupabaseService]
        AI[AI服务<br/>AIService]
        Analytics[分析服务<br/>AnalyticsService]
    end
    
    subgraph "Supabase后端"
        PG[(PostgreSQL<br/>80+ Tables)]
        SAuth[Supabase Auth<br/>OTP/OAuth]
        Storage[Storage<br/>文件存储]
        RT[Realtime<br/>WebSocket]
        Edge[Edge Functions<br/>业务逻辑]
    end
    
    subgraph "外部服务"
        Volcano[火山引擎<br/>大模型API]
        CDN[CDN<br/>内容分发]
        SMS[SMS网关<br/>短信服务]
        Pay[支付系统<br/>微信/支付宝]
    end
    
    iOS --> UI
    Android --> UI
    Web --> UI
    
    UI --> Route
    Route --> State
    State --> Cache
    
    UI --> Home & Discovery & Creation & Message & Profile
    
    Home --> Auth & API & DB
    Discovery --> API & DB & AI
    Creation --> API & DB & AI
    Message --> API & DB & RT
    Profile --> Auth & API & DB
    
    Auth --> SAuth
    API --> PG & Edge
    DB --> PG & Storage
    AI --> Volcano
    Analytics --> PG
    
    SAuth --> SMS
    Storage --> CDN
    Profile --> Pay
```

## 2. 主页功能架构图

```mermaid
graph LR
    subgraph "主页容器 HomeRefactored"
        TabController[Tab控制器]
        
        subgraph "精选页"
            S1[AI角色推荐]
            S2[轮播组件]
            S3[个性化推荐]
            S4[快速对话入口]
        end
        
        subgraph "综合页"
            C1[AI对话]
            C2[角色定制]
            C3[记忆挑战]
            C4[双语学习]
            C5[推荐算法]
            C6[订阅管理]
        end
        
        subgraph "FM电台"
            F1[播放器控件]
            F2[频道列表]
            F3[播放历史]
            F4[收藏管理]
        end
        
        subgraph "AI助理"
            A1[智能对话]
            A2[预设问答]
            A3[任务处理]
            A4[个性化服务]
        end
    end
    
    TabController --> 精选页
    TabController --> 综合页
    TabController --> FM电台
    TabController --> AI助理
    
    S1 --> API1[获取推荐列表]
    S4 --> API2[创建对话会话]
    C1 --> API3[AI对话API]
    F1 --> API4[音频流API]
    A1 --> API5[助理服务API]
```

## 3. 数据库架构图

```mermaid
graph TD
    subgraph "用户系统"
        users[users<br/>用户基础表]
        profiles[profiles<br/>用户档案]
        settings[settings<br/>用户设置]
    end
    
    subgraph "AI角色系统"
        characters[ai_characters<br/>AI角色]
        tags[character_tags<br/>角色标签]
        follows[character_follows<br/>关注关系]
    end
    
    subgraph "内容系统"
        contents[contents<br/>内容表]
        comments[comments<br/>评论表]
        likes[likes<br/>点赞表]
    end
    
    subgraph "音频系统"
        audio[audio_contents<br/>音频内容]
        playlists[playlists<br/>播放列表]
        history[play_history<br/>播放历史]
    end
    
    subgraph "API集成扩展"
        conv[conversations<br/>对话会话]
        msg[messages<br/>消息记录]
        usage[api_usage<br/>使用统计]
        quota[api_quota<br/>配额管理]
    end
    
    users --> profiles
    users --> settings
    users --> follows
    users --> contents
    users --> comments
    users --> likes
    users --> playlists
    users --> conv
    
    characters --> tags
    characters --> follows
    characters --> conv
    
    contents --> comments
    contents --> likes
    
    audio --> playlists
    audio --> history
    
    conv --> msg
    conv --> usage
    users --> quota
```

## 4. 数据流架构图

```mermaid
sequenceDiagram
    participant User as 用户
    participant App as Flutter App
    participant Auth as 认证服务
    participant API as API服务
    participant DB as Supabase DB
    participant AI as AI服务
    participant Cache as 本地缓存
    
    User->>App: 打开应用
    App->>Cache: 检查登录状态
    
    alt 未登录
        App->>User: 显示登录页
        User->>App: 输入手机号
        App->>Auth: 请求OTP
        Auth->>User: 发送验证码
        User->>App: 输入验证码
        App->>Auth: 验证OTP
        Auth->>App: 返回Token
        App->>Cache: 保存Token
    end
    
    App->>API: 获取用户数据
    API->>DB: 查询数据
    DB->>API: 返回结果
    API->>App: 返回用户信息
    
    User->>App: 选择AI角色对话
    App->>AI: 发送对话请求
    AI->>AI: 处理请求
    AI->>App: 返回AI响应
    App->>DB: 保存对话记录
    App->>User: 显示对话内容
```

## 5. 服务依赖关系图

```mermaid
graph LR
    subgraph "前端服务依赖"
        AppService[App Services]
        AppService --> AuthDep[AuthService]
        AppService --> ApiDep[ApiService]
        AppService --> DBDep[SupabaseService]
        
        AuthDep --> SupaAuth[Supabase Auth]
        AuthDep --> SMSDep[SMS Service]
        
        ApiDep --> SupaDB[Supabase DB]
        ApiDep --> EdgeFunc[Edge Functions]
        
        DBDep --> SupaDB
        DBDep --> SupaStorage[Supabase Storage]
    end
    
    subgraph "后端服务依赖"
        SupaDB --> PGExt[PostgreSQL Extensions]
        SupaStorage --> CDNDep[CDN Service]
        EdgeFunc --> VolcanoDep[火山引擎API]
        EdgeFunc --> ModerDep[内容审核API]
    end
    
    subgraph "第三方集成"
        SMSDep --> SMSGate[SMS Gateway]
        CDNDep --> CDNProv[CDN Provider]
        VolcanoDep --> LLM[大语言模型]
        PayDep[支付服务] --> WXPay[微信支付]
        PayDep --> AliPay[支付宝]
    end
```

## 6. 部署架构图

```mermaid
graph TB
    subgraph "开发环境"
        Dev[本地开发<br/>Flutter + Supabase Local]
        DevDB[(开发数据库)]
    end
    
    subgraph "测试环境"
        Test[测试服务器<br/>Staging]
        TestDB[(测试数据库)]
        TestCDN[测试CDN]
    end
    
    subgraph "生产环境"
        subgraph "前端部署"
            AppStore[App Store<br/>iOS]
            PlayStore[Google Play<br/>Android]
            WebHost[Web托管<br/>Vercel/Netlify]
        end
        
        subgraph "后端部署"
            SupaProd[Supabase<br/>生产实例]
            ProdDB[(生产数据库<br/>PostgreSQL)]
            ProdStorage[对象存储<br/>S3兼容]
            ProdCDN[生产CDN<br/>全球加速]
        end
        
        subgraph "监控系统"
            APM[性能监控]
            Logger[日志系统]
            Alert[告警系统]
        end
    end
    
    Dev --> Test
    Test --> 生产环境
    
    AppStore --> SupaProd
    PlayStore --> SupaProd
    WebHost --> SupaProd
    
    SupaProd --> ProdDB
    SupaProd --> ProdStorage
    ProdStorage --> ProdCDN
    
    SupaProd --> APM
    SupaProd --> Logger
    Logger --> Alert
```

## 7. 安全架构图

```mermaid
graph TD
    subgraph "安全层级"
        subgraph "应用层安全"
            AppAuth[应用认证<br/>JWT Token]
            AppEnc[数据加密<br/>HTTPS/TLS]
            AppVal[输入验证<br/>表单校验]
        end
        
        subgraph "API层安全"
            APIAuth[API认证<br/>Bearer Token]
            APIRate[速率限制<br/>Rate Limiting]
            APICORS[CORS策略]
        end
        
        subgraph "数据层安全"
            RLS[行级安全<br/>Row Level Security]
            Encrypt[数据加密<br/>字段级加密]
            Backup[数据备份<br/>自动备份]
        end
        
        subgraph "内容安全"
            TextMod[文本审核]
            ImageMod[图片审核]
            AudioMod[音频审核]
        end
    end
    
    User[用户请求] --> AppAuth
    AppAuth --> AppEnc
    AppEnc --> AppVal
    AppVal --> APIAuth
    APIAuth --> APIRate
    APIRate --> APICORS
    APICORS --> RLS
    RLS --> Encrypt
    Encrypt --> Backup
    
    Content[用户内容] --> TextMod & ImageMod & AudioMod
    TextMod & ImageMod & AudioMod --> Filter[内容过滤]
    Filter --> Store[安全存储]
```

## 8. 性能优化架构图

```mermaid
graph LR
    subgraph "前端优化"
        LazyLoad[懒加载<br/>按需加载组件]
        ImageOpt[图片优化<br/>WebP格式]
        CodeSplit[代码分割<br/>路由级分割]
        StateOpt[状态优化<br/>减少重渲染]
    end
    
    subgraph "网络优化"
        CDNCache[CDN缓存<br/>静态资源]
        APICache[API缓存<br/>响应缓存]
        Compress[数据压缩<br/>Gzip/Brotli]
        HTTP2[HTTP/2<br/>多路复用]
    end
    
    subgraph "数据库优化"
        Index[索引优化<br/>15+专用索引]
        Query[查询优化<br/>预编译语句]
        Pool[连接池<br/>复用连接]
        Partition[分区策略<br/>大表分区]
    end
    
    subgraph "缓存策略"
        Memory[内存缓存<br/>热点数据]
        Redis[Redis缓存<br/>会话数据]
        Local[本地缓存<br/>离线数据]
    end
    
    LazyLoad --> Performance[性能提升]
    ImageOpt --> Performance
    CodeSplit --> Performance
    StateOpt --> Performance
    
    CDNCache --> Performance
    APICache --> Performance
    Compress --> Performance
    HTTP2 --> Performance
    
    Index --> Performance
    Query --> Performance
    Pool --> Performance
    Partition --> Performance
    
    Memory --> Performance
    Redis --> Performance
    Local --> Performance
```

## 说明

这些架构图展示了星趣App的完整技术架构：

1. **系统整体架构** - 展示了从客户端到后端的完整技术栈
2. **主页功能架构** - 详细展示了4个Tab页面的功能结构
3. **数据库架构** - 展示了80+表的关系结构
4. **数据流架构** - 展示了用户操作的完整数据流程
5. **服务依赖关系** - 展示了各服务之间的依赖关系
6. **部署架构** - 展示了开发、测试、生产环境的部署结构
7. **安全架构** - 展示了多层级的安全防护体系
8. **性能优化架构** - 展示了全方位的性能优化策略

所有图表均使用Mermaid语法，可以在支持Mermaid的Markdown查看器中直接渲染查看。