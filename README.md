# Study Plan

A small, mobile-friendly study journal. The site is a static GitHub Pages app; study entries are stored in Supabase and scoped to the signed-in user.

## Set up Supabase

1. Create a Supabase project.
2. In **SQL Editor**, run [`supabase/schema.sql`](supabase/schema.sql) once. It creates the study log table and row-level security policies.
3. In **Project Settings → API**, copy the **Project URL** and the **publishable key** (or legacy `anon` key).
4. Paste those two values into [`supabase-config.js`](supabase-config.js). Never use a `secret` or `service_role` key in this browser app.
5. In **Authentication → URL Configuration**, set the Site URL and add the GitHub Pages address to Redirect URLs:
   - `https://dalani200.github.io/studyplan/`

Email and password sign-in must be enabled in Supabase Auth. New accounts may need to confirm their email once, depending on the project's email confirmation setting. Existing email-link accounts can use **비밀번호 설정 / 재설정** on the login screen to set a password through a one-time email link.

## Publish on GitHub Pages

1. Push `index.html`, `supabase-config.js`, and the `supabase/` folder to the repository's `main` branch.
2. Open the repository's **Settings → Pages** and choose **Deploy from a branch**, branch `main`, folder `/(root)`.
3. After GitHub Pages finishes publishing, open `https://dalani200.github.io/studyplan/` and sign in with your email and password.

Only entries belonging to the signed-in Supabase user are readable or editable. The publishable key is intended for browser apps; the SQL policies protect the data. The app refreshes entries when opened or when **새로고침** is pressed.
