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
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization")! },
        },
      }
    );

    // Parse request body
    const { step_id, ingredient_id, media_type, file_name, content_type } = await req.json();

    if (!media_type || !file_name) {
      throw new Error("Missing required fields: media_type, file_name");
    }

    if (!step_id && !ingredient_id) {
      throw new Error("Either step_id or ingredient_id must be provided");
    }

    // Determine bucket based on media type and target
    let bucket: string;
    let folder: string;

    if (ingredient_id) {
      bucket = "ingredient-images";
      folder = "ingredients";
      
      if (media_type !== "image") {
        throw new Error("Only images are supported for ingredients");
      }
    } else if (step_id) {
      bucket = "recipe-step-media";
      folder = "steps";
      
      if (!["image", "video"].includes(media_type)) {
        throw new Error("Media type must be 'image' or 'video'");
      }
    } else {
      throw new Error("Invalid target");
    }

    // Generate unique file path
    const file_extension = file_name.split(".").pop() || "jpg";
    const unique_id = crypto.randomUUID();
    const file_path = `${folder}/${unique_id}.${file_extension}`;

    // Create signed URL for upload (valid for 5 minutes)
    const { data: signData, error: signError } = await supabaseClient.storage
      .from(bucket)
      .createSignedUploadUrl(file_path, 300); // 5 minutes

    if (signError) {
      console.error("Error creating signed URL:", signError);
      throw new Error("Failed to create upload URL");
    }

    // Prepare database insert based on target
    let db_table: string;
    let db_data: any;

    if (ingredient_id) {
      // For ingredients, we'll update the ingredient record after upload
      db_table = "ingredient";
      db_data = {
        ingredient_id,
        temp_file_path: file_path,
      };
    } else {
      // For recipe steps, create a media record
      db_table = "recipe_step_media";
      
      // Get the next display_order for this step
      const { data: existingMedia } = await supabaseClient
        .from("recipe_step_media")
        .select("display_order")
        .eq("step_id", step_id)
        .order("display_order", { ascending: false })
        .limit(1);

      const next_order = existingMedia && existingMedia.length > 0 
        ? existingMedia[0].display_order + 1 
        : 0;

      db_data = {
        id: crypto.randomUUID(),
        step_id,
        media_type,
        media_url: `https://${Deno.env.get("SUPABASE_PROJECT_REF")}.supabase.co/storage/v1/object/public/${bucket}/${file_path}`,
        thumbnail_url: null, // Will be populated by optimize-image function
        display_order: next_order,
        is_primary: next_order === 0, // First media is primary by default
      };

      // Insert the media record
      const { error: dbError } = await supabaseClient
        .from("recipe_step_media")
        .insert(db_data);

      if (dbError) {
        console.error("Error inserting media record:", dbError);
        throw new Error("Failed to create media record");
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        upload_url: signData.url,
        file_path: file_path,
        media_id: db_data.id || null,
        media_url: db_data.media_url || null,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Error in process-media-upload:", error);
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
