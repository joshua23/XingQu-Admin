import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface MemoryRequest {
  action: 'list' | 'create' | 'update' | 'delete' | 'search' | 'get_types'
  memory_data?: {
    memory_type_id: string
    title: string
    content?: string
    tags?: string[]
    related_character_id?: string
    related_conversation_id?: string
    metadata?: Record<string, any>
  }
  memory_id?: string
  search_query?: string
  filters?: {
    memory_type_id?: string
    tags?: string[]
    date_range?: {
      start: string
      end: string
    }
  }
  limit?: number
  offset?: number
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const requestBody: MemoryRequest = await req.json()
    const { action, memory_data, memory_id, search_query, filters, limit = 20, offset = 0 } = requestBody

    switch (action) {
      case 'list':
        return await listMemoryItems(supabaseClient, user.id, filters, limit, offset)
      
      case 'create':
        if (!memory_data) {
          return new Response(
            JSON.stringify({ error: 'Missing memory_data' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await createMemoryItem(supabaseClient, user.id, memory_data)
      
      case 'update':
        if (!memory_id || !memory_data) {
          return new Response(
            JSON.stringify({ error: 'Missing memory_id or memory_data' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await updateMemoryItem(supabaseClient, user.id, memory_id, memory_data)
      
      case 'delete':
        if (!memory_id) {
          return new Response(
            JSON.stringify({ error: 'Missing memory_id' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await deleteMemoryItem(supabaseClient, user.id, memory_id)
      
      case 'search':
        if (!search_query) {
          return new Response(
            JSON.stringify({ error: 'Missing search_query' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await searchMemoryItems(supabaseClient, user.id, search_query, filters, limit)
      
      case 'get_types':
        return await getMemoryTypes(supabaseClient)
      
      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

async function listMemoryItems(
  supabaseClient: any, 
  userId: string, 
  filters?: any, 
  limit: number = 20, 
  offset: number = 0
) {
  try {
    let query = supabaseClient
      .from('memory_items')
      .select(`
        *,
        memory_types!inner(
          id,
          type_name,
          display_name,
          icon_name,
          color_hex
        )
      `)
      .eq('user_id', userId)
      .eq('is_archived', false)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1)

    // Apply filters
    if (filters?.memory_type_id) {
      query = query.eq('memory_type_id', filters.memory_type_id)
    }

    if (filters?.tags && filters.tags.length > 0) {
      query = query.overlaps('tags', filters.tags)
    }

    if (filters?.date_range) {
      query = query
        .gte('created_at', filters.date_range.start)
        .lte('created_at', filters.date_range.end)
    }

    const { data: memoryItems, error } = await query

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch memory items' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get total count for pagination
    let countQuery = supabaseClient
      .from('memory_items')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_archived', false)

    if (filters?.memory_type_id) {
      countQuery = countQuery.eq('memory_type_id', filters.memory_type_id)
    }

    const { count, error: countError } = await countQuery

    if (countError) {
      console.error('Count error:', countError)
    }

    // Get memory type statistics
    const { data: typeStats, error: statsError } = await supabaseClient
      .from('memory_items')
      .select(`
        memory_type_id,
        memory_types!inner(display_name, color_hex)
      `)
      .eq('user_id', userId)
      .eq('is_archived', false)

    const statsMap = new Map()
    typeStats?.forEach((item: any) => {
      const typeId = item.memory_type_id
      if (!statsMap.has(typeId)) {
        statsMap.set(typeId, {
          type_id: typeId,
          type_name: item.memory_types.display_name,
          color: item.memory_types.color_hex,
          count: 0
        })
      }
      statsMap.get(typeId).count++
    })

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          memory_items: memoryItems,
          total_count: count || 0,
          type_statistics: Array.from(statsMap.values()),
          pagination: {
            limit,
            offset,
            has_more: (count || 0) > offset + limit
          }
        }
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error listing memory items:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to list memory items' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function createMemoryItem(supabaseClient: any, userId: string, memoryData: any) {
  try {
    const { data, error } = await supabaseClient
      .from('memory_items')
      .insert({
        user_id: userId,
        memory_type_id: memoryData.memory_type_id,
        title: memoryData.title,
        content: memoryData.content || '',
        tags: memoryData.tags || [],
        related_character_id: memoryData.related_character_id,
        related_conversation_id: memoryData.related_conversation_id,
        metadata: memoryData.metadata || {}
      })
      .select(`
        *,
        memory_types!inner(
          id,
          type_name,
          display_name,
          icon_name,
          color_hex
        )
      `)
      .single()

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to create memory item' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create search vector for full-text search
    await createSearchVector(supabaseClient, data.id, data.title, data.content)

    // Update user activity
    await updateUserActivity(supabaseClient, userId, 'memory_create', {
      memory_type: data.memory_types.type_name
    })

    return new Response(
      JSON.stringify({
        success: true,
        data,
        message: 'Memory item created successfully'
      }),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error creating memory item:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to create memory item' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function updateMemoryItem(supabaseClient: any, userId: string, memoryId: string, memoryData: any) {
  try {
    const { data, error } = await supabaseClient
      .from('memory_items')
      .update({
        memory_type_id: memoryData.memory_type_id,
        title: memoryData.title,
        content: memoryData.content,
        tags: memoryData.tags,
        related_character_id: memoryData.related_character_id,
        related_conversation_id: memoryData.related_conversation_id,
        metadata: memoryData.metadata
      })
      .eq('id', memoryId)
      .eq('user_id', userId)
      .select(`
        *,
        memory_types!inner(
          id,
          type_name,
          display_name,
          icon_name,
          color_hex
        )
      `)
      .single()

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to update memory item' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update search vector
    await createSearchVector(supabaseClient, data.id, data.title, data.content)

    return new Response(
      JSON.stringify({
        success: true,
        data,
        message: 'Memory item updated successfully'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error updating memory item:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to update memory item' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function deleteMemoryItem(supabaseClient: any, userId: string, memoryId: string) {
  try {
    // Soft delete by archiving
    const { error } = await supabaseClient
      .from('memory_items')
      .update({ is_archived: true })
      .eq('id', memoryId)
      .eq('user_id', userId)

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to delete memory item' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Memory item deleted successfully'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error deleting memory item:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to delete memory item' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function searchMemoryItems(
  supabaseClient: any, 
  userId: string, 
  searchQuery: string, 
  filters?: any, 
  limit: number = 20
) {
  try {
    // Use PostgreSQL full-text search
    const { data: searchResults, error } = await supabaseClient
      .from('memory_search_vectors')
      .select(`
        memory_id,
        memory_items!inner(
          *,
          memory_types!inner(
            id,
            type_name,
            display_name,
            icon_name,
            color_hex
          )
        )
      `)
      .eq('memory_items.user_id', userId)
      .eq('memory_items.is_archived', false)
      .textSearch('search_vector', searchQuery, {
        type: 'websearch',
        config: 'english'
      })
      .limit(limit)

    if (error) {
      console.error('Search error:', error)
      // Fallback to simple text search
      return await fallbackTextSearch(supabaseClient, userId, searchQuery, filters, limit)
    }

    const memoryItems = searchResults.map((result: any) => ({
      ...result.memory_items,
      search_rank: 1.0 // Placeholder for actual search ranking
    }))

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          memory_items: memoryItems,
          search_query: searchQuery,
          total_results: memoryItems.length,
          search_method: 'full_text_search'
        }
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error searching memory items:', error)
    return await fallbackTextSearch(supabaseClient, userId, searchQuery, filters, limit)
  }
}

async function fallbackTextSearch(
  supabaseClient: any, 
  userId: string, 
  searchQuery: string, 
  filters?: any, 
  limit: number = 20
) {
  try {
    let query = supabaseClient
      .from('memory_items')
      .select(`
        *,
        memory_types!inner(
          id,
          type_name,
          display_name,
          icon_name,
          color_hex
        )
      `)
      .eq('user_id', userId)
      .eq('is_archived', false)
      .or(`title.ilike.%${searchQuery}%,content.ilike.%${searchQuery}%`)
      .order('created_at', { ascending: false })
      .limit(limit)

    // Apply additional filters
    if (filters?.memory_type_id) {
      query = query.eq('memory_type_id', filters.memory_type_id)
    }

    const { data: memoryItems, error } = await query

    if (error) {
      console.error('Fallback search error:', error)
      return new Response(
        JSON.stringify({ error: 'Search failed' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          memory_items: memoryItems,
          search_query: searchQuery,
          total_results: memoryItems.length,
          search_method: 'fallback_text_search'
        }
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in fallback search:', error)
    return new Response(
      JSON.stringify({ error: 'Search failed' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function getMemoryTypes(supabaseClient: any) {
  try {
    const { data: memoryTypes, error } = await supabaseClient
      .from('memory_types')
      .select('*')
      .order('display_order')

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to get memory types' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: memoryTypes,
        total_types: memoryTypes.length
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error getting memory types:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to get memory types' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function createSearchVector(supabaseClient: any, memoryId: string, title: string, content: string) {
  try {
    const searchText = `${title} ${content || ''}`.trim()
    
    const { error } = await supabaseClient
      .from('memory_search_vectors')
      .upsert({
        memory_id: memoryId,
        search_vector: supabaseClient.rpc('to_tsvector', ['english', searchText])
      })

    if (error) {
      console.error('Error creating search vector:', error)
    }
  } catch (error) {
    console.error('Error creating search vector:', error)
  }
}

async function updateUserActivity(supabaseClient: any, userId: string, activityType: string, activityData: any) {
  try {
    const expPoints = activityType === 'memory_create' ? 8 : 3
    
    const { error } = await supabaseClient
      .from('users')
      .update({ 
        experience_points: supabaseClient.raw('experience_points + ?', [expPoints])
      })
      .eq('id', userId)

    if (error) {
      console.error('Error updating user activity:', error)
    }
  } catch (error) {
    console.error('Error updating user activity:', error)
  }
}

/* Deno.serve(serve) */