import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface InteractionMenuRequest {
  page_type: 'ai_interaction' | 'grid_recommendation'
  action?: 'get' | 'log_interaction'
  interaction_data?: {
    interaction_type: string
    target_type?: string
    target_id?: string
    metadata?: Record<string, any>
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
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

    // Get user from JWT token
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const requestBody: InteractionMenuRequest = await req.json()
    const { page_type, action = 'get', interaction_data } = requestBody

    switch (action) {
      case 'get':
        return await getInteractionMenuConfig(supabaseClient, page_type)
      
      case 'log_interaction':
        if (!interaction_data) {
          return new Response(
            JSON.stringify({ error: 'Missing interaction_data' }),
            { 
              status: 400, 
              headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
            }
          )
        }
        return await logInteraction(supabaseClient, user.id, page_type, interaction_data)
      
      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action' }),
          { 
            status: 400, 
            headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
          }
        )
    }
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function getInteractionMenuConfig(supabaseClient: any, pageType: string) {
  try {
    const { data, error } = await supabaseClient
      .from('interaction_menu_configs')
      .select('*')
      .eq('page_type', pageType)
      .eq('is_active', true)
      .order('display_order')

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Database query failed' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Transform menu items for frontend consumption
    const menuConfigs = data.map((config: any) => ({
      id: config.id,
      page_type: config.page_type,
      menu_items: config.menu_items,
      display_order: config.display_order,
      created_at: config.created_at,
      updated_at: config.updated_at
    }))

    return new Response(
      JSON.stringify({
        success: true,
        data: menuConfigs,
        page_type: pageType,
        total_configs: menuConfigs.length
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('Error getting interaction menu config:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to get interaction menu config' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
}

async function logInteraction(
  supabaseClient: any, 
  userId: string, 
  pageType: string, 
  interactionData: any
) {
  try {
    const { error } = await supabaseClient
      .from('interaction_logs')
      .insert({
        user_id: userId,
        page_type: pageType,
        interaction_type: interactionData.interaction_type,
        target_type: interactionData.target_type,
        target_id: interactionData.target_id,
        metadata: interactionData.metadata || {}
      })

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to log interaction' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Update user activity for gamification
    await updateUserActivity(supabaseClient, userId, 'interaction', {
      page_type: pageType,
      interaction_type: interactionData.interaction_type
    })

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Interaction logged successfully'
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  } catch (error) {
    console.error('Error logging interaction:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to log interaction' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
}

async function updateUserActivity(
  supabaseClient: any, 
  userId: string, 
  activityType: string, 
  activityData: any
) {
  try {
    // Get current user experience points
    const { data: userData, error: userError } = await supabaseClient
      .from('users')
      .select('experience_points')
      .eq('id', userId)
      .single()

    if (userError) {
      console.error('Error getting user data:', userError)
      return
    }

    // Calculate experience points based on activity type
    const expPoints = calculateExperiencePoints(activityType, activityData)
    
    // Update user experience points
    const { error: updateError } = await supabaseClient
      .from('users')
      .update({ 
        experience_points: (userData.experience_points || 0) + expPoints 
      })
      .eq('id', userId)

    if (updateError) {
      console.error('Error updating user experience:', updateError)
    }
  } catch (error) {
    console.error('Error updating user activity:', error)
  }
}

function calculateExperiencePoints(activityType: string, activityData: any): number {
  const basePoints = {
    'interaction': 1,
    'voice_call': 5,
    'image_share': 3,
    'gift_send': 10
  }

  let points = basePoints[activityType as keyof typeof basePoints] || 1

  // Bonus points for specific interaction types
  if (activityData.interaction_type === 'voice_call') {
    points += 4
  } else if (activityData.interaction_type === 'gift') {
    points += 9
  }

  return points
}

/* Deno.serve(serve) */