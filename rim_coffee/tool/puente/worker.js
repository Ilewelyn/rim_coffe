// Puente para Rim Coffee (Cloudflare Worker "rim-coffee-api"):
// reenvía todo a Supabase. Sirve en redes que bloquean supabase.co.
const DESTINO = "xnacwcvgjqzplwmuybgh.supabase.co";

export default {
  async fetch(request) {
    const url = new URL(request.url);
    url.protocol = "https:";
    url.hostname = DESTINO;
    url.port = "";
    return fetch(new Request(url, request));
  },
};
