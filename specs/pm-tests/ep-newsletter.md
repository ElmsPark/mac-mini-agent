# Test: EP Newsletter Settings Page

## Prerequisites
- Logged into admin
- EP Newsletter is active on the dev site

## Steps

### 1. Navigate to EP Newsletter settings
- Open: $PM_DEV_URL/admin/plugins/?plugin=EP_Newsletter
- Wait for page to load (5 seconds)
- Screenshot and verify:
  - [ ] Page loads without PHP errors
  - [ ] "Newsletter" text visible

### 2. Verify form fields
- [ ] At least one text input or checkbox exists
- [ ] Newsletter-specific settings present

### 3. Verify save button
- [ ] Save button exists and is enabled
- [ ] Do NOT click save

## Pass Criteria
Settings page loads with form fields. No PHP errors.

## On Failure
Check EP Newsletter's settings() method and class-ep-suite.php.
