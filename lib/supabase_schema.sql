-- Tabel profiles: terpisah dari auth.users bawaan Supabase,
-- untuk menyimpan nama & role tanpa mengubah tabel auth internal.
create table public.profiles (
  id uuid references auth.users(id) primary key,
  email text not null,
  name text not null default '',
  role text not null check (role in ('owner', 'admin', 'staf')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Semua user yang login boleh baca profilnya sendiri (untuk cek role saat startup app).
create policy "user bisa baca profil sendiri"
  on public.profiles for select
  using (auth.uid() = id);

-- Contoh RLS untuk tabel members: admin & owner boleh insert/update,
-- staf hanya boleh select (baca).
-- create table public.members (...);
-- alter table public.members enable row level security;
--
-- create policy "owner_admin bisa kelola member"
--   on public.members for all
--   using (
--     exists (
--       select 1 from public.profiles
--       where id = auth.uid() and role in ('owner', 'admin')
--     )
--   );
--
-- create policy "staf bisa lihat member"
--   on public.members for select
--   using (
--     exists (
--       select 1 from public.profiles
--       where id = auth.uid() and role in ('owner', 'admin', 'staf')
--     )
--   );

-- Catatan: aturan role di UserRoleX.canAccess() (Flutter) hanya untuk
-- UX (tampil/sembunyikan menu). Keamanan sebenarnya harus ditegakkan
-- lewat RLS policy seperti di atas, karena request bisa saja langsung
-- ke Supabase API tanpa lewat app.
