import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RecommendationRequest {
  action: 'get_recommendations' | 'refresh_recommendations' | 'get_algorithms'
  content_type?: 'character' | 'audio' | 'creation' | 'all'
  algorithm_type?: 'collaborative' | 'content_based' | 'hybrid'
  limit?: number
  force_refresh?: boolean
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

    const requestBody: RecommendationRequest = await req.json()
    const { action, content_type = 'all', algorithm_type, limit = 10, force_refresh = false } = requestBody

    switch (action) {
      case 'get_recommendations':
        return await getRecommendations(supabaseClient, user.id, content_type, limit, force_refresh)
      
      case 'refresh_recommendations':
        return await refreshRecommendations(supabaseClient, user.id, content_type, limit)
      
      case 'get_algorithms':
        return await getRecommendationAlgorithms(supabaseClient, algorithm_type)
      
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

async function getRecommendations(
  supabaseClient: any, 
  userId: string, 
  contentType: string, 
  limit: number, 
  forceRefresh: boolean
) {
  try {
    // Check for existing cached recommendations
    if (!forceRefresh) {
      const { data: cached, error: cacheError } = await supabaseClient
        .from('user_recommendations')
        .select('*')
        .eq('user_id', userId)
        .eq('content_type', contentType)
        .gt('expires_at', new Date().toISOString())
        .order('created_at', { ascending: false })
        .limit(1)

      if (!cacheError && cached && cached.length > 0) {
        return new Response(
          JSON.stringify({
            success: true,
            data: {
              recommendations: cached[0].recommended_items,
              algorithm_version: cached[0].algorithm_version,
              confidence_score: cached[0].confidence_score,
              cached: true,
              expires_at: cached[0].expires_at
            }
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Generate new recommendations
    return await generateRecommendations(supabaseClient, userId, contentType, limit)
  } catch (error) {
    console.error('Error getting recommendations:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to get recommendations' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function generateRecommendations(
  supabaseClient: any, 
  userId: string, 
  contentType: string, 
  limit: number
) {
  try {
    // Get user preferences and history
    const userProfile = await getUserProfile(supabaseClient, userId)
    
    let recommendations = []
    let algorithmVersion = 'v1.0'
    let confidenceScore = 0.0

    switch (contentType) {
      case 'character':
        recommendations = await generateCharacterRecommendations(supabaseClient, userProfile, limit)
        confidenceScore = 0.85
        break
      
      case 'audio':
        recommendations = await generateAudioRecommendations(supabaseClient, userProfile, limit)
        confidenceScore = 0.78
        break
      
      case 'creation':
        recommendations = await generateCreationRecommendations(supabaseClient, userProfile, limit)
        confidenceScore = 0.72
        break
      
      default:
        // Mixed recommendations
        const charRecs = await generateCharacterRecommendations(supabaseClient, userProfile, Math.ceil(limit / 3))
        const audioRecs = await generateAudioRecommendations(supabaseClient, userProfile, Math.ceil(limit / 3))
        const creationRecs = await generateCreationRecommendations(supabaseClient, userProfile, Math.floor(limit / 3))
        
        recommendations = [
          ...charRecs.map((r: any) => ({ ...r, type: 'character' })),
          ...audioRecs.map((r: any) => ({ ...r, type: 'audio' })),
          ...creationRecs.map((r: any) => ({ ...r, type: 'creation' }))
        ]
        confidenceScore = 0.75
        break
    }

    // Cache the recommendations
    const expiresAt = new Date(Date.now() + 6 * 60 * 60 * 1000) // 6 hours from now
    
    await supabaseClient
      .from('user_recommendations')
      .insert({
        user_id: userId,
        content_type: contentType,
        recommended_items: recommendations,
        algorithm_version: algorithmVersion,
        confidence_score: confidenceScore,
        expires_at: expiresAt.toISOString()
      })

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          recommendations,
          algorithm_version: algorithmVersion,
          confidence_score: confidenceScore,
          cached: false,
          expires_at: expiresAt.toISOString(),
          total_items: recommendations.length
        }
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error generating recommendations:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to generate recommendations' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function getUserProfile(supabaseClient: any, userId: string) {
  try {
    // Get user basic info
    const { data: user, error: userError } = await supabaseClient
      .from('users')
      .select('*')
      .eq('id', userId)
      .single()

    if (userError) {
      console.error('Error getting user:', userError)
      return { id: userId, preferences: {} }
    }

    // Get user subscriptions for preference analysis
    const { data: subscriptions, error: subError } = await supabaseClient
      .from('user_subscriptions')
      .select('target_type, tags, priority')
      .eq('user_id', userId)
      .limit(50)

    // Get user interaction logs for behavior analysis
    const { data: interactions, error: intError } = await supabaseClient
      .from('interaction_logs')
      .select('interaction_type, target_type, metadata')
      .eq('user_id', userId)
      .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()) // Last 30 days
      .limit(100)

    return {
      id: userId,
      user_data: user,
      subscriptions: subscriptions || [],
      recent_interactions: interactions || [],
      preferences: user.preferences || {}
    }
  } catch (error) {
    console.error('Error getting user profile:', error)
    return { id: userId, preferences: {} }
  }
}

async function generateCharacterRecommendations(supabaseClient: any, userProfile: any, limit: number) {
  try {
    // Analyze user's subscription patterns
    const subscribedCharacterTypes = userProfile.subscriptions
      ?.filter((s: any) => s.target_type === 'character')
      ?.flatMap((s: any) => s.tags || []) || []

    // Get popular characters with similar tags
    const { data: characters, error } = await supabaseClient
      .from('ai_characters')
      .select(`
        id,
        name,
        description,
        avatar_url,
        category,
        tags,
        follower_count,
        rating,
        is_featured
      `)
      .eq('is_public', true)
      .eq('is_active', true)
      .order('follower_count', { ascending: false })
      .limit(limit * 3) // Get more to filter and rank

    if (error) {
      console.error('Error getting characters:', error)
      return []
    }

    // Score and rank characters
    const scoredCharacters = characters.map((char: any) => {
      let score = 0
      
      // Base popularity score
      score += Math.log(char.follower_count + 1) * 0.3
      
      // Rating score
      score += (char.rating || 0) * 0.2
      
      // Featured bonus
      if (char.is_featured) score += 0.2
      
      // Tag similarity score
      const commonTags = (char.tags || []).filter((tag: string) => 
        subscribedCharacterTypes.includes(tag)
      ).length
      score += commonTags * 0.3
      
      // Category preference (if user has patterns)
      const userCategories = userProfile.subscriptions
        ?.filter((s: any) => s.target_type === 'character')
        ?.map((s: any) => s.metadata?.category)
        ?.filter(Boolean) || []
      
      if (userCategories.includes(char.category)) {
        score += 0.25
      }

      return { ...char, recommendation_score: score }
    })

    // Sort by score and return top results
    return scoredCharacters
      .sort((a, b) => b.recommendation_score - a.recommendation_score)
      .slice(0, limit)
      .map(char => ({
        id: char.id,
        name: char.name,
        description: char.description,
        avatar_url: char.avatar_url,
        category: char.category,
        tags: char.tags,
        follower_count: char.follower_count,
        rating: char.rating,
        recommendation_score: char.recommendation_score,
        reason: generateRecommendationReason(char, userProfile)
      }))
  } catch (error) {
    console.error('Error generating character recommendations:', error)
    return []
  }
}

async function generateAudioRecommendations(supabaseClient: any, userProfile: any, limit: number) {
  try {
    // Implementation for audio recommendations
    // This would follow similar pattern to character recommendations
    // but focus on audio content preferences and listening history
    
    const { data: audios, error } = await supabaseClient
      .from('audio_contents')
      .select('*')
      .eq('is_public', true)
      .order('play_count', { ascending: false })
      .limit(limit)

    if (error) {
      console.error('Error getting audio content:', error)
      return []
    }

    return audios.map((audio: any) => ({
      ...audio,
      recommendation_score: Math.random() * 0.5 + 0.5, // Placeholder scoring
      reason: 'Popular content in your preferred categories'
    }))
  } catch (error) {
    console.error('Error generating audio recommendations:', error)
    return []
  }
}

async function generateCreationRecommendations(supabaseClient: any, userProfile: any, limit: number) {
  try {
    // Implementation for creation/discovery content recommendations
    const { data: creations, error } = await supabaseClient
      .from('creation_items')
      .select('*')
      .eq('status', 'published')
      .order('like_count', { ascending: false })
      .limit(limit)

    if (error) {
      console.error('Error getting creation content:', error)
      return []
    }

    return creations.map((creation: any) => ({
      ...creation,
      recommendation_score: Math.random() * 0.5 + 0.5, // Placeholder scoring
      reason: 'Trending content from creators you might like'
    }))
  } catch (error) {
    console.error('Error generating creation recommendations:', error)
    return []
  }
}

function generateRecommendationReason(item: any, userProfile: any): string {
  const reasons = []
  
  if (item.is_featured) {
    reasons.push('featured content')
  }
  
  if (item.follower_count > 1000) {
    reasons.push('popular choice')
  }
  
  if (item.tags && userProfile.subscriptions) {
    const commonTags = item.tags.filter((tag: string) => 
      userProfile.subscriptions.some((s: any) => s.tags?.includes(tag))
    )
    if (commonTags.length > 0) {
      reasons.push(`matches your interests in ${commonTags.slice(0, 2).join(', ')}`)
    }
  }
  
  return reasons.length > 0 ? 
    `Recommended because: ${reasons.join(' and ')}` : 
    'Recommended based on your activity'
}

async function refreshRecommendations(
  supabaseClient: any, 
  userId: string, 
  contentType: string, 
  limit: number
) {
  try {
    // Clear existing cached recommendations
    await supabaseClient
      .from('user_recommendations')
      .delete()
      .eq('user_id', userId)
      .eq('content_type', contentType)

    // Generate fresh recommendations
    return await generateRecommendations(supabaseClient, userId, contentType, limit)
  } catch (error) {
    console.error('Error refreshing recommendations:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to refresh recommendations' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

async function getRecommendationAlgorithms(supabaseClient: any, algorithmType?: string) {
  try {
    let query = supabaseClient
      .from('recommendation_algorithms')
      .select('*')
      .eq('is_active', true)
      .order('weight', { ascending: false })

    if (algorithmType) {
      query = query.eq('algorithm_type', algorithmType)
    }

    const { data: algorithms, error } = await query

    if (error) {
      console.error('Database error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to get algorithms' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: algorithms,
        total_algorithms: algorithms.length
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error getting recommendation algorithms:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to get recommendation algorithms' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
}

/* Deno.serve(serve) */