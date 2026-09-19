// supabase/functions/self-checkin/index.ts
//
// Edge Function PUBLIK (tidak perlu login) untuk member melakukan
// check-in mandiri dengan nomor HP saja. Pakai service_role key di sisi
// server supaya bisa mencari data member & insert check-in walau
// pemanggilnya tidak punya sesi login sama sekali — TAPI cuma
// mengembalikan data seperlunya (nama, nama paket, tanggal berakhir),
// TIDAK pernah mengembalikan data sensitif member lain atau daftar
// member sama sekali.

import { serve } from 'https://deno.land/std@0.192.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { phone, pin } = await req.json();
    const normalizedPhone = String(phone ?? '').trim();
    const normalizedPin = String(pin ?? '').trim();

    if (!normalizedPhone) {
      return new Response(JSON.stringify({ error: 'Nomor HP wajib diisi' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: member, error: findError } = await adminClient
      .from('members')
      .select('id, name, phone, pin, package_name, membership_end_date')
      .eq('phone', normalizedPhone)
      .limit(1)
      .maybeSingle();

    if (findError) throw findError;

    // Pesan error SENGAJA sama persis untuk "nomor tidak ditemukan" dan
    // "PIN salah" — supaya orang tidak bisa dipakai untuk menebak-nebak
    // nomor HP mana saja yang terdaftar sebagai member (mencegah
    // enumeration attack).
    const genericError = {
      error: 'Nomor HP atau PIN tidak sesuai. Periksa kembali atau hubungi staf gym.',
    };

    if (!member) {
      return new Response(JSON.stringify(genericError), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Kalau member ini punya PIN terdaftar, PIN WAJIB dicocokkan.
    // Kalau member belum punya PIN (kolom pin NULL), boleh check-in
    // cuma dengan nomor HP saja (mode lama, backward-compatible).
    if (member.pin && member.pin !== normalizedPin) {
      return new Response(JSON.stringify(genericError), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Catat check-in — checked_in_by dikosongkan (null) karena ini
    // dilakukan mandiri oleh member, bukan oleh staf.
    const { error: insertError } = await adminClient.from('check_ins').insert({
      member_id: member.id,
      member_name: member.name,
      checked_in_by: null,
      notes: 'Self check-in (tanpa login)',
    });

    if (insertError) throw insertError;

    const endDate = new Date(member.membership_end_date);
    const now = new Date();
    const daysLeft = Math.ceil((endDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
    const status = daysLeft < 0 ? 'expired' : daysLeft <= 7 ? 'expiring_soon' : 'active';

    return new Response(
      JSON.stringify({
        success: true,
        memberName: member.name,
        packageName: member.package_name,
        membershipEndDate: member.membership_end_date,
        status,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
