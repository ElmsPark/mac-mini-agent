# Test: EP Email Settings Page

## Prerequisites
- Logged into admin
- EP Email is active on the dev site

## Steps

### 1. Navigate to EP Email settings
- Open: $PM_DEV_URL/admin/plugins/?plugin=EP_Email
- Wait for page to load (5 seconds, settings pages can be slower)
- Screenshot and verify:
  - [ ] Page loads without PHP errors
  - [ ] No white/blank page
  - [ ] "EP Email" text visible in heading or breadcrumb

### 2. Verify form fields exist
- Take a snapshot and inspect the accessibility tree
- Verify:
  - [ ] At least one text input field (T*) exists
  - [ ] At least one checkbox (C*) or toggle exists
  - [ ] Form elements are present (not just static text)

### 3. Verify save button
- Search for a "Save" button in the accessibility tree
- Verify:
  - [ ] Save button exists and is enabled
  - [ ] Do NOT click save (read-only test)

### 4. Check for EP Suite navigation
- Look for EP Suite nav bar elements (other plugin names like "Booking", "GDPR", etc.)
- Verify:
  - [ ] EP Suite navigation is visible (indicates the EP Suite base class loaded correctly)

## Pass Criteria
Settings page loads with form fields and a save button. No PHP errors.

## On Failure
A failure here likely means EP Email's settings() valet method crashed. Check if the plugin's class-ep-suite.php loaded correctly.
