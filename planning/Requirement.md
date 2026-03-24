## Mobile Application Design & Technical Specification Document

**Project:** Modular Chore Robot Control App
**Role:** Mobile Architecture & Project Management
**Target Framework:** Flutter (Dart)

### 1. Design System & Aesthetic (Tesla-Inspired)

**Philosophy:** Minimalist, data-dense, cinematic. The interface must feel like a direct extension of the hardware.

* **Palette:**
* **Background:** Deep Matte Black (`#121212`) or Dark Gunmetal (`#1E1E1E`).
* **Accents:** Neon Cyan (`#00E5FF`) for connectivity, Safety Orange (`#FF3D00`) for alerts, Leaf Green (`#00C853`) for active tasks.
* **Glassmorphism:** Heavily used for overlays (control panels) over the 3D robot render.


* **Typography:** Sans-serif, geometric (e.g., Roboto or custom spaced fonts), high readability.
* **Key Visual:** A central, interactive 3D model of the robot (using `.glb` or `.gltf` via `flutter_3d_controller` or `model_viewer_plus`).
* **Interaction:** Haptic feedback on all button presses. Swipe gestures for routing.

---

### 2. Routing Architecture

**Navigation Strategy:** Stack-based navigation with a persistent bottom sheet for quick controls.
**Routing Package:** `go_router` (Recommended for deep linking and strict typed routes).

**Route Map:**

1. `/splash` -> Checks Auth/Ownership State.
2. `/intro` -> `/configurator` (Book My Robot - For non-owners).
3. `/dashboard` (Main Hub - For owners).
* Sub-route: `/dashboard/health`
* Sub-route: `/dashboard/schedule`
* Sub-route: `/dashboard/remote_view` (Camera feed)
* Sub-route: `/dashboard/modules` (Attachment config)



---

### 3. Screen Specifications & API Contracts

#### A. Splash Screen

* **UI:** Black screen. Company logo animates in (fade + scale).
* **Logic:**
* Check local storage for `auth_token`.
* If no token -> Route to `/intro`.
* If token exists -> Call `GET /user/status`.
* If `status: "prospect"` -> Route to `/configurator`.
* If `status: "owner"` -> Route to `/dashboard`.





#### B. The Configurator ("Book My Robot")

* **Goal:** Allow users to customize and pre-order the robot.
* **UI Layout:**
* **Top:** Horizontal stepper (Chassis -> Wheels -> Attachments -> Review).
* **Center:** High-fidelity rotating render of the robot. Updates in real-time as options are selected.
* **Bottom:** Floating "Reserve Now" bar with price estimation.


* **Routing:** On success -> `/order_confirmation` -> `/dashboard` (Limited "Awaiting Delivery" mode).

**API Contract:**

* **Endpoint:** `POST /orders/configure`
* **Request Body:**
```json
{
  "chassis_color": "matte_black",
  "wheel_type": "all_terrain_treads",
  "attachments": ["snow_blower_v2", "lawn_mower_deck"],
  "battery_pack": "long_range_100kwh"
}

```


* **Response:**
```json
{
  "order_id": "ORD-9928-X",
  "estimated_delivery": "2026-04-12",
  "total_price": 4500.00
}

```



#### C. Main Dashboard (The Hub)

* **Goal:** Instant status awareness and connection status.
* **UI Layout:**
* **Background:** The 3D Robot model sits in the center void. It rotates slowly.
* **Top Bar (Transparent):**
* Left: Robot Name ("ChoreBot 1").
* Right: Connection Status (Wifi/5G Icon), Weather Icon (Outdoor context).


* **Overlays (Floating Widgets):**
* **Top Left (Battery):** Large percentage text "82%". Subtext: "4h 20m remaining". Visual battery bar (Green).
* **Top Right (Current Activity):** "Idle" or "Blowing Snow".
* **Bottom Control Dock:** A slide-up panel (glass effect).
* Quick Actions: [Unlock], [Return Home], [Stop], [Camera].






* **Interaction:** Tapping specific parts of the 3D robot (e.g., the battery pack) routes to the detailed Health screen.

**API Contract:**

* **Endpoint:** `GET /robot/{id}/telemetry`
* **Response:**
```json
{
  "robot_id": "rb_8821",
  "connection_status": "online",
  "battery": {
    "percentage": 82,
    "voltage": 48.2,
    "range_est_km": 12.5
  },
  "current_state": "idle", // idle, working, charging, error
  "active_task": null,
  "environment": {
    "temp_c": -2,
    "precipitation": "snow"
  },
  "gps": { "lat": 33.6844, "lng": 73.0479 }
}

```



#### D. Health & Diagnostics Analysis

* **UI Layout:**
* **Visual:** Wireframe view of the robot.
* **Components List:** Scrollable list of subsystems (Lidar, Motor FL, Motor FR, AI Core, Attachment Interface).
* **Status Indicators:** Green dots for healthy, Red pulsing for errors.
* **Details:** Tapping a component expands a graph showing temperature/load over time.


* **Tesla Inspiration:** "Service Mode" aesthetics. Dark grey lists, monospace fonts for data values.

**API Contract:**

* **Endpoint:** `GET /robot/{id}/diagnostics`
* **Response:**
```json
{
  "system_health": 98,
  "last_check": "2026-01-08T14:00:00Z",
  "modules": [
    {
      "id": "motor_front_left",
      "status": "nominal",
      "temp_c": 45,
      "rpm": 0
    },
    {
      "id": "lidar_main",
      "status": "warning",
      "error_code": "LIDAR_OBSCURATION_20",
      "message": "Lens requires cleaning"
    }
  ]
}

```



#### E. Task Scheduler & Map

* **Goal:** Tell the robot where to go and what to do.
* **UI Layout:**
* **Full Screen Map:** Satellite view of the home/yard.
* **Zones:** Polygon overlays showing "Mow Zone", "Snow Clear Zone".
* **Action:** Drag and drop tasks onto zones.
* **Time Selector:** "Start Now" or wheel picker for scheduling.



**API Contract:**

* **Endpoint:** `POST /robot/{id}/task`
* **Request Body:**
```json
{
  "task_type": "snow_clearing",
  "zone_id": "driveway_zone_A",
  "start_time": "immediate", // or ISO timestamp
  "parameters": {
    "intensity": "high",
    "pattern": "linear"
  }
}

```



#### F. Module Management (Attachments)

* **Goal:** Detect and configure the currently attached hardware.
* **UI Layout:**
* **Visual:** Exploded view of the robot highlighting the attachment port.
* **Detection:** "Snow Blower Detected".
* **Settings:** Specific sliders for that module (e.g., Chute Angle, Auger Speed).



**API Contract:**

* **Endpoint:** `PUT /robot/{id}/module_config`
* **Request Body:**
```json
{
  "module_type": "snow_blower_v1",
  "settings": {
    "chute_angle_degrees": 45,
    "auger_speed_percent": 80
  }
}

```



---

### 4. Implementation Roadmap (Phase 1)

1. **Project Setup:** Initialize Flutter with `riverpod` (State Management) and `go_router`.
2. **Asset Prep:** Export low-poly GLB models of the robot and attachments.
3. **Mock Service:** Create a local Dart service that mimics the JSON responses above to unblock UI development before the Python/C++ backend is ready.
4. **UI Construction:** Build the "Dashboard" first (it is the highest complexity screen due to 3D integration).

### 5. Next Step

Confirm the specific list of attachments available at launch. I will then generate the specific `JSON` configuration schemas for those modules so the backend team knows exactly what parameters to expect.