import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SubscriptionRequest {
  action: 'list' | 'create' | 'update' | 'delete' | 'group_create' | 'group_update' | 'group_delete'
  subscription_data?: {
    target_type: string
    target_id: string
    subscription_type?: string
    tags?: string[]
    priority?: number
    notifications_enabled?: boolean
  }
  group_data?: {
    group_name: string
    group_color?: string
    display_order?: number
  }
  subscription_id?: string
  group_id?: string
  filters?: {
    target_type?: string
    group_id?: string
  }
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

    const requestBody: SubscriptionRequest = await req.json()
    const { action, subscription_data, group_data, subscription_id, group_id, filters } = requestBody

    switch (action) {
      case 'list':
        return await listUserSubscriptions(supabaseClient, user.id, filters)
      
      case 'create':
        if (!subscription_data) {
          return new Response(
            JSON.stringify({ error: 'Missing subscription_data' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await createSubscription(supabaseClient, user.id, subscription_data)
      
      case 'update':
        if (!subscription_id || !subscription_data) {
          return new Response(
            JSON.stringify({ error: 'Missing subscription_id or subscription_data' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await updateSubscription(supabaseClient, user.id, subscription_id, subscription_data)
      
      case 'delete':
        if (!subscription_id) {
          return new Response(
            JSON.stringify({ error: 'Missing subscription_id' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await deleteSubscription(supabaseClient, user.id, subscription_id)
      
      case 'group_create':
        if (!group_data) {
          return new Response(
            JSON.stringify({ error: 'Missing group_data' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await createSubscriptionGroup(supabaseClient, user.id, group_data)
      
      case 'group_update':
        if (!group_id || !group_data) {
          return new Response(
            JSON.stringify({ error: 'Missing group_id or group_data' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await updateSubscriptionGroup(supabaseClient, user.id, group_id, group_data)
      
      case 'group_delete':
        if (!group_id) {
          return new Response(
            JSON.stringify({ error: 'Missing group_id' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
        return await deleteSubscriptionGroup(supabaseClient, user.id, group_id)
      
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

async function listUserSubscriptions(supabaseClient: any, userId: string, filters?: any) {
  try {
    let query = supabaseClient
      .from('user_subscriptions')
      .select(`
        *,
        subscription_groups!subscription_group_items(
          id,
          group_name,
          group_color,
          display_order
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })

    // Apply filters
    if (filters?.target_type) {
      query = query.eq('target_type', filters.target_type)
    }

    const { data: subscriptions, error } = await query

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch subscriptions' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get user's subscription groups
    const { data: groups, error: groupsError } = await supabaseClient
      .from('subscription_groups')
      .select('*')
      .eq('user_id', userId)
      .order('display_order')

    if (groupsError) {
      console.error('Groups database error:', groupsError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch subscription groups' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          subscriptions,
          groups,
          total_subscriptions: subscriptions.length,
          total_groups: groups.length
        }
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error listing subscriptions:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to list subscriptions' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function createSubscription(supabaseClient: any, userId: string, subscriptionData: any) {
  try {
    // Check if subscription already exists
    const { data: existing, error: checkError } = await supabaseClient
      .from('user_subscriptions')
      .select('id')
      .eq('user_id', userId)
      .eq('target_type', subscriptionData.target_type)
      .eq('target_id', subscriptionData.target_id)
      .single()

    if (existing) {
      return new Response(
        JSON.stringify({ error: 'Subscription already exists' }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { data, error } = await supabaseClient
      .from('user_subscriptions')
      .insert({
        user_id: userId,
        target_type: subscriptionData.target_type,
        target_id: subscriptionData.target_id,
        subscription_type: subscriptionData.subscription_type || 'standard',
        tags: subscriptionData.tags || [],
        priority: subscriptionData.priority || 0,
        notifications_enabled: subscriptionData.notifications_enabled ?? true
      })
      .select()
      .single()

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to create subscription' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update user activity
    await updateUserActivity(supabaseClient, userId, 'subscription_create', {
      target_type: subscriptionData.target_type
    })

    return new Response(
      JSON.stringify({
        success: true,
        data,
        message: 'Subscription created successfully'
      }),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error creating subscription:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to create subscription' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function updateSubscription(supabaseClient: any, userId: string, subscriptionId: string, subscriptionData: any) {
  try {
    const { data, error } = await supabaseClient
      .from('user_subscriptions')
      .update({
        subscription_type: subscriptionData.subscription_type,
        tags: subscriptionData.tags,
        priority: subscriptionData.priority,
        notifications_enabled: subscriptionData.notifications_enabled,
        last_accessed_at: new Date().toISOString()
      })
      .eq('id', subscriptionId)
      .eq('user_id', userId)
      .select()
      .single()

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to update subscription' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        data,
        message: 'Subscription updated successfully'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error updating subscription:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to update subscription' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function deleteSubscription(supabaseClient: any, userId: string, subscriptionId: string) {
  try {
    const { error } = await supabaseClient
      .from('user_subscriptions')
      .delete()
      .eq('id', subscriptionId)
      .eq('user_id', userId)

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to delete subscription' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Subscription deleted successfully'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error deleting subscription:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to delete subscription' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function createSubscriptionGroup(supabaseClient: any, userId: string, groupData: any) {
  try {
    const { data, error } = await supabaseClient
      .from('subscription_groups')
      .insert({
        user_id: userId,
        group_name: groupData.group_name,
        group_color: groupData.group_color || '#3B82F6',
        display_order: groupData.display_order || 0
      })
      .select()
      .single()

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to create subscription group' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        data,
        message: 'Subscription group created successfully'
      }),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error creating subscription group:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to create subscription group' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function updateSubscriptionGroup(supabaseClient: any, userId: string, groupId: string, groupData: any) {
  try {
    const { data, error } = await supabaseClient
      .from('subscription_groups')
      .update({
        group_name: groupData.group_name,
        group_color: groupData.group_color,
        display_order: groupData.display_order
      })
      .eq('id', groupId)
      .eq('user_id', userId)
      .select()
      .single()

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to update subscription group' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        data,
        message: 'Subscription group updated successfully'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error updating subscription group:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to update subscription group' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function deleteSubscriptionGroup(supabaseClient: any, userId: string, groupId: string) {
  try {
    // First, remove all items from the group
    await supabaseClient
      .from('subscription_group_items')
      .delete()
      .eq('group_id', groupId)

    // Then delete the group
    const { error } = await supabaseClient
      .from('subscription_groups')
      .delete()
      .eq('id', groupId)
      .eq('user_id', userId)

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to delete subscription group' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Subscription group deleted successfully'
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error deleting subscription group:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to delete subscription group' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function updateUserActivity(supabaseClient: any, userId: string, activityType: string, activityData: any) {
  try {
    const expPoints = activityType === 'subscription_create' ? 5 : 1
    
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