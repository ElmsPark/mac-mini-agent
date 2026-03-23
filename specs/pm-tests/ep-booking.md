# Test: EP Booking Settings Page

## Prerequisites
- Logged into admin
- EP Booking is active on the dev site

## Steps

### 1. Navigate to EP Booking settings
- Open: $PM_DEV_URL/admin/plugins/?plugin=EP_Booking
- Wait for page to load (5 seconds)
- Screenshot and verify:
  - [ ] Page loads without PHP errors
  - [ ] "Booking" text visible

### 2. Verify form fields
- [ ] At least one text input or checkbox exists
- [ ] Booking-specific settings present (calendar, availability, or service references)

### 3. Verify save button
- [ ] Save button exists and is enabled
- [ ] Do NOT click save

## Pass Criteria
Settings page loads with form fields. No PHP errors.

## On Failure
Check EP Booking's settings() method and class-ep-suite.php.
