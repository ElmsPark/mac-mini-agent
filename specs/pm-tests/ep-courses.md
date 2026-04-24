# Test: EP Courses Admin UI — Full Interaction Test

## Target
- **Site:** dev3.elmspark.com
- **URL:** https://dev3.elmspark.com/admin/plugins/?plugin=EP_Courses

## Prerequisites
- Logged into admin (run `pm-browser-login.sh` first)
- EP Courses is active on dev3.elmspark.com

## Important Rules
- After EVERY action, run `steer see --app Safari --json` for a fresh snapshot
- After every snapshot, check for "fatal error", "Warning:", or blank content
- If the page goes blank at any point, STOP and report the last action taken
- Do NOT click the main PageMotor "Save Options" button at the top of the page. It has a gold background and sits in a sticky bar. Only click EP Courses' own buttons inside the "Manage Courses" section (they have white/grey backgrounds)
- Use `steer wait --for` with expected text instead of fixed sleeps where possible. Fall back to `sleep 2` only when no specific text to wait for
- Dismiss native browser `confirm()` dialogs with `steer hotkey escape --json` (equivalent to Cancel)
- Save a screenshot at the start of each phase: `steer screenshot --app Safari --path /tmp/steer/ep-courses-phase-N.png --json`

---

## Phase 0: First Load and Seed Verification

### 0.1 Navigate to EP Courses settings (first visit creates tables and seeds data)
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/admin/plugins/?plugin=EP_Courses" --clear --json`
- `steer hotkey return --json`
- `sleep 5`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Page loaded (not blank)
  - [ ] No "fatal error" or "Warning:" in page text

### 0.2 Reload to pick up seeded data
The first load creates database tables (via `construct()`) and seeds courses, but `settings()` already rendered before seeding ran. Reload so the course table is populated.
- `steer hotkey cmd+r --json`
- `sleep 5`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-courses-phase-0.png --json`
- **VERIFY:**
  - [ ] "EP Courses" visible in the header area
  - [ ] EP Suite navigation bar visible
  - [ ] "Manage Courses" section label visible

---

## Phase 1: Settings Groups

### 1.1 Expand General settings
- Click on the "General" section header text
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] "Default Language" select dropdown visible
  - [ ] "Courses Per Page" input visible

### 1.2 Collapse General, expand Languages
- Click on "General" header again
- Click on "Languages" header
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] "Enabled Languages" checkbox group visible
  - [ ] "English" checkbox visible
  - [ ] "isiZulu" checkbox visible

### 1.3 Collapse Languages, expand Display
- Click "Languages" header
- Click "Display" header
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] "Card Style" select visible
  - [ ] "Progress Bar" checkbox visible
  - [ ] "Lesson Count" checkbox visible
  - [ ] "Duration" checkbox visible

### 1.4 Collapse Display, expand Manage Courses
- Click "Display" header
- Click "Manage Courses" header
- `sleep 2`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-courses-phase-1.png --json`
- **VERIFY:**
  - [ ] "Courses" tab visible and active
  - [ ] "Enrolments" tab visible
  - [ ] "+ Add Course" button visible
  - [ ] Course table visible with headers: Title, Level, Price, Lessons, Status, Actions
  - [ ] At least one course row (e.g. "What is the 4th Industrial Revolution?")

---

## Phase 2: Course Table and Tabs

### 2.1 Verify seeded course data
- Read the table from the current snapshot
- **VERIFY:**
  - [ ] At least 5 courses visible
  - [ ] Level column shows "free" for most rows
  - [ ] Lessons column shows "5" for each row
  - [ ] Each row has three action buttons: Edit, Lessons, Delete

### 2.2 Switch to Enrolments tab
- Click the "Enrolments" tab button
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Enrolment stats visible (numbers may be 0)
  - [ ] Course table is hidden
  - [ ] No errors visible

### 2.3 Switch back to Courses tab
- Click the "Courses" tab button
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Course table visible again with same courses

---

## Phase 3: Add Course — Open and Cancel

### 3.1 Click Add Course
- Click the "+ Add Course" button
- `sleep 1`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-courses-phase-3.png --json`
- **VERIFY:**
  - [ ] Editor form visible with heading "Add Course" or "Edit Course"
  - [ ] Title field visible and empty
  - [ ] Slug field visible
  - [ ] Description textarea visible
  - [ ] Outcome textarea visible
  - [ ] Level select visible (Free/Intermediate)
  - [ ] Status select visible (Published/Draft)
  - [ ] "Translations" section visible with language toggle buttons
  - [ ] "Save" and "Cancel" buttons visible
  - [ ] Course table is NOT visible (hidden behind editor)

### 3.2 Test auto-slug generation
- Click on the Title input field
- `steer type "Test Course Alpha" --json`
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Slug field contains "test-course-alpha" (auto-generated)

### 3.3 Expand isiZulu translation
- Click the "isiZulu" button in the Translations section
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Three fields appeared: Title, Description, Outcome (for isiZulu)

### 3.4 Collapse isiZulu translation
- Click the "isiZulu" button again
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] isiZulu fields hidden

### 3.5 Cancel without saving
- Click the "Cancel" button (inside the editor actions area, NOT the PageMotor save bar)
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Editor hidden
  - [ ] Course table visible
  - [ ] No "Test Course Alpha" in the table (nothing was saved)
  - [ ] URL is still `/admin/plugins/?plugin=EP_Courses` (no page reload)

---

## Phase 4: Edit Course — Open and Cancel

### 4.1 Click Edit on first course
- Find the "Edit" button in the first row of the course table
- Click it
- `sleep 2`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-courses-phase-4.png --json`
- **VERIFY:**
  - [ ] Editor form visible
  - [ ] Title field contains "What is the 4th Industrial Revolution?" (first seeded course)
  - [ ] Slug field contains "4th-industrial-revolution"
  - [ ] Description field is not empty
  - [ ] Outcome field is not empty
  - [ ] Course table is hidden

### 4.2 Cancel edit
- Click "Cancel" button
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Editor hidden
  - [ ] Course table visible with all original courses

---

## Phase 5: Lesson Manager

### 5.1 Open Lessons for first course
- Find the "Lessons" button in the first row of the course table
- Click it
- `sleep 2`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-courses-phase-5.png --json`
- **VERIFY:**
  - [ ] "Manage Lessons" heading visible
  - [ ] "+ Add Lesson" button visible
  - [ ] "Back to Courses" button visible
  - [ ] Lesson table visible with headers: Order, Title, Duration, Status, Actions
  - [ ] "Lesson 1" visible in the table
  - [ ] At least 5 lesson rows
  - [ ] Each row has Edit and Delete buttons
  - [ ] Course table is hidden

### 5.2 Edit first lesson
- Find the "Edit" button in the first lesson row
- Click it
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Lesson editor form visible
  - [ ] Title field contains "Lesson 1"
  - [ ] Content textarea visible (may be empty for placeholder lessons)
  - [ ] Video URL field visible
  - [ ] Video Type select visible with options: None, YouTube, Vimeo, MP4
  - [ ] Sort Order field visible
  - [ ] Duration field visible
  - [ ] Status select visible
  - [ ] Translations section with language toggles visible
  - [ ] Save and Cancel buttons visible

### 5.3 Expand Afrikaans lesson translation
- Click the "Afrikaans" translation toggle
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Afrikaans fields visible: Title, Content, Video URL

### 5.4 Cancel lesson edit
- Click "Cancel" button
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Lesson editor hidden
  - [ ] Lesson table visible with same lessons

### 5.5 Delete lesson — dismiss confirm dialog
- Find the "Delete" button in the first lesson row
- Click it
- `sleep 1`
- A native browser confirm dialog should appear
- Dismiss it: `steer hotkey escape --json`
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Still on the lesson manager (NOT back at course table)
  - [ ] All lessons still listed (none deleted)
  - [ ] "Manage Lessons" heading still visible

### 5.6 Back to Courses
- Click "Back to Courses" button
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Lesson manager hidden
  - [ ] Course table visible with all original courses

---

## Phase 6: Delete Course — Dismiss Confirm

### 6.1 Delete course — dismiss confirm dialog
- Find the "Delete" button in the first course row (in the Actions column of the course table)
- Click it
- `sleep 1`
- A native confirm dialog should appear with text about deleting lessons and enrolments
- Dismiss it: `steer hotkey escape --json`
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Still on the course table
  - [ ] All courses still listed (none deleted)

---

## Phase 7: Navigation Stability

### 7.1 Rapid tab switching
- Click "Enrolments" tab, `sleep 1`
- Click "Courses" tab, `sleep 1`
- Click "Enrolments" tab, `sleep 1`
- Click "Courses" tab, `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Course table visible
  - [ ] No blank screen at any point
  - [ ] Page did not reload

### 7.2 Deep navigation round-trip
Execute this sequence without stopping:
1. Click "Lessons" on first course, `sleep 2`
2. Click "Edit" on first lesson, `sleep 1`
3. Click "Cancel", `sleep 1`
4. Click "Back to Courses", `sleep 1`
5. Click "Edit" on first course, `sleep 2`
6. Click "Cancel", `sleep 1`

After the full sequence:
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-courses-phase-7.png --json`
- **VERIFY:**
  - [ ] Course table visible with all courses
  - [ ] URL is still `/admin/plugins/?plugin=EP_Courses`
  - [ ] No blank screen occurred at any step

---

## Phase 8: Save Course with Empty Title (Error Handling)

### 8.1 Attempt to save empty course
- Click "+ Add Course" button
- `sleep 1`
- Leave the Title field empty
- Click the "Save" button inside the editor (NOT the PageMotor save bar at top)
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] An error message or alert appeared ("Title is required" or similar)
  - [ ] Page did NOT go blank
  - [ ] Editor is still visible (not closed)

### 8.2 Cancel after failed save
- Click "Cancel"
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Course table visible
  - [ ] No empty-title course was added

---

## Phase 9: Frontend Smoke Test

### 9.1 Verify frontend still loads
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-courses-phase-9.png --json`
- **VERIFY:**
  - [ ] Page loaded (not blank)
  - [ ] No "fatal error" or "Warning:" visible

### 9.2 HTTP confirmation
- Run: `curl -sL -o /dev/null -w '%{http_code} %{size_download}' 'https://dev3.elmspark.com/'`
- **VERIFY:**
  - [ ] Status code is 200
  - [ ] Size is > 1000 bytes

---

## Pass Criteria

ALL of the following must be true:
1. Settings page loads with EP Suite header and four collapsible groups
2. Seeded courses appear in the table after page reload (Phase 0)
3. Enrolments tab loads and Courses tab restores cleanly
4. Add Course editor opens with empty fields, auto-slug works, Cancel returns without saving
5. Edit Course editor opens with populated fields, Cancel returns cleanly
6. Lesson Manager opens with seeded lessons, Edit/Cancel works, Back returns cleanly
7. Dismissing confirm dialogs (Delete lesson, Delete course) does NOT navigate away
8. Deep navigation round-trip completes without state corruption
9. Saving with empty title shows an error, does not create a course
10. Frontend homepage still loads normally

## On Failure

Report each failed step with:
- Step number and name
- What was expected vs what happened
- Screenshot path (if captured)
- The last Steer command executed before the failure

### Common failure patterns

| Symptom | Likely cause |
|---------|-------------|
| Blank screen after button click | Button missing `type="button"`, form submitted |
| Section collapses on dialog cancel | Click bubbling to EP Suite group toggle. Missing `e.stopPropagation()` |
| Empty course table on first load | Seed data runs after `settings()` renders. Need page reload (Phase 0.2) |
| AJAX timeout, no data loads | `fetch()` handler not returning JSON. Check `pm_ajax` routing |
| PHP errors on page load | `settings()` running DB query on frontend. Missing `is_admin` guard |
| Confirm dialog not dismissed | Use `steer hotkey escape` not `steer click --on Cancel` for native dialogs |
