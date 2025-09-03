import React, { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { FileText, Edit3, Eye, Save, X } from 'lucide-react'

const SAMPLE_DOCUMENT = `星趣用户协议

更新日期：2025年9月1日
欢迎您使用星趣！

特别提示

为了更好地为您提供服务，请您在开始使用星趣产品和服务之前，认真阅读并充分理解《星趣用户协议》（"本协议"或"用户协议"）及《星趣隐私政策》（"隐私政策"）...

## 一、协议的范围

1.1 本协议是您（即用户）与上海启垒应网络科技有限公司及其关联公司（合称"我们"）之间关于用户使用星趣产品和服务所订立的协议。

1.3 我们根据本协议，通过星趣向用户提供的服务（"本服务"），包括但不限于人工智能（"AI"）相关的智能对话、问答等服务。

## 二、服务内容

2.1 用户在使用本服务前需要提前使用手机号注册认证以获得【星趣】账户。

2.2 本产品的具体功能由星趣根据实际情况提供，包括但不限于虚拟智能体连结、对话、获得成就、客服服务等。

## 三、服务使用规则

3.1 用户在本服务中或通过本服务所传送、发布的任何内容并不反映或代表，也不得被视为反映或代表我们的观点、立场或政策，我们对此不承担任何责任。

...（文档内容继续）`

export const SimpleDocumentTab: React.FC = () => {
  const [content, setContent] = useState(SAMPLE_DOCUMENT)
  const [isEditing, setIsEditing] = useState(false)
  const [editContent, setEditContent] = useState(content)

  const handleStartEdit = () => {
    setEditContent(content)
    setIsEditing(true)
  }

  const handleSave = () => {
    setContent(editContent)
    setIsEditing(false)
    // 这里可以添加实际的保存逻辑
    console.log('文档已保存:', editContent.slice(0, 100) + '...')
  }

  const handleCancel = () => {
    setEditContent(content)
    setIsEditing(false)
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center space-x-2">
              <FileText size={20} />
              <span>隐私/用户协议管理</span>
            </CardTitle>
            
            {!isEditing ? (
              <button
                onClick={handleStartEdit}
                className="inline-flex items-center space-x-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors"
              >
                <Edit3 size={16} />
                <span>编辑文档</span>
              </button>
            ) : (
              <div className="flex items-center space-x-2">
                <button
                  onClick={handleSave}
                  className="inline-flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors"
                >
                  <Save size={16} />
                  <span>保存</span>
                </button>
                <button
                  onClick={handleCancel}
                  className="inline-flex items-center space-x-2 px-4 py-2 bg-secondary text-secondary-foreground rounded-md hover:bg-secondary/80 transition-colors"
                >
                  <X size={16} />
                  <span>取消</span>
                </button>
              </div>
            )}
          </div>
        </CardHeader>

        <CardContent>
          {isEditing ? (
            <div className="space-y-4">
              <div className="border border-amber-200 bg-amber-50 p-3 rounded-lg">
                <p className="text-sm text-amber-800">
                  ⚠️ 注意：对文档的修改将直接影响用户端显示的法律条款，请谨慎操作。
                </p>
              </div>
              
              <textarea
                value={editContent}
                onChange={(e) => setEditContent(e.target.value)}
                className="w-full h-96 p-4 border border-border rounded-lg font-mono text-sm resize-none focus:outline-none focus:ring-2 focus:ring-ring"
                placeholder="编辑您的文档内容..."
              />
              
              <div className="flex items-center justify-between text-sm text-muted-foreground">
                <div>
                  字符数: {editContent.length} | 行数: {editContent.split('\n').length}
                </div>
                <div>
                  支持 Markdown 格式
                </div>
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="bg-blue-50 border border-blue-200 p-3 rounded-lg">
                <div className="flex items-center space-x-2 text-blue-800">
                  <Eye size={16} />
                  <span className="text-sm font-medium">文档预览模式</span>
                </div>
              </div>
              
              <div className="prose prose-sm max-w-none">
                <pre className="whitespace-pre-wrap font-sans text-sm leading-relaxed">
                  {content}
                </pre>
              </div>
              
              <div className="flex items-center justify-between text-sm text-muted-foreground border-t border-border pt-3">
                <div>
                  最后修改: {new Date().toLocaleString('zh-CN')}
                </div>
                <div>
                  大小: {Math.round(content.length / 1024 * 100) / 100} KB
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardContent className="py-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <h4 className="font-medium mb-2">功能说明:</h4>
              <ul className="space-y-1 text-muted-foreground">
                <li>• 查看和编辑用户协议内容</li>
                <li>• 简单的文本编辑界面</li>
                <li>• 实时字符和行数统计</li>
                <li>• 修改前确认提醒</li>
              </ul>
            </div>
            <div>
              <h4 className="font-medium mb-2">使用提醒:</h4>
              <ul className="space-y-1 text-muted-foreground">
                <li>• 修改将直接影响用户端显示</li>
                <li>• 保存前请仔细检查内容</li>
                <li>• 建议在重要修改前备份</li>
                <li>• 当前版本为简化实现</li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

export default SimpleDocumentTab