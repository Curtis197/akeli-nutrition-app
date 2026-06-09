async function test() {
  const url = 'https://njzqcftjzskwcpforwzf.supabase.co/rest/v1/allergen?select=id,slug,label:label_fr&limit=1';
  const res = await fetch(url, {
    headers: {
      'apikey': 'sb_publishable_2WUTLXygeO3s1FTvBdydwA_24zE-a6R',
      'Authorization': 'Bearer sb_publishable_2WUTLXygeO3s1FTvBdydwA_24zE-a6R'
    }
  });
  const data = await res.json();
  console.log(data);
}
test();
