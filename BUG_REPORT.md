# Bug Report: Thread History Not Working with Environment Variables

## 🐛 **Problem Description**

Thread History component doesn't load data when using environment variables (`NEXT_PUBLIC_API_URL` and `NEXT_PUBLIC_ASSISTANT_ID`), despite the README documenting this as a supported configuration method.

## 🔍 **Root Cause**

**Inconsistent environment variable handling** between `StreamProvider` and `ThreadProvider`:

- ✅ **StreamProvider**: Reads env vars as fallbacks → Chat works
- ❌ **ThreadProvider**: Only reads URL query params → Thread History always empty

## 📋 **Steps to Reproduce**

1. Set environment variables in `.env`:
   ```bash
   NEXT_PUBLIC_API_URL=http://localhost:2024
   NEXT_PUBLIC_ASSISTANT_ID=your-assistant-id
   ```

2. Start the application
3. Chat functionality works (uses StreamProvider)
4. Thread History panel remains empty (uses ThreadProvider)

## 💻 **Expected vs Actual Behavior**

**Expected**: Thread History loads previous conversations using env vars
**Actual**: Thread History is always empty because ThreadProvider can't read env vars

## 🛠️ **Additional Issues Found**

While investigating, also discovered **hydration warnings** caused by browser extensions (password managers) adding attributes to form elements. This affects user experience in Safari and Chrome.

## 🌐 **Environment**

- **OS**: macOS (affects all platforms)
- **Browsers**: Safari, Chrome, Firefox (all affected)  
- **Node Version**: 18+
- **Next.js Version**: 15.2.3

## 📊 **Impact**

- **High**: Thread History completely non-functional with env var configuration
- **Medium**: Console errors affect developer experience
- **Users affected**: Anyone using `.env` configuration (documented method)

## ✅ **Solution Available**

Pull Request: [#link-to-pr] fixes both issues with minimal, backward-compatible changes.
