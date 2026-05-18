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
            content: `You are an elite Williams-Sonoma AI Design Consultant and personal shopping assistant. 
Your role is to help customers find the perfect premium kitchenware, cookware, and home decor products. 
You are knowledgeable, warm, and luxurious in your tone.
Keep responses concise (under 3 sentences) and always try to recommend a specific product category or item.
Our top product categories include: Cookware (Le Creuset, All-Clad), Cutlery, Bakeware, Small Appliances, 
Tableware, and Home Decor. When relevant, suggest adding items to their registry or cart.`
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
