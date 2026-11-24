import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    })
  }

  try {
    const { message } = await req.json()

    if (!message) {
      return new Response(
        JSON.stringify({ error: "No message provided" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      )
    }

    const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY")

    if (!GROQ_API_KEY) {
      return new Response(
        JSON.stringify({ error: "GROQ_API_KEY not set" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      )
    }

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "llama3-8b-8192",
        messages: [
          {
            role: "system",
            content: `You are Exora, a focused, friendly, and brilliant AI study assistant.
STRICT TOPIC POLICY (STUDY & ACADEMICS ONLY):
You must ONLY answer questions and discuss topics that are directly related to studying, academics, education, homework, exam preparation, and learning concepts.
If the user asks about ANYTHING unrelated to studying, education, or learning (e.g., entertainment, pop culture, celebrity gossip, gaming, dating, sports scores, politics, or casual non-academic chit-chat), you must politely and firmly decline to answer and guide them back to their studies.`
          },
          {
            role: "user",
            content: message
          }
        ],
        temperature: 0.7,
        max_tokens: 200,
      })
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error("Groq API error:", errorText)
      return new Response(
        JSON.stringify({ error: "AI service error", detail: errorText }),
        { status: 502, headers: { "Content-Type": "application/json" } }
      )
    }

    const data = await response.json()
    const reply = data.choices?.[0]?.message?.content ?? "I'm sorry, I couldn't generate a response right now."

    return new Response(
      JSON.stringify({ reply }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        }
      }
    )
  } catch (error) {
    console.error("Edge function error:", error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    )
  }
})
