# Test: Frontend Rendering

## Prerequisites
- Safari is open (login not required for this test)

## Steps

### 1. Navigate to dev site homepage
- Open: $PM_DEV_URL/
- Wait for page to load (5 seconds)
- Screenshot and verify:
  - [ ] Page loads (not blank)
  - [ ] No PHP errors visible in the page
  - [ ] HTML content is rendered (not raw code)

### 2. Check page structure
- Look for common page elements in the accessibility tree:
  - [ ] At least one link (L*) exists
  - [ ] Text content is present (S* static text elements)
  - [ ] The page has more than 10 elements total (not a minimal error page)

### 3. Check for structured data
- Use steer find to look for "application/ld+json" or schema markup
- This is a soft check (WARN not FAIL if missing)

## Pass Criteria
Homepage loads with real content, no PHP errors, reasonable number of elements.

## On Failure
The site may be down or a core error prevents rendering. Run pm-smoke.sh to check HTTP status first.
