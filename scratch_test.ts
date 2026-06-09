import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const client = createClient(
  "https://njzqcftjzskwcpforwzf.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qenFjZnRqenNrd2NwZm9yd3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0ODQzMzcsImV4cCI6MjA4ODA2MDMzN30.hnbx0os7WVRZpDP9_EmxMqFH3cN0aypQg1SvBgWtEmk"
);

async function test() {
  const { data, error } = await client
    .from("recipe")
    .select("id, creator:creator_id(user_id)")
    .limit(3);
  
  console.log("DATA:", JSON.stringify(data, null, 2));
  console.log("ERROR:", error);
}

test();
