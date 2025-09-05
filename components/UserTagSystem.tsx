/**
 * 用户标签系统组件 - 星趣后台管理系统
 * 功能：标签创建管理、用户标签分配、基于标签的用户筛选
 * Created: 2025-09-05
 */

'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Checkbox } from '@/components/ui/checkbox'
import { 
  Plus, 
  Tag, 
  Users, 
  Search, 
  Filter,
  Edit3,
  Trash2,
  X,
  Check,
  Hash,
  Target
} from 'lucide-react'

// 标签类型定义
export interface UserTag {
  id: string
  name: string
  color: string
  description?: string
  category?: string
  userCount: number
  isSystem: boolean
  createdAt: string
  updatedAt: string
}

export interface TaggedUser {
  id: string
  nickname: string
  email: string
  tags: string[]
  avatar?: string
}

// 预定义标签颜色
const TAG_COLORS = [
  { name: '蓝色', value: '#3B82F6', bg: 'bg-blue-100', text: 'text-blue-800', border: 'border-blue-200' },
  { name: '绿色', value: '#10B981', bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-200' },
  { name: '黄色', value: '#F59E0B', bg: 'bg-yellow-100', text: 'text-yellow-800', border: 'border-yellow-200' },
  { name: '红色', value: '#EF4444', bg: 'bg-red-100', text: 'text-red-800', border: 'border-red-200' },
  { name: '紫色', value: '#8B5CF6', bg: 'bg-purple-100', text: 'text-purple-800', border: 'border-purple-200' },
  { name: '粉色', value: '#EC4899', bg: 'bg-pink-100', text: 'text-pink-800', border: 'border-pink-200' },
  { name: '青色', value: '#06B6D4', bg: 'bg-cyan-100', text: 'text-cyan-800', border: 'border-cyan-200' },
  { name: '灰色', value: '#6B7280', bg: 'bg-gray-100', text: 'text-gray-800', border: 'border-gray-200' }
]

// 标签分类
const TAG_CATEGORIES = [
  { value: 'behavior', label: '行为标签' },
  { value: 'preference', label: '偏好标签' },
  { value: 'demographic', label: '人口统计' },
  { value: 'engagement', label: '参与度' },
  { value: 'risk', label: '风险标签' },
  { value: 'custom', label: '自定义' }
]

interface UserTagSystemProps {
  tags: UserTag[]
  users: TaggedUser[]
  onCreateTag: (tag: Omit<UserTag, 'id' | 'userCount' | 'createdAt' | 'updatedAt'>) => Promise<void>
  onUpdateTag: (id: string, updates: Partial<UserTag>) => Promise<void>
  onDeleteTag: (id: string) => Promise<void>
  onAssignTags: (userIds: string[], tagIds: string[]) => Promise<void>
  onRemoveTags: (userIds: string[], tagIds: string[]) => Promise<void>
  loading?: boolean
}

export default function UserTagSystem({
  tags = [],
  users = [],
  onCreateTag,
  onUpdateTag,
  onDeleteTag,
  onAssignTags,
  onRemoveTags,
  loading = false
}: UserTagSystemProps) {
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [selectedTags, setSelectedTags] = useState<string[]>([])
  const [selectedUsers, setSelectedUsers] = useState<string[]>([])
  
  // 创建标签对话框状态
  const [showCreateDialog, setShowCreateDialog] = useState(false)
  const [newTag, setNewTag] = useState({
    name: '',
    color: TAG_COLORS[0].value,
    description: '',
    category: 'custom' as string,
    isSystem: false
  })
  
  // 编辑标签对话框状态
  const [editingTag, setEditingTag] = useState<UserTag | null>(null)
  const [showEditDialog, setShowEditDialog] = useState(false)
  
  // 批量操作状态
  const [showBatchDialog, setShowBatchDialog] = useState(false)
  const [batchOperation, setBatchOperation] = useState<'add' | 'remove'>('add')
  const [batchTagIds, setBatchTagIds] = useState<string[]>([])

  // 过滤标签
  const filteredTags = useMemo(() => {
    let filtered = tags

    // 按分类筛选
    if (selectedCategory !== 'all') {
      filtered = filtered.filter(tag => tag.category === selectedCategory)
    }

    // 搜索过滤
    if (searchQuery) {
      const query = searchQuery.toLowerCase()
      filtered = filtered.filter(tag =>
        tag.name.toLowerCase().includes(query) ||
        tag.description?.toLowerCase().includes(query)
      )
    }

    return filtered.sort((a, b) => b.userCount - a.userCount)
  }, [tags, selectedCategory, searchQuery])

  // 过滤用户（基于选中的标签）
  const filteredUsers = useMemo(() => {
    if (selectedTags.length === 0) {
      return users
    }

    return users.filter(user =>
      selectedTags.some(tagId => user.tags.includes(tagId))
    )
  }, [users, selectedTags])

  // 获取标签颜色样式
  const getTagColorStyle = (color: string) => {
    const colorConfig = TAG_COLORS.find(c => c.value === color) || TAG_COLORS[0]
    return {
      backgroundColor: colorConfig.value + '20',
      color: colorConfig.value,
      borderColor: colorConfig.value + '40'
    }
  }

  // 创建标签
  const handleCreateTag = async () => {
    if (!newTag.name.trim()) return

    try {
      await onCreateTag({
        name: newTag.name.trim(),
        color: newTag.color,
        description: newTag.description.trim(),
        category: newTag.category,
        isSystem: newTag.isSystem
      })

      setNewTag({
        name: '',
        color: TAG_COLORS[0].value,
        description: '',
        category: 'custom',
        isSystem: false
      })
      setShowCreateDialog(false)
    } catch (error) {
      console.error('创建标签失败:', error)
    }
  }

  // 更新标签
  const handleUpdateTag = async () => {
    if (!editingTag) return

    try {
      await onUpdateTag(editingTag.id, {
        name: editingTag.name,
        color: editingTag.color,
        description: editingTag.description,
        category: editingTag.category
      })

      setEditingTag(null)
      setShowEditDialog(false)
    } catch (error) {
      console.error('更新标签失败:', error)
    }
  }

  // 删除标签
  const handleDeleteTag = async (tagId: string) => {
    if (!confirm('确定要删除这个标签吗？删除后无法恢复。')) return

    try {
      await onDeleteTag(tagId)
    } catch (error) {
      console.error('删除标签失败:', error)
    }
  }

  // 批量分配/移除标签
  const handleBatchOperation = async () => {
    if (selectedUsers.length === 0 || batchTagIds.length === 0) return

    try {
      if (batchOperation === 'add') {
        await onAssignTags(selectedUsers, batchTagIds)
      } else {
        await onRemoveTags(selectedUsers, batchTagIds)
      }

      setSelectedUsers([])
      setBatchTagIds([])
      setShowBatchDialog(false)
    } catch (error) {
      console.error('批量操作失败:', error)
    }
  }

  // 渲染标签项
  const renderTag = (tag: UserTag) => (
    <Card key={tag.id} className="relative group">
      <CardContent className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-2">
              <Badge 
                style={getTagColorStyle(tag.color)}
                className="px-2 py-1 text-sm font-medium border"
              >
                <Hash className="w-3 h-3 mr-1" />
                {tag.name}
              </Badge>
              {tag.isSystem && (
                <Badge variant="outline" className="text-xs">
                  系统标签
                </Badge>
              )}
            </div>
            
            {tag.description && (
              <p className="text-sm text-muted-foreground mb-2">{tag.description}</p>
            )}
            
            <div className="flex items-center gap-4 text-xs text-muted-foreground">
              <span className="flex items-center gap-1">
                <Users className="w-3 h-3" />
                {tag.userCount} 用户
              </span>
              <span>
                {TAG_CATEGORIES.find(c => c.value === tag.category)?.label || '未分类'}
              </span>
            </div>
          </div>

          {/* 操作按钮 */}
          <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
            <Button
              variant="ghost"
              size="sm"
              className="h-7 w-7 p-0"
              onClick={() => {
                setEditingTag(tag)
                setShowEditDialog(true)
              }}
              disabled={tag.isSystem}
            >
              <Edit3 className="h-3 w-3" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              className="h-7 w-7 p-0 hover:bg-red-50 hover:text-red-600"
              onClick={() => handleDeleteTag(tag.id)}
              disabled={tag.isSystem}
            >
              <Trash2 className="h-3 w-3" />
            </Button>
          </div>
        </div>

        {/* 标签选择器 */}
        <div className="mt-2">
          <Checkbox
            id={`tag-${tag.id}`}
            checked={selectedTags.includes(tag.id)}
            onCheckedChange={(checked) => {
              if (checked) {
                setSelectedTags([...selectedTags, tag.id])
              } else {
                setSelectedTags(selectedTags.filter(id => id !== tag.id))
              }
            }}
            className="mr-2"
          />
          <label
            htmlFor={`tag-${tag.id}`}
            className="text-sm cursor-pointer"
          >
            用于筛选用户
          </label>
        </div>
      </CardContent>
    </Card>
  )

  // 渲染用户项
  const renderUser = (user: TaggedUser) => {
    const userTags = tags.filter(tag => user.tags.includes(tag.id))
    
    return (
      <div key={user.id} className="flex items-center justify-between p-3 border rounded-lg hover:bg-muted/50 transition-colors">
        <div className="flex items-center gap-3">
          <Checkbox
            checked={selectedUsers.includes(user.id)}
            onCheckedChange={(checked) => {
              if (checked) {
                setSelectedUsers([...selectedUsers, user.id])
              } else {
                setSelectedUsers(selectedUsers.filter(id => id !== user.id))
              }
            }}
          />
          
          <div className="w-8 h-8 bg-primary/20 rounded-full flex items-center justify-center">
            <span className="text-sm font-medium text-primary">
              {user.nickname[0]}
            </span>
          </div>
          
          <div>
            <div className="font-medium">{user.nickname}</div>
            <div className="text-sm text-muted-foreground">{user.email}</div>
          </div>
        </div>

        <div className="flex flex-wrap gap-1">
          {userTags.map(tag => (
            <Badge
              key={tag.id}
              style={getTagColorStyle(tag.color)}
              className="text-xs border"
            >
              {tag.name}
            </Badge>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 头部统计 */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="text-2xl font-bold text-blue-600">{tags.length}</div>
            <p className="text-sm text-muted-foreground">总标签数</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-2xl font-bold text-green-600">
              {tags.filter(t => !t.isSystem).length}
            </div>
            <p className="text-sm text-muted-foreground">自定义标签</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="text-2xl font-bold text-purple-600">
              {selectedTags.length > 0 ? filteredUsers.length : users.length}
            </div>
            <p className="text-sm text-muted-foreground">
              {selectedTags.length > 0 ? '筛选用户' : '总用户数'}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* 操作栏 */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <Search className="h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="搜索标签..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-48"
            />
          </div>
          
          <Select value={selectedCategory} onValueChange={setSelectedCategory}>
            <SelectTrigger className="w-32">
              <SelectValue placeholder="分类" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">所有分类</SelectItem>
              {TAG_CATEGORIES.map(category => (
                <SelectItem key={category.value} value={category.value}>
                  {category.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          {(searchQuery || selectedCategory !== 'all') && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                setSearchQuery('')
                setSelectedCategory('all')
              }}
            >
              <X className="h-4 w-4 mr-1" />
              清除筛选
            </Button>
          )}
        </div>

        <div className="flex gap-2">
          <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
            <DialogTrigger asChild>
              <Button>
                <Plus className="h-4 w-4 mr-2" />
                创建标签
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>创建新标签</DialogTitle>
                <DialogDescription>
                  为用户创建新的分类标签
                </DialogDescription>
              </DialogHeader>
              
              <div className="space-y-4">
                <div>
                  <label className="text-sm font-medium">标签名称</label>
                  <Input
                    value={newTag.name}
                    onChange={(e) => setNewTag({ ...newTag, name: e.target.value })}
                    placeholder="输入标签名称"
                  />
                </div>
                
                <div>
                  <label className="text-sm font-medium">标签描述</label>
                  <Input
                    value={newTag.description}
                    onChange={(e) => setNewTag({ ...newTag, description: e.target.value })}
                    placeholder="标签用途说明（可选）"
                  />
                </div>
                
                <div>
                  <label className="text-sm font-medium">分类</label>
                  <Select 
                    value={newTag.category} 
                    onValueChange={(value) => setNewTag({ ...newTag, category: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {TAG_CATEGORIES.map(category => (
                        <SelectItem key={category.value} value={category.value}>
                          {category.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                
                <div>
                  <label className="text-sm font-medium">标签颜色</label>
                  <div className="flex flex-wrap gap-2 mt-2">
                    {TAG_COLORS.map(color => (
                      <button
                        key={color.value}
                        className={`w-8 h-8 rounded-full border-2 ${
                          newTag.color === color.value 
                            ? 'border-gray-900 scale-110' 
                            : 'border-gray-300'
                        } transition-all`}
                        style={{ backgroundColor: color.value }}
                        onClick={() => setNewTag({ ...newTag, color: color.value })}
                        title={color.name}
                      />
                    ))}
                  </div>
                </div>
              </div>
              
              <DialogFooter>
                <Button 
                  variant="outline" 
                  onClick={() => setShowCreateDialog(false)}
                >
                  取消
                </Button>
                <Button 
                  onClick={handleCreateTag}
                  disabled={!newTag.name.trim()}
                >
                  创建标签
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
          
          {selectedUsers.length > 0 && (
            <Button 
              variant="outline"
              onClick={() => setShowBatchDialog(true)}
            >
              <Target className="h-4 w-4 mr-2" />
              批量操作 ({selectedUsers.length})
            </Button>
          )}
        </div>
      </div>

      {/* 标签管理区域 */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Tag className="h-5 w-5" />
            标签管理
          </CardTitle>
          <CardDescription>
            显示 {filteredTags.length} 个标签，共 {tags.length} 个
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {[...Array(6)].map((_, i) => (
                <Card key={i} className="animate-pulse">
                  <CardContent className="p-4">
                    <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                    <div className="h-3 bg-gray-200 rounded w-full mb-2"></div>
                    <div className="h-3 bg-gray-200 rounded w-1/2"></div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : filteredTags.length === 0 ? (
            <div className="text-center py-12">
              <Tag className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-lg font-medium text-muted-foreground mb-2">
                {searchQuery ? '没有找到匹配的标签' : '暂无标签'}
              </h3>
              <p className="text-muted-foreground">
                {searchQuery ? '尝试调整搜索条件' : '点击"创建标签"开始管理用户标签'}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredTags.map(renderTag)}
            </div>
          )}
        </CardContent>
      </Card>

      {/* 用户列表区域 */}
      {selectedTags.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5" />
              筛选用户
              <Badge variant="outline" className="ml-2">
                {filteredUsers.length} 人
              </Badge>
            </CardTitle>
            <CardDescription>
              基于选中标签筛选的用户列表
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 max-h-96 overflow-y-auto">
              {filteredUsers.map(renderUser)}
            </div>
          </CardContent>
        </Card>
      )}

      {/* 编辑标签对话框 */}
      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>编辑标签</DialogTitle>
            <DialogDescription>
              修改标签的基本信息
            </DialogDescription>
          </DialogHeader>
          
          {editingTag && (
            <div className="space-y-4">
              <div>
                <label className="text-sm font-medium">标签名称</label>
                <Input
                  value={editingTag.name}
                  onChange={(e) => setEditingTag({ ...editingTag, name: e.target.value })}
                  placeholder="输入标签名称"
                />
              </div>
              
              <div>
                <label className="text-sm font-medium">标签描述</label>
                <Input
                  value={editingTag.description || ''}
                  onChange={(e) => setEditingTag({ ...editingTag, description: e.target.value })}
                  placeholder="标签用途说明（可选）"
                />
              </div>
              
              <div>
                <label className="text-sm font-medium">分类</label>
                <Select 
                  value={editingTag.category || 'custom'} 
                  onValueChange={(value) => setEditingTag({ ...editingTag, category: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {TAG_CATEGORIES.map(category => (
                      <SelectItem key={category.value} value={category.value}>
                        {category.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div>
                <label className="text-sm font-medium">标签颜色</label>
                <div className="flex flex-wrap gap-2 mt-2">
                  {TAG_COLORS.map(color => (
                    <button
                      key={color.value}
                      className={`w-8 h-8 rounded-full border-2 ${
                        editingTag.color === color.value 
                          ? 'border-gray-900 scale-110' 
                          : 'border-gray-300'
                      } transition-all`}
                      style={{ backgroundColor: color.value }}
                      onClick={() => setEditingTag({ ...editingTag, color: color.value })}
                      title={color.name}
                    />
                  ))}
                </div>
              </div>
            </div>
          )}
          
          <DialogFooter>
            <Button 
              variant="outline" 
              onClick={() => setShowEditDialog(false)}
            >
              取消
            </Button>
            <Button 
              onClick={handleUpdateTag}
              disabled={!editingTag?.name.trim()}
            >
              保存更改
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* 批量操作对话框 */}
      <Dialog open={showBatchDialog} onOpenChange={setShowBatchDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>批量标签操作</DialogTitle>
            <DialogDescription>
              为选中的 {selectedUsers.length} 个用户批量添加或移除标签
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium">操作类型</label>
              <Select 
                value={batchOperation} 
                onValueChange={(value: 'add' | 'remove') => setBatchOperation(value)}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="add">添加标签</SelectItem>
                  <SelectItem value="remove">移除标签</SelectItem>
                </SelectContent>
              </Select>
            </div>
            
            <div>
              <label className="text-sm font-medium">选择标签</label>
              <div className="grid grid-cols-2 gap-2 mt-2 max-h-48 overflow-y-auto">
                {tags.map(tag => (
                  <div key={tag.id} className="flex items-center gap-2">
                    <Checkbox
                      checked={batchTagIds.includes(tag.id)}
                      onCheckedChange={(checked) => {
                        if (checked) {
                          setBatchTagIds([...batchTagIds, tag.id])
                        } else {
                          setBatchTagIds(batchTagIds.filter(id => id !== tag.id))
                        }
                      }}
                    />
                    <Badge 
                      style={getTagColorStyle(tag.color)}
                      className="text-xs border"
                    >
                      {tag.name}
                    </Badge>
                  </div>
                ))}
              </div>
            </div>
          </div>
          
          <DialogFooter>
            <Button 
              variant="outline" 
              onClick={() => setShowBatchDialog(false)}
            >
              取消
            </Button>
            <Button 
              onClick={handleBatchOperation}
              disabled={batchTagIds.length === 0}
            >
              {batchOperation === 'add' ? '添加标签' : '移除标签'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}