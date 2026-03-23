# Test: Plugin Upload UI

## Prerequisites
- Logged into admin

## Steps

### 1. Navigate to Manage Plugins
- Open: $PM_DEV_URL/admin/plugins/?manage=1
- Wait for page to load (5 seconds)
- Screenshot and verify:
  - [ ] Page loads without PHP errors
  - [ ] Plugin management interface is visible

### 2. Verify upload button
- Look for "Upload" text or an upload button in the accessibility tree
- Verify:
  - [ ] Upload button or action exists
  - [ ] Do NOT click it (read-only test, we don't want to trigger the uploader popup)

### 3. Verify plugin list
- Check that installed plugins are listed:
  - [ ] At least 3 plugins visible in the list
  - [ ] Delete or deactivate controls are present (indicates the management UI loaded)

## Pass Criteria
Manage Plugins page loads with upload capability and plugin list visible.

## On Failure
This page depends on the admin-ui-plugins core plugin. If it fails, the core may have an issue.
