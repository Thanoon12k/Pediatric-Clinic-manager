// Deploy with `supabase functions deploy provision-staff` after applying
// database migrations 001 → 002 → 003 → 004. Never embed service role in APK.
// Called only by an authenticated admin (create/reset doctors) or a doctor
// (create/reset their own secretary). Usernames are case-insensitive ASCII.
import { createClient } from 'npm:@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, x-client-info, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json; charset=utf-8',
};
const domain = 'staff.yadati.invalid';
const usernamePattern = /^[a-z][a-z0-9_]{3,23}$/;
const respond = (status: number, data: unknown) =>
  new Response(JSON.stringify(data), { status, headers: cors });

const normalize = (value: unknown) =>
  typeof value === 'string' ? value.trim().toLowerCase() : '';
const staffEmail = (username: string) => `${username}@${domain}`;

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') return new Response('', { headers: cors });
  if (request.method !== 'POST') return respond(405, { error: 'Method not allowed' });

  const url = Deno.env.get('SUPABASE_URL');
  const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceRole) {
    return respond(500, { error: 'Server not configured' });
  }

  // Verify token against Auth, not merely client-provided metadata/role.
  const authorization = request.headers.get('Authorization') ?? '';
  const token = /^Bearer (.+)$/i.exec(authorization)?.[1];
  if (!token) return respond(401, { error: 'Sign in first' });

  const admin = createClient(url, serviceRole, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: authenticated, error: authError } = await admin.auth.getUser(token);
  const userId = authenticated.user?.id;
  if (authError || !userId) return respond(401, { error: 'Invalid session' });

  const { data: profile, error: profileError } = await admin
    .from('profiles').select('role').eq('id', userId).single();
  if (profileError || !profile || !['admin', 'doctor'].includes(profile.role)) {
    return respond(403, { error: 'Account provisioning not permitted' });
  }

  let doctorId: string | null = null;
  if (profile.role === 'doctor') {
    const { data: doctor, error: doctorError } = await admin.from('doctors')
      .select('id').eq('user_id', userId).eq('is_active', true).maybeSingle();
    if (doctorError || !doctor) return respond(403, { error: 'Doctor is inactive' });
    doctorId = doctor.id;
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return respond(400, { error: 'Invalid JSON body' });
  }

  const action = body.action === 'reset_password' ? 'reset_password' : 'create';
  const username = normalize(body.username);
  const password = typeof body.password === 'string' ? body.password : '';
  const fullName = typeof body.full_name === 'string' ? body.full_name.trim() : '';

  if (!usernamePattern.test(username)) {
    return respond(400, { error: 'Username must be 4–24 lower-case Latin characters, digits or underscores, starting with a letter' });
  }
  if (password.length < 12 || password.length > 128) {
    return respond(400, { error: 'Password must be 12–128 characters' });
  }

  if (action === 'reset_password') {
    const { data: target, error: targetError } = await admin.from('staff_usernames')
      .select('user_id').eq('username', username).maybeSingle();
    if (targetError) return respond(500, { error: 'Staff lookup failed' });
    if (!target) return respond(404, { error: 'Account not found' });

    const { data: targetRole, error: roleError } = await admin.from('profiles')
      .select('role').eq('id', target.user_id).single();
    if (roleError || !targetRole) return respond(404, { error: 'Staff profile missing' });

    if (profile.role === 'admin') {
      if (targetRole.role !== 'doctor') return respond(403, { error: 'Admins may reset doctor accounts only' });
    } else {
      if (targetRole.role !== 'secretary') return respond(403, { error: 'Doctors may reset their secretaries only' });
      const { data: secretary, error: assignmentError } = await admin.from('secretary_assignments')
        .select('user_id').eq('user_id', target.user_id).eq('doctor_id', doctorId!)
        .eq('is_active', true).maybeSingle();
      if (assignmentError || !secretary) return respond(403, { error: 'This secretary is not assigned to you' });
    }
    const { error } = await admin.auth.admin.updateUserById(target.user_id, { password });
    if (error) return respond(400, { error: 'Password reset failed' });
    return respond(200, { ok: true, username, action });
  }

  // Only admins create doctors. Only active doctors create their own secretary.
  const newRole = profile.role === 'admin' ? 'doctor' : 'secretary';
  if (fullName.length < 2 || fullName.length > 120) {
    return respond(400, { error: 'Full name must be 2–120 characters' });
  }
  const specialty = typeof body.specialty === 'string'
    ? body.specialty.trim().slice(0, 100) : '';

  const { data: existing, error: duplicateLookupError } = await admin
    .from('staff_usernames').select('user_id').eq('username', username).maybeSingle();
  if (duplicateLookupError) return respond(500, { error: 'Username check failed' });
  if (existing) return respond(409, { error: 'Username already taken' });

  const { data: creation, error: createError } = await admin.auth.admin.createUser({
    email: staffEmail(username),
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName },
  });
  if (createError || !creation.user) {
    return respond(400, { error: 'Cannot create staff account; choose another username' });
  }

  const newUserId = creation.user.id;
  try {
    const { error: userError } = await admin.from('staff_usernames').insert({
      user_id: newUserId, username, created_by: userId,
    });
    if (userError) throw new Error('Username registration failed');

    // Trigger from migration 002 creates a default patient profile.
    // This trusted server update is the only supported privileged promotion.
    const { data: upgraded, error: upgradeError } = await admin.from('profiles')
      .update({ role: newRole, full_name: fullName })
      .eq('id', newUserId).eq('role', 'patient').select('id').single();
    if (upgradeError || !upgraded) throw new Error('Profile upgrade failed');

    if (newRole === 'doctor') {
      const { error } = await admin.from('doctors').insert({
        user_id: newUserId, full_name: fullName, specialty: specialty || null,
        email: staffEmail(username), is_active: true,
      });
      if (error) throw new Error('Doctor record creation failed');
    } else {
      const { error } = await admin.from('secretary_assignments').insert({
        user_id: newUserId, doctor_id: doctorId, is_active: true,
      });
      if (error) throw new Error('Secretary assignment failed');
    }
  } catch {
    // Clean up partially-created auth user (cascades to profile, doctor,
    // username mapping and assignment); no privileged orphan accounts.
    await admin.auth.admin.deleteUser(newUserId);
    return respond(500, { error: 'Account setup failed. Nothing was activated. Check server logs.' });
  }

  return respond(201, {
    ok: true, role: newRole, username, full_name: fullName,
    user_id: newUserId,
  });
});
