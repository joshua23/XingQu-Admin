import React, { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '../ui/Card'
import { FileText, Upload, Eye, Download, AlertTriangle, CheckCircle } from 'lucide-react'

// 从 docs/用户协议.md 获取的内容
const DEFAULT_DOCUMENT = `# 星趣用户协议

**更新日期：2025年9月1日**

欢迎您使用星趣！

## 特别提示

为了更好地为您提供服务，请您在开始使用星趣产品和服务之前，认真阅读并充分理解《星趣用户协议》（"本协议"或"用户协议"）及《星趣隐私政策》（"隐私政策"），特别是涉及免除或者限制责任的条款、权利许可和信息使用的条款、同意开通和使用特殊单项服务的条款、法律适用和争议解决条款等。

您点击确认本协议、以其他方式同意本协议或实际使用星趣产品和服务的，即表示您同意、接受并承诺遵守本协议的全部内容。

## 一、协议的范围

1.1 本协议是您（即用户）与上海启垒应网络科技有限公司及其关联公司（合称"我们"）之间关于用户使用星趣产品和服务所订立的协议。

1.2 本协议适用于星趣移动端应用程序（包括但不限于iOS应用、Android应用）、网站、小程序及其他相关服务平台。

1.3 我们根据本协议，通过星趣向用户提供的服务（"本服务"），包括但不限于人工智能（"AI"）相关的智能对话、问答等服务。

1.4 本协议构成您与我们之间的完整协议，并取代双方此前就同一事项达成的所有口头或书面协议。

## 二、服务内容

2.1 用户在使用本服务前需要提前使用手机号注册认证以获得【星趣】账户。

2.2 本产品的具体功能由星趣根据实际情况提供，包括但不限于虚拟智能体连结、对话、获得成就、客服服务等。

2.3 我们保留根据实际需要对服务内容进行更新、升级、暂停或终止的权利，并将通过适当方式通知用户。

2.4 部分服务可能需要额外付费，相关收费标准将在服务页面明确标示，用户确认后生效。

## 三、服务使用规则

3.1 用户在本服务中或通过本服务所传送、发布的任何内容并不反映或代表，也不得被视为反映或代表我们的观点、立场或政策，我们对此不承担任何责任。

3.2 用户承诺不会利用本服务进行任何违法、有害、威胁、辱骂、骚扰、侵权、中伤、粗俗、猥亵、诽谤的行为。

3.3 用户不得利用本服务制作、上传、复制、发布、传播或者转载如下内容：
- 反对宪法所确定的基本原则的
- 危害国家安全，泄露国家秘密，颠覆国家政权，破坏国家统一的
- 损害国家荣誉和利益的
- 煽动民族仇恨、民族歧视，破坏民族团结的
- 破坏国家宗教政策，宣扬邪教和封建迷信的
- 散布谣言，扰乱社会秩序，破坏社会稳定的
- 散布淫秽、色情、赌博、暴力、凶杀、恐怖或者教唆犯罪的
- 侮辱或者诽谤他人，侵害他人合法权益的
- 含有法律、行政法规禁止的其他内容的

3.4 用户理解并同意，我们有权对用户发布的内容进行审核，并有权删除违规内容。

## 四、账户安全

4.1 用户有责任维护账户信息的安全性和保密性，包括但不限于登录密码、验证码等。

4.2 用户应对自己账户下的所有活动和事件负责。如发现账户被盗用或存在安全漏洞，应立即通知我们。

4.3 我们不会主动要求用户提供密码，请用户妥善保管账户信息，谨防诈骗。

## 五、隐私保护

5.1 我们严格按照《星趣隐私政策》收集、使用、存储和保护用户个人信息。

5.2 用户的个人信息仅在法律允许的范围内使用，我们不会向第三方出售、出租或以其他方式披露用户个人信息。

5.3 用户有权查看、修改或删除自己的个人信息，具体操作请参考应用内相关功能或联系客服。

## 六、知识产权

6.1 本服务中包含的所有内容，包括但不限于文字、图片、音频、视频、软件、程序、版面设计等，均受知识产权法律保护。

6.2 未经我们明确书面同意，用户不得复制、修改、发布、销售或以其他方式使用上述内容。

6.3 用户在使用本服务过程中发布的原创内容，用户保留相应知识产权，但授权我们在本服务中使用。

## 七、免责声明

7.1 用户理解并同意，本服务基于现有技术和条件提供。我们不保证服务不会中断，不保证服务的及时性、安全性、准确性。

7.2 我们不对以下情况承担责任：
- 因自然灾害、罢工、暴乱、战争等不可抗力因素造成的服务中断
- 因用户自身原因导致的账户安全问题
- 因第三方行为造成的损失
- 因用户违反本协议造成的任何损失

7.3 在法律允许的范围内，我们对任何间接的、偶然的、特殊的或后果性的损害不承担责任。

## 八、协议变更

8.1 我们有权随时修改本协议，修改后的协议将在本服务中公布。

8.2 如果用户不同意修改后的协议，可以选择停止使用本服务；如果用户继续使用本服务，视为接受修改后的协议。

8.3 重大协议变更将通过站内信、推送通知等方式告知用户。

## 九、服务终止

9.1 用户可以随时停止使用本服务，并可按照相关流程注销账户。

9.2 如用户违反本协议，我们有权暂停或终止用户账户，并保留追究法律责任的权利。

9.3 因以下原因造成的服务终止，我们不承担违约责任：
- 用户严重违反本协议
- 用户利用本服务进行违法犯罪活动
- 根据法律法规要求需要终止服务

## 十、争议解决

10.1 本协议的签订、履行、解释均适用中华人民共和国法律。

10.2 因本协议引起的争议，双方应友好协商解决；协商不成的，任何一方均可向被告住所地人民法院提起诉讼。

## 十一、其他条款

11.1 本协议的标题仅为方便而设，不影响条款的解释。

11.2 如本协议中的任何条款被判定为无效或不可执行，该条款将被删除，但不影响其他条款的效力。

11.3 我们未行使或执行本协议任何权利或条款，不构成对该权利或条款的放弃。

## 联系我们

如您对本协议有任何疑问，或需要举报违规行为，请通过以下方式联系我们：

- 客服邮箱：support@xingqu.ai
- 客服电话：400-123-4567
- 公司地址：上海市浦东新区张江高科技园区XX路XX号

**上海启垒应网络科技有限公司**

**生效日期：2025年9月1日**`

export const DocumentUploadTab: React.FC = () => {
  const [document, setDocument] = useState(DEFAULT_DOCUMENT)
  const [isUploading, setIsUploading] = useState(false)
  const [uploadSuccess, setUploadSuccess] = useState<string | null>(null)
  const [uploadError, setUploadError] = useState<string | null>(null)

  // 处理文件上传
  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // 验证文件类型
    if (!file.name.endsWith('.md') && !file.name.endsWith('.txt')) {
      setUploadError('请上传 .md 或 .txt 格式的文件')
      return
    }

    // 验证文件大小（限制为 1MB）
    if (file.size > 1024 * 1024) {
      setUploadError('文件大小不能超过 1MB')
      return
    }

    setIsUploading(true)
    setUploadError(null)
    setUploadSuccess(null)

    try {
      const text = await file.text()
      setDocument(text)
      setUploadSuccess(`文件 "${file.name}" 上传成功！内容已更新。`)
      
      // 3秒后清除成功提示
      setTimeout(() => setUploadSuccess(null), 3000)
    } catch (error) {
      setUploadError('文件读取失败，请重试')
    } finally {
      setIsUploading(false)
      // 清除 input 值，允许重复上传同一文件
      event.target.value = ''
    }
  }

  // 下载当前文档
  const handleDownload = () => {
    const blob = new Blob([document], { type: 'text/markdown;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = '用户协议.md'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)
  }

  return (
    <div className="space-y-6">
      {/* 页面标题和操作区域 */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center space-x-2">
              <FileText size={20} />
              <span>隐私/用户协议管理</span>
            </CardTitle>
            
            <div className="flex items-center space-x-3">
              {/* 下载按钮 */}
              <button
                onClick={handleDownload}
                className="inline-flex items-center space-x-2 px-4 py-2 bg-secondary text-secondary-foreground rounded-md hover:bg-secondary/80 transition-colors"
                title="下载当前文档"
              >
                <Download size={16} />
                <span>下载</span>
              </button>

              {/* 文件上传 */}
              <label className="inline-flex items-center space-x-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors cursor-pointer">
                <Upload size={16} />
                <span>{isUploading ? '上传中...' : '上传文档'}</span>
                <input
                  type="file"
                  accept=".md,.txt"
                  onChange={handleFileUpload}
                  disabled={isUploading}
                  className="hidden"
                />
              </label>
            </div>
          </div>
        </CardHeader>

        <CardContent>
          {/* 状态提示 */}
          {uploadSuccess && (
            <div className="flex items-center space-x-2 p-3 mb-4 bg-green-50 dark:bg-green-950/20 border border-green-200 dark:border-green-800/30 rounded-lg text-green-800 dark:text-green-200">
              <CheckCircle size={16} />
              <span className="text-sm">{uploadSuccess}</span>
            </div>
          )}

          {uploadError && (
            <div className="flex items-center space-x-2 p-3 mb-4 bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800/30 rounded-lg text-red-800 dark:text-red-200">
              <AlertTriangle size={16} />
              <span className="text-sm">{uploadError}</span>
            </div>
          )}


          {/* 重要提醒 */}
          <div className="flex items-start space-x-3 p-4 mb-6 bg-amber-50 dark:bg-amber-950/20 border border-amber-200 dark:border-amber-800/30 rounded-lg">
            <AlertTriangle size={20} className="text-amber-600 dark:text-amber-400 mt-0.5 flex-shrink-0" />
            <div>
              <h4 className="font-medium text-amber-800 dark:text-amber-200 mb-1">重要提醒</h4>
              <p className="text-sm text-amber-700 dark:text-amber-300">
                上传的文档内容将直接替换当前的用户协议，并立即对所有用户生效。
                请确保内容符合法律法规要求，并在上传前仔细审核。
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 文档内容预览 */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Eye size={18} />
            <span>当前文档内容</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="prose prose-sm max-w-none">
            <pre className="whitespace-pre-wrap font-sans text-sm leading-relaxed bg-muted/30 p-4 rounded-lg border">
              {document}
            </pre>
          </div>
          
          {/* 文档统计 */}
          <div className="flex items-center justify-between mt-4 pt-4 border-t border-border text-sm text-muted-foreground">
            <div className="flex items-center space-x-4">
              <span>字符数: {document.length.toLocaleString()}</span>
              <span>行数: {document.split('\n').length}</span>
              <span>大小: {Math.round(new Blob([document]).size / 1024 * 100) / 100} KB</span>
            </div>
            <div>
              最后更新: {new Date().toLocaleString('zh-CN')}
            </div>
          </div>
        </CardContent>
      </Card>

    </div>
  )
}

export default DocumentUploadTab