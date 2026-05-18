import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const apiKey = Deno.env.get('GROQ_API_KEY')?.trim()
    if (!apiKey) throw new Error("Missing GROQ_API_KEY")

    // 1. Grab ALL the variables your Swift app sends
    const { topic, type, count, difficulty } = await req.json()

    // 2. Determine what instructions to give the AI based on the 'type' variable
    const requestedType = (type || "").toLowerCase()
    let instructions = ""

    if (requestedType.includes("note")) {
      instructions = "Format: Comprehensive Academic Notes in Markdown. Use # for Title, ## for subtopics. DO NOT output a quiz. DO NOT output JSON."
    } else if (requestedType.includes("cheat")) {
      instructions = "Format: Quick-glance Cheatsheet in Markdown. Focus on key definitions and use tables. DO NOT output a quiz. DO NOT output JSON."
    } else if (requestedType.includes("index")) {
      instructions = "Format: Topic Index in Markdown. List the main themes with a 1-sentence summary for each. DO NOT output a quiz. DO NOT output JSON."
    } else if (requestedType.includes("flashcard")) {
      instructions = `Format: RAW JSON ONLY. Create ${count || 10} flashcards. Format exactly: { "flashcards": [ { "front": "Term", "back": "Definition" } ] }`
    } else {
      // Fallback to Quiz
      instructions = `Format: RAW JSON ONLY. Create a multiple-choice quiz with ${count || 5} questions. Format exactly: { "questions": [ { "question": "...", "options": ["A","B","C","D"], "answer": "A", "hint": "..." } ] }`
    }

    // 3. Combine the raw document text with our strict instructions
    const finalPrompt = `
    CONTEXT / TEXT TO ANALYZE:
    ${topic}

    STRICT INSTRUCTIONS:
    ${instructions}
    `

    const url = "https://api.groq.com/openai/v1/chat/completions"

    const requestBody = {
      model: "llama-3.3-70b-versatile", // Valid Groq model. You can change this to llama3-8b-8192 or mixtral-8x7b-32768
      messages: [
        {
          role: "system",
          content: "You are a highly intelligent and helpful AI tutor."
        },
        {
          role: "user",
          content: finalPrompt
        }
      ],
      temperature: 0.7
    }

    const groqResponse = await fetch(url, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify(requestBody)
    })

    const data = await groqResponse.json()

    if (!groqResponse.ok) {
      throw new Error(`Groq Error: ${data.error?.message || JSON.stringify(data)}`)
    }

    let generatedText = data.choices?.[0]?.message?.content || ""

    // Clean up Markdown JSON ticks if they appear
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