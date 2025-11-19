
# Mr Sleep App Design Principles

## 🎨 Visual Design Principles

### 1. Color System
- **Primary background:** Deep navy blue gradient (dark-to-darker tones) for calmness and night association.  
- **Accent color:** Golden yellow for call-to-action buttons, icons, and section headers (used for “Set Alarm,” “Full Recharge,” etc.).  
- **Secondary accent:** Light gray for body text and labels to maintain contrast and readability.  
- **State color logic:**  
  - Yellow → active, positive, or primary action (e.g., "Set Alarm").  
  - Gray → secondary or neutral actions (e.g., “Cancel”).  
  - Blue tones → background and supportive visuals.  

### 2. Typography
- **Font:** Rounded, friendly sans-serif type (similar to SF Pro Rounded).  
- **Hierarchy:**
  - **Large titles** (e.g., “Mr Sleep,” “Alarm set!”) — bold and centered.  
  - **Subheadings** (e.g., “Sleep Now. Wake up Like a Boss”) — medium weight, slightly smaller.  
  - **Body text** — light weight, high readability.  
  - **Time values (e.g., 1:20 PM)** — oversized numeric font, clear and bold to convey importance.  
- **Color use in typography:**
  - Bright white or light gray on dark background.  
  - Yellow for highlight or emphasis.

### 3. Iconography & Illustrations
- **Style:** 3D emojis and rounded flat icons.  
- **Tone:** Playful and friendly (e.g., moon with sunglasses, thumbs-up emoji).  
- **Function:** Used as visual anchors for each section (e.g., battery → energy, heart → recovery, lightning → quick boost).  
- **Consistency:** All icons follow the same lighting and shading style.

---

## 🧭 Layout & Structure

### 1. Alignment & Spacing
- **Vertical stacking** of modules with consistent padding.  
- Each section (e.g., “Full Recharge,” “Recovery,” “Quick Boost”) is a **card block** separated by ample vertical spacing.  
- **Central alignment** for all text and buttons — reinforces calm, balanced feel.  

### 2. Card Design
- **Rounded corners:** Large radius (around 20–24px).  
- **Elevation:** Subtle shadow or darker gradient to distinguish from background.  
- **Content layout:**  
  - Top line: “Wake Up Time” label.  
  - Middle: Large bold time.  
  - Right: “Total Sleep” indicator with small clock icon.  

### 3. Visual Flow
- Top-to-bottom narrative:  
  - Current time → motivation → suggested alarms → set alarm → confirmation.  
- Each screen continues the story (see “Sleep Now,” then “Set Alarm,” then “Alarm Set”).  
- Minimal distractions — no clutter or extra buttons.

---

## 🧠 UX & Interaction Design

### 1. Tone & Copy
- **Motivational and casual:**  
  - Examples: “Wake up Like a Boss,” “Recharge without feeling like a zombie,” “Get ready to wake up refreshed.”  
- **Microcopy serves emotion + clarity:** communicates both state and benefit (not just status).  
- **Human touch:** use of emojis and warm language builds user comfort before sleep.

### 2. Feedback & State Transitions
- Clear state progression:
  1. Choose sleep duration →  
  2. Confirm alarm time →  
  3. Loading state (“Setting up your alarm…”) →  
  4. Success confirmation (“Alarm set!”).  
- **Animations:** Smooth transitions and gentle delays between states (implied by “Please wait a moment”).  
- **Loading feedback:** Single icon animation (ring around bell) — keeps focus without stress.

### 3. CTA Design
- **Primary CTA:** Large, full-width golden button (e.g., “Set Alarm”).  
- **Secondary CTA:** Text-based “Cancel” below in gray.  
- Buttons are clearly distinct by color and spacing.  

### 4. User Mental Model
- Simplicity-first approach — no settings, no distractions.  
- Each screen has **one clear goal** (decide, confirm, wait, done).  
- The app mimics a **ritual experience** — calming before sleep.

---

## ⚙️ Motion & Interaction Principles

- **Micro-interactions:**  
  - Icon scaling (e.g., bell vibration effect when alarm is being set).  
  - Smooth progress indicator transitions (e.g., circular time-left indicator).  
- **Screen transitions:** Crossfade or slide-up; always slow and subtle.  
- **Haptic feedback:** Likely soft tap when confirming alarm.  
- **Animation curve:** Ease-in-out to match the relaxing context.

---

## 📱 Component Summary for Implementation

| Component | Type | Description |
|------------|------|-------------|
| **Header (Mr Sleep)** | Text + Icon | Centered moon emoji + title with animated Zs |
| **Current Time Display** | Label | Medium text, white |
| **Motivational Subtitle** | Text | “Sleep Now. Wake up Like a Boss” |
| **Section Title** | Text + Icon | Bold yellow label (“Full Recharge,” “Recovery,” etc.) |
| **Card** | Container | Rounded corners, gradient or shadow, includes wake-up time and total sleep |
| **Button (Primary)** | Action | Full-width, yellow, rounded corners |
| **Button (Secondary)** | Text Action | Gray text below primary button |
| **Progress Ring** | Visual | Circular progress with time left and blue highlight |
| **Loading State** | Animation | Centered bell icon with subtle rotation or pulse |
| **Confirmation Screen** | Success | Centered emoji and short success message |
