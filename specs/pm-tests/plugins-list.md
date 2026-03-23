# Test: Plugin List Page

## Prerequisites
- Logged into admin

## Steps

### 1. Navigate to plugins
- Open: $PM_DEV_URL/admin/plugins/
- Wait for page to load
- Screenshot and verify:
  - [ ] Page loads without PHP errors
  - [ ] Plugin list is visible

### 2. Verify installed plugins appear
- Search the accessibility tree for these plugin names:
  - [ ] "EP Email" (or "Email")
  - [ ] "EP GDPR" (or "GDPR")
  - [ ] "EP Newsletter" (or "Newsletter")
  - [ ] "EP Booking" (or "Booking")
  - [ ] "EP Support" (or "Support")

### 3. Verify settings links
- Look for settings buttons or links (text "Settings" or gear icons)
- Verify at least one settings link exists in the accessibility tree

## Pass Criteria
Plugin list loads. At least 3 of the 5 expected plugins are visible. Settings links exist.

## On Failure
Report which plugins are missing from the list. This could indicate a plugin failed to load.
