# Flutter Supabase App

## Security Setup

### Environment Variables
1. Copy `.env.example` to `.env`
2. Add your Supabase credentials to `.env`
3. Never commit `.env` to version control

### Security Best Practices Implemented

1. **Environment Variables**: Credentials stored in `.env` file (gitignored)
2. **No Hardcoded Secrets**: All sensitive data loaded from environment
3. **Row Level Security**: Enable RLS on all Supabase tables
4. **Authentication**: Use Supabase auth for user management
5. **HTTPS Only**: All API calls use secure connections

### Additional Security Recommendations

#### On Supabase Dashboard:
- Enable Row Level Security (RLS) on all tables
- Set up proper authentication policies
- Use service role key only on backend/server
- Enable email verification for sign-ups
- Configure allowed redirect URLs

#### In Your App:
- Validate all user inputs
- Use parameterized queries (Supabase does this by default)
- Implement proper error handling
- Add rate limiting for sensitive operations
- Use secure storage for tokens (Supabase Flutter handles this)

## Setup

```bash
flutter pub get
flutter run
```

## Building for Production

See [BUILD_RELEASE.md](BUILD_RELEASE.md) for instructions on building obfuscated release versions.

**Code obfuscation is configured and ready!** When you build for release, your code will be automatically obfuscated.
