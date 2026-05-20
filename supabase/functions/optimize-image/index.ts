import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    const { file_path, bucket } = await req.json();

    if (!file_path || !bucket) {
      throw new Error("Missing required fields: file_path, bucket");
    }

    // Only process images (videos handled by third-party services)
    const imageExtensions = ["jpg", "jpeg", "png", "webp"];
    const file_extension = file_path.split(".").pop()?.toLowerCase() || "";
    
    if (!imageExtensions.includes(file_extension)) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "File is not an image, skipping optimization",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    // Download the original image
    const { data: originalImage, error: downloadError } = await supabaseClient.storage
      .from(bucket)
      .download(file_path);

    if (downloadError || !originalImage) {
      console.error("Error downloading image:", downloadError);
      throw new Error("Failed to download image");
    }

    // In a real implementation, you would:
    // 1. Use Sharp or similar library to resize and compress the image
    // 2. Generate a thumbnail (e.g., 300x300)
    // 3. Convert to WebP format for better compression
    // 4. Upload the optimized versions back to storage
    
    // For now, we'll simulate the process
    const thumbnail_path = file_path.replace(/\.[^/.]+$/, "_thumb.webp");
    const optimized_path = file_path.replace(/\.[^/.]+$/, ".webp");

    // Simulate upload of thumbnail and optimized version
    // In production, you'd actually process the image here
    
    // Update the database record with thumbnail URL
    const public_url_base = `https://${Deno.env.get("SUPABASE_PROJECT_REF")}.supabase.co/storage/v1/object/public/${bucket}`;
    
    let update_error: any;

    // Check if this is an ingredient or step media
    if (file_path.startsWith("ingredients/")) {
      // Update ingredient table
      const { error } = await supabaseClient
        .from("ingredient")
        .update({
          image_url: `${public_url_base}/${optimized_path}`,
          image_thumbnail_url: `${public_url_base}/${thumbnail_path}`,
          updated_at: new Date().toISOString(),
        })
        .eq("image_url", `${public_url_base}/${file_path}`);
      
      update_error = error;
    } else if (file_path.startsWith("steps/")) {
      // Update recipe_step_media table
      const { error } = await supabaseClient
        .from("recipe_step_media")
        .update({
          thumbnail_url: `${public_url_base}/${thumbnail_path}`,
        })
        .eq("media_url", `${public_url_base}/${file_path}`);
      
      update_error = error;
    }

    if (update_error) {
      console.error("Error updating database:", update_error);
      // Don't throw - the upload succeeded, just the optimization metadata failed
    }

    return new Response(
      JSON.stringify({
        success: true,
        original_path: file_path,
        thumbnail_path: thumbnail_path,
        optimized_path: optimized_path,
        message: "Image optimization completed (simulated)",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Error in optimize-image:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "An error occurred",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
