# Test: EP Support Settings Page

## Prerequisites
- Logged into admin
- EP Support is active on the dev site

## Steps

### 1. Navigate to EP Support settings
- Open: $PM_DEV_URL/admin/plugins/?plugin=EP_Support
- Wait for page to load (5 seconds)
- Screenshot and verify:
  - [ ] Page loads without PHP errors
  - [ ] "Support" text visible

### 2. Verify form fields
- [ ] At least one checkbox or toggle exists (Enable toggle)
- [ ] Support-specific settings present

### 3. Verify save button
- [ ] Save button exists and is enabled
- [ ] Do NOT click save

## Pass Criteria
Settings page loads with form fields. No PHP errors.

## On Failure
Check EP Support's settings() method and class-ep-suite.php.
