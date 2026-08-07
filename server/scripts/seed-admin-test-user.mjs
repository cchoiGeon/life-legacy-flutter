import bcrypt from 'bcryptjs';
import pg from 'pg';

const loginId = 'admintest1234@gmail.com';
const password = 'a1234567!';

const client = new pg.Client({
  host: '127.0.0.1',
  port: 5432,
  user: 'postgres',
  password: 'postgres',
  database: 'life_legacy',
});

await client.connect();
const hash = await bcrypt.hash(password, 10);

const existing = await client.query(
  'SELECT id, login_id FROM app_user WHERE login_id = $1',
  [loginId],
);

if (existing.rows.length) {
  await client.query(
    `UPDATE app_user
     SET password_hash = $1,
         deleted_at = NULL,
         name = COALESCE(NULLIF(name, ''), $2),
         intro_completed_at = COALESCE(intro_completed_at, NOW()),
         updated_at = NOW()
     WHERE login_id = $3`,
    [hash, 'Admin Test', loginId],
  );
  console.log('UPDATED', existing.rows[0].id);
} else {
  const r = await client.query(
    `INSERT INTO app_user (
       id, phone, name, login_id, password_hash,
       child_linked, intro_completed_at, created_at, updated_at
     ) VALUES (
       gen_random_uuid(), NULL, $1, $2, $3,
       false, NOW(), NOW(), NOW()
     )
     RETURNING id, login_id`,
    ['Admin Test', loginId, hash],
  );
  console.log('CREATED', r.rows[0]);
}

await client.end();
