import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const apiKey = Deno.env.get('GEMINI_API_KEY')?.trim()
    if (!apiKey) throw new Error("Missing GEMINI_API_KEY")

    const { topic } = await req.json()

    // 👇 FIXED: We are using the exact model name from your log
    const modelName = "gemini-2.5-flash" 
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`

    const requestBody = {
      contents: [{
        parts: [{
          text: `Create a short study quiz about: ${topic}. 
                 Return ONLY raw JSON. Do not use Markdown. 
                 Format: { "questions": [ { "question": "...", "options": ["..."], "answer": "..." } ] }`
        }]
      }]
    }

    const googleResponse = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody)
    })

    const data = await googleResponse.json()

    if (!googleResponse.ok) {
        throw new Error(`Google Error: ${data.error?.message || JSON.stringify(data)}`)
    }

    // Extract text
    let generatedText = data.candidates?.[0]?.content?.parts?.[0]?.text || ""

    // 🧹 CLEANUP: Remove ```json and ``` if Google adds them
    generatedText = generatedText.replace(/```json/g, "").replace(/```/g, "").trim()

    return new Response(
      JSON.stringify({ content: generatedText }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})