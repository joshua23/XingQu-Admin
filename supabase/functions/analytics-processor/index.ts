import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AnalyticsEvent {
  event_name: string
  event_category?: string
  properties?: Record<string, any>
  user_id?: string
  session_id?: string
  device_info?: Record<string, any>
  location_info?: Record<string, any>
  story_id?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { event_name, event_category, properties, user_id, session_id, device_info, location_info, story_id }: AnalyticsEvent = await req.json()

    // Validate required fields
    if (!event_name) {
      return new Response(
        JSON.stringify({ error: 'event_name is required' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Insert event into user_events table
    const { data: eventData, error: eventError } = await supabaseClient
      .from('user_events')
      .insert({
        event_name,
        event_category: event_category || 'general',
        properties: properties || {},
        user_id,
        session_id: session_id || `session_${Date.now()}`,
        device_info: device_info || {},
        location_info: location_info || {},
        story_id,
        event_timestamp: new Date().toISOString(),
      })

    if (eventError) {
      console.error('Error inserting event:', eventError)
      return new Response(
        JSON.stringify({ error: 'Failed to insert event', details: eventError.message }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Process real-time metrics for specific events
    if (event_name === 'membership_purchase_complete') {
      await processRevenueMetrics(supabaseClient, properties)
    }

    if (event_name === 'user_lifecycle_change') {
      await updateUserSegment(supabaseClient, user_id, properties?.new_stage)
    }

    // Update user session if session_id provided
    if (session_id && user_id) {
      await updateUserSession(supabaseClient, session_id, user_id)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        event_id: eventData?.[0]?.id,
        message: 'Event processed successfully' 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Analytics processor error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

async function processRevenueMetrics(supabaseClient: any, properties: any) {
  const amount = properties?.amount || 0
  const planType = properties?.plan_type || 'unknown'
  
  // Insert real-time revenue metric
  await supabaseClient
    .from('realtime_metrics')
    .insert({
      metric_type: 'revenue',
      time_window: '1min',
      window_start: new Date(Date.now() - 60000).toISOString(),
      window_end: new Date().toISOString(),
      metric_value: amount,
      metric_count: 1,
      dimensions: { plan_type: planType }
    })

  // Check for revenue alerts (example: if amount > 1000)
  if (amount > 1000) {
    console.log(`🚨 High-value purchase alert: ${amount} from ${planType} plan`)
    // Could trigger webhook or notification here
  }
}

async function updateUserSegment(supabaseClient: any, userId: string, newStage: string) {
  if (!userId || !newStage) return

  // Update user attributes with new lifecycle stage
  await supabaseClient
    .from('user_attributes')
    .upsert({
      user_id: userId,
      lifecycle_stage: newStage,
      updated_at: new Date().toISOString()
    })

  // Insert into user segments table
  await supabaseClient
    .from('user_segments')
    .insert({
      user_id: userId,
      segment_name: `lifecycle_${newStage}`,
      segment_type: 'lifecycle',
      criteria_data: { stage: newStage, updated_at: new Date().toISOString() }
    })
}

async function updateUserSession(supabaseClient: any, sessionId: string, userId: string) {
  // Update session with latest activity
  const { data: sessionData } = await supabaseClient
    .from('user_sessions')
    .select('*')
    .eq('id', sessionId)
    .single()

  if (sessionData) {
    // Update existing session
    await supabaseClient
      .from('user_sessions')
      .update({
        session_end: new Date().toISOString(),
        events_count: (sessionData.events_count || 0) + 1,
        updated_at: new Date().toISOString()
      })
      .eq('id', sessionId)
  } else {
    // Create new session
    await supabaseClient
      .from('user_sessions')
      .insert({
        id: sessionId,
        user_id: userId,
        session_start: new Date().toISOString(),
        events_count: 1,
        page_views: 0,
        is_first_session: false, // Could be determined by checking user's session history
        device_info: {},
        platform: 'mobile' // Could be determined from user agent
      })
  }
}