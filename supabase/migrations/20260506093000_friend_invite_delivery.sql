-- Migration: friend invite delivery status
-- Lets the app send invite emails synchronously while the existing webhook path
-- stays idempotent and can ignore rows already handled by the app.

alter table public.friend_invites
    add column if not exists email_delivery_status text not null default 'pending'
        check (email_delivery_status in ('pending', 'sending', 'sent', 'failed')),
    add column if not exists email_sent_at timestamptz,
    add column if not exists email_delivery_error text;

comment on column public.friend_invites.email_delivery_status is
    'Transactional delivery state for the invite email. Webhook dispatch ignores rows already handled by the app.';
comment on column public.friend_invites.email_sent_at is
    'Set when Resend confirms delivery of the invite email.';
comment on column public.friend_invites.email_delivery_error is
    'Last delivery error returned by the invite email sender.';
