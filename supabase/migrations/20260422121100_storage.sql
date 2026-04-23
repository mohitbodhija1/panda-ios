-- Migration: storage buckets and policies
-- Three buckets:
--   avatars             - profile photos (public read, owner write)
--   group-avatars       - group photos (public read, owner-of-group write)
--   expense-attachments - receipts (private; access via signed URLs)
--
-- Object paths (convention):
--   avatars/<user_id>/<filename>
--   group-avatars/<group_id>/<filename>
--   expense-attachments/<expense_id>/<filename>

insert into storage.buckets (id, name, public)
values
    ('avatars',             'avatars',             true),
    ('group-avatars',       'group-avatars',       true),
    ('expense-attachments', 'expense-attachments', false)
on conflict (id) do nothing;

-- ============================================================================
-- avatars: anyone may read; owner may write/update/delete their own folder.
-- ============================================================================
drop policy if exists "avatars read"  on storage.objects;
drop policy if exists "avatars write" on storage.objects;

create policy "avatars read" on storage.objects
    for select to anon, authenticated
    using (bucket_id = 'avatars');

create policy "avatars write" on storage.objects
    for all to authenticated
    using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- ============================================================================
-- group-avatars: anyone may read; only group owner may write.
-- ============================================================================
drop policy if exists "group avatars read"  on storage.objects;
drop policy if exists "group avatars write" on storage.objects;

create policy "group avatars read" on storage.objects
    for select to anon, authenticated
    using (bucket_id = 'group-avatars');

create policy "group avatars write" on storage.objects
    for all to authenticated
    using (
        bucket_id = 'group-avatars'
        and public.is_group_owner(((storage.foldername(name))[1])::uuid)
    )
    with check (
        bucket_id = 'group-avatars'
        and public.is_group_owner(((storage.foldername(name))[1])::uuid)
    );

-- ============================================================================
-- expense-attachments: private; participant may read and upload.
-- ============================================================================
drop policy if exists "expense attachments read"   on storage.objects;
drop policy if exists "expense attachments insert" on storage.objects;
drop policy if exists "expense attachments delete" on storage.objects;

create policy "expense attachments read" on storage.objects
    for select to authenticated
    using (
        bucket_id = 'expense-attachments'
        and public.is_expense_participant(((storage.foldername(name))[1])::uuid)
    );

create policy "expense attachments insert" on storage.objects
    for insert to authenticated
    with check (
        bucket_id = 'expense-attachments'
        and public.is_expense_participant(((storage.foldername(name))[1])::uuid)
    );

create policy "expense attachments delete" on storage.objects
    for delete to authenticated
    using (
        bucket_id = 'expense-attachments'
        and exists (
            select 1 from public.expense_attachments a
             where a.expense_id = ((storage.foldername(name))[1])::uuid
               and a.storage_path = name
               and a.uploaded_by = auth.uid()
        )
    );
