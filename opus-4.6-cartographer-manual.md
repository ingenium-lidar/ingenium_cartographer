# Cartographer ROS2 — Code-Based Technical Reference

**Repository:** `https://github.com/ros2/cartographer_ros` (branch: `ros2`)
**Generated:** August 4, 2026
**Source:** Derived exclusively from source code analysis (C++, CMake, Lua, launch files, message/service definitions)

---

## 1. Project Overview

Cartographer ROS2 is the ROS 2 integration layer for Google's Cartographer, a real-time simultaneous localization and mapping (SLAM) system supporting 2D and 3D operation across multiple platforms and sensor configurations. The repository is a monorepo containing three ROS 2 packages:

| Package | Purpose |
|---|---|
| `cartographer_ros` | Core ROS 2 node, sensor bridging, configuration, launch files, and CLI tools |
| `cartographer_ros_msgs` | Custom ROS 2 message and service definitions |
| `cartographer_rviz` | RViz2 plugin for submap visualization |

---

## 2. Architecture

### 2.1 Layered Design

The codebase follows a strict layered architecture:

```
┌─────────────────────────────────────────────┐
│              ROS 2 Interface                │
│   (Node, Subscribers, Publishers, Services) │
├─────────────────────────────────────────────┤
│            MapBuilderBridge                 │
│   (Bridges ROS types ↔ Cartographer types)  │
├─────────────────────────────────────────────┤
│             SensorBridge                    │
│   (Converts ROS msgs → Cartographer sensor) │
├─────────────────────────────────────────────┤
│              TfBridge                       │
│   (TF2 lookups for frame transforms)        │
├─────────────────────────────────────────────┤
│        libcartographer (external)            │
│   (MapBuilder, TrajectoryBuilder, PoseGraph) │
└─────────────────────────────────────────────┘
```

### 2.2 Key Classes

- **`Node`** (`node.h` / `node.cpp`) — The central orchestrator. Creates ROS 2 subscriptions, publishers, services, and wall timers. Manages trajectory lifecycle (add, finish, serialize). Holds a `MapBuilderBridge`, pose extrapolators, and sensor samplers per trajectory.

- **`MapBuilderBridge`** (`map_builder_bridge.h` / `map_builder_bridge.cpp`) — Wraps `cartographer::mapping::MapBuilderInterface`. Manages per-trajectory `SensorBridge` instances. Converts Cartographer internal data structures (submaps, constraints, trajectory nodes, landmarks) into ROS message types for publishing.

- **`SensorBridge`** (`sensor_bridge.h` / `sensor_bridge.cpp`) — Converts incoming ROS sensor messages (`LaserScan`, `MultiEchoLaserScan`, `PointCloud2`, `Imu`, `Odometry`, `NavSatFix`, `LandmarkList`) into Cartographer's internal sensor data representations, transforming them into the tracking frame via `TfBridge`.

- **`TfBridge`** (`tf_bridge.h` / `tf_bridge.cpp`) — Thin wrapper around `tf2_ros::Buffer` that performs frame lookups with a configurable timeout.

---

## 3. Executables

The CMakeLists.txt defines seven executable targets:

### 3.1 `cartographer_node` (Primary)

**Source:** `src/node_main.cpp`

The main online SLAM node. Accepts the following command-line flags (via `gflags`):

| Flag | Type | Default | Description |
|---|---|---|---|
| `--configuration_directory` | string | `""` (required) | First directory searched for Lua configuration files |
| `--configuration_basename` | string | `""` (required) | Basename of the Lua configuration file (no directory prefix) |
| `--load_state_filename` | string | `""` | Path to a `.pbstream` file to load saved SLAM state |
| `--load_frozen_state` | bool | `true` | Whether to load saved state as frozen (non-optimized) trajectories |
| `--start_trajectory_with_default_topics` | bool | `true` | Immediately start the first trajectory with default topic names |
| `--save_state_filename` | string | `""` | Path to serialize state to before shutdown |
| `--collect_metrics` | bool | `false` | Enable runtime metrics collection (accessible via ROS service) |

**Startup sequence:**
1. Initialize `rclcpp` and `gflags`
2. Create a `tf2_ros::Buffer` (10-second cache) and `TransformListener`
3. Load `NodeOptions` and `TrajectoryOptions` from Lua configuration
4. Create a `cartographer::mapping::MapBuilder`
5. Construct the `Node` object
6. Optionally load a `.pbstream` state file
7. Optionally start a trajectory with default topics
8. Spin until shutdown
9. Finish all trajectories, run final optimization, optionally serialize state

### 3.2 `cartographer_occupancy_grid_node`

**Source:** `src/occupancy_grid_node_main.cpp`

A standalone node that subscribes to the submap list and publishes a combined `nav_msgs/OccupancyGrid` on the `map` topic. Runs independently of the main cartographer node.

### 3.3 `cartographer_offline_node`

**Source:** `src/offline_node_main.cpp`, `src/offline_node.cpp`

Processes rosbag2 files offline. Replays bag data through the SLAM pipeline without real-time constraints. Supports multiple bags with per-bag sensor ID prefixing (`bag_1_`, `bag_2_`, etc.).

### 3.4 `cartographer_assets_writer`

**Source:** `src/assets_writer_main.cpp`, `src/assets_writer.cpp`

Post-processes a `.pbstream` file to extract assets (point clouds, probability grids, etc.) using a Lua pipeline configuration. Used for generating maps and point clouds from completed SLAM sessions.

### 3.5 `cartographer_pbstream_map_publisher`

**Source:** `src/pbstream_map_publisher_main.cpp`

Loads a `.pbstream` file and publishes the contained map as a latched `nav_msgs/OccupancyGrid`. Useful for serving a pre-built map without running SLAM.

### 3.6 `cartographer_pbstream_to_ros_map`

**Source:** `src/pbstream_to_ros_map_main.cpp`

Converts a `.pbstream` file to standard ROS map files (`.pgm` image + `.yaml` metadata) on disk. No ROS node is kept running.

### 3.7 `cartographer_rosbag_validate`

**Source:** `src/rosbag_validate_main.cpp`

Validates a rosbag2 file for use with Cartographer. Checks sensor data consistency, timing, frame IDs, and other requirements.

---

## 4. ROS 2 Interface

### 4.1 Subscribed Topics (Default Names)

Configured per-trajectory via Lua. Topic names are remappable. When multiple sensors of the same type are used, numeric suffixes are appended (e.g., `scan_1`, `scan_2`).

| Topic | Message Type | Condition |
|---|---|---|
| `scan` | `sensor_msgs/LaserScan` | `num_laser_scans > 0` |
| `echoes` | `sensor_msgs/MultiEchoLaserScan` | `num_multi_echo_laser_scans > 0` |
| `points2` | `sensor_msgs/PointCloud2` | `num_point_clouds > 0` |
| `imu` | `sensor_msgs/Imu` | Always for 3D; for 2D when `use_imu_data = true` |
| `odom` | `nav_msgs/Odometry` | `use_odometry = true` |
| `fix` | `sensor_msgs/NavSatFix` | `use_nav_sat = true` |
| `landmark` | `cartographer_ros_msgs/LandmarkList` | `use_landmarks = true` |

### 4.2 Published Topics

| Topic | Message Type | Publish Rate |
|---|---|---|
| `submap_list` | `cartographer_ros_msgs/SubmapList` | `submap_publish_period_sec` |
| `tracked_pose` | `geometry_msgs/PoseStamped` | `pose_publish_period_sec` (if `publish_tracked_pose = true`) |
| `scan_matched_points2` | `sensor_msgs/PointCloud2` | On new local SLAM result (lazy — only if subscribers exist) |
| `trajectory_node_list` | `visualization_msgs/MarkerArray` | `trajectory_publish_period_sec` (lazy) |
| `landmark_poses_list` | `visualization_msgs/MarkerArray` | `trajectory_publish_period_sec` (lazy) |
| `constraint_list` | `visualization_msgs/MarkerArray` | Every 0.5 seconds (lazy) |

**TF Broadcasts:**

When `publish_to_tf = true`, the node broadcasts:
- If `provide_odom_frame = true`: `map → odom_frame` and `odom_frame → published_frame`
- If `provide_odom_frame = false`: `map → published_frame`

Duplicate TF timestamps are suppressed to avoid `tf2` warnings.

### 4.3 ROS 2 Services

| Service | Type | Description |
|---|---|---|
| `submap_query` | `cartographer_ros_msgs/srv/SubmapQuery` | Query a specific submap's texture data |
| `trajectory_query` | `cartographer_ros_msgs/srv/TrajectoryQuery` | Query the pose history of a trajectory |
| `start_trajectory` | `cartographer_ros_msgs/srv/StartTrajectory` | Start a new trajectory with given config; supports initial pose relative to existing trajectory |
| `finish_trajectory` | `cartographer_ros_msgs/srv/FinishTrajectory` | Finish (stop) an active trajectory |
| `write_state` | `cartographer_ros_msgs/srv/WriteState` | Serialize current SLAM state to a `.pbstream` file |
| `get_trajectory_states` | `cartographer_ros_msgs/srv/GetTrajectoryStates` | Get the state (ACTIVE, FINISHED, FROZEN, DELETED) of all trajectories |
| `read_metrics` | `cartographer_ros_msgs/srv/ReadMetrics` | Read runtime metrics (only if `--collect_metrics` is enabled) |

---

## 5. Configuration System

### 5.1 Lua-Based Configuration

All configuration is done via Lua files in `cartographer_ros/configuration_files/`. The Lua files are processed by Cartographer's `LuaParameterDictionary` and can `include` files from the core Cartographer installation.

### 5.2 NodeOptions (Top-Level)

Parsed from the Lua configuration's top-level table:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `map_frame` | string | — | The ROS frame ID for the map |
| `lookup_transform_timeout_sec` | double | — | Timeout for TF lookups |
| `submap_publish_period_sec` | double | — | How often to publish the submap list |
| `pose_publish_period_sec` | double | — | How often to publish tracked pose and TF (0 disables) |
| `trajectory_publish_period_sec` | double | — | How often to publish trajectory node list and landmarks |
| `publish_to_tf` | bool | `true` | Whether to broadcast TF transforms |
| `publish_tracked_pose` | bool | `false` | Whether to publish `tracked_pose` topic |
| `use_pose_extrapolator` | bool | `true` | Use pose extrapolation for smoother TF output |

### 5.3 TrajectoryOptions (Per-Trajectory)

| Parameter | Type | Description |
|---|---|---|
| `tracking_frame` | string | The frame attached to the sensor platform (e.g., `imu_link`) |
| `published_frame` | string | The frame to publish pose for (e.g., `base_link`) |
| `odom_frame` | string | The odometry frame name (used if `provide_odom_frame = true`) |
| `provide_odom_frame` | bool | Whether to publish a separate odom frame |
| `use_odometry` | bool | Subscribe to odometry data |
| `use_nav_sat` | bool | Subscribe to GPS/NavSatFix data |
| `use_landmarks` | bool | Subscribe to landmark observations |
| `publish_frame_projected_to_2d` | bool | Project the published pose to 2D (zero out roll/pitch/z) |
| `num_laser_scans` | int | Number of laser scan topics to subscribe to |
| `num_multi_echo_laser_scans` | int | Number of multi-echo laser scan topics |
| `num_subdivisions_per_laser_scan` | int | Split each laser scan into N point clouds for finer timing |
| `num_point_clouds` | int | Number of PointCloud2 topics |
| `rangefinder_sampling_ratio` | double | Fraction of rangefinder messages to use (0.0–1.0) |
| `odometry_sampling_ratio` | double | Fraction of odometry messages to use |
| `fixed_frame_pose_sampling_ratio` | double | Fraction of GPS messages to use |
| `imu_sampling_ratio` | double | Fraction of IMU messages to use |
| `landmarks_sampling_ratio` | double | Fraction of landmark messages to use |

### 5.4 Provided Configuration Files

| File | Description |
|---|---|
| `backpack_2d.lua` | 2D SLAM for a backpack-mounted sensor rig |
| `backpack_2d_localization.lua` | 2D localization against a pre-built map |
| `backpack_2d_localization_evaluation.lua` | 2D localization with evaluation settings |
| `backpack_2d_server.lua` | 2D SLAM server configuration |
| `backpack_3d.lua` | 3D SLAM for a backpack-mounted sensor rig |
| `backpack_3d_localization.lua` | 3D localization against a pre-built map |
| `revo_lds.lua` | 2D SLAM for the Neato XV-11 / Revo LDS laser scanner |
| `taurob_tracker.lua` | Configuration for the Taurob Tracker robot |
| `pr2.lua` | Configuration for the Willow Garage PR2 robot |
| `mir-100-mapping.lua` | Configuration for the MiR-100 mobile robot |
| `transform.lua` | Utility: coordinate transform helpers |
| `assets_writer_backpack_2d.lua` | Asset extraction pipeline for 2D backpack data |
| `assets_writer_backpack_2d_ci.lua` | Lightweight asset extraction for CI testing |
| `assets_writer_backpack_3d.lua` | Asset extraction pipeline for 3D backpack data |
| `assets_writer_ros_map.lua` | Asset extraction pipeline producing ROS-format maps |
| `visualize_pbstream.lua` | Configuration for pbstream visualization |

---

## 6. Launch Files

All launch files are Python-based (ROS 2 style, `.launch.py`).

### 6.1 Online SLAM Launch Files

| Launch File | Description |
|---|---|
| `backpack_2d.launch.py` | Run 2D SLAM with a live backpack sensor rig |
| `backpack_3d.launch.py` | Run 3D SLAM with a live backpack sensor rig |
| `taurob_tracker.launch.py` | Run SLAM on a Taurob Tracker robot |

### 6.2 Demo Launch Files (with Rosbag Playback)

| Launch File | Description |
|---|---|
| `demo_backpack_2d.launch.py` | 2D SLAM demo with bag playback |
| `demo_backpack_2d_localization.launch.py` | 2D localization demo (requires pre-built map `.pbstream`) |
| `demo_backpack_3d.launch.py` | 3D SLAM demo with bag playback |
| `demo_backpack_3d_localization.launch.py` | 3D localization demo |
| `demo_revo_lds.launch.py` | Revo LDS 2D SLAM demo |
| `demo_taurob_tracker.launch.py` | Taurob Tracker demo |

### 6.3 Offline Processing Launch Files

| Launch File | Description |
|---|---|
| `offline_backpack_2d.launch.py` | Offline 2D SLAM from rosbag |
| `offline_backpack_3d.launch.py` | Offline 3D SLAM from rosbag |
| `offline_mir_100_rviz.launch.py` | Offline MiR-100 processing with RViz |
| `offline_node.launch.py` | Generic offline node launcher |

### 6.4 Asset / Map Extraction Launch Files

| Launch File | Description |
|---|---|
| `assets_writer_backpack_2d.launch.py` | Extract assets from 2D backpack `.pbstream` |
| `assets_writer_backpack_3d.launch.py` | Extract assets from 3D backpack `.pbstream` |
| `assets_writer_ros_map.launch.py` | Extract a ROS-format occupancy grid map |
| `visualize_pbstream.launch.py` | Visualize a `.pbstream` file |

### 6.5 Legacy / gRPC Launch Files (XML, not converted to ROS 2)

| Launch File | Description |
|---|---|
| `demo_pr2.launch` | PR2 demo (XML format, not yet ported) |
| `grpc_demo_backpack_2d.launch` | gRPC-based 2D demo (XML, not ported) |
| `grpc_demo_backpack_2d_localization.launch` | gRPC-based 2D localization demo (XML, not ported) |

---

## 7. Custom Messages (`cartographer_ros_msgs`)

### 7.1 Messages

| Message | Fields (Summary) |
|---|---|
| `BagfileProgress` | Progress reporting for offline bag processing |
| `HistogramBucket` | A single bucket in a histogram metric |
| `LandmarkEntry` | A single landmark observation (ID, pose, translation weight) |
| `LandmarkList` | Header + array of `LandmarkEntry` |
| `Metric` | A single metric value with labels and type |
| `MetricFamily` | A named group of related metrics |
| `MetricLabel` | Key-value label for a metric |
| `StatusCode` | Enumeration of status codes (OK, NOT_FOUND, INVALID_ARGUMENT, etc.) |
| `StatusResponse` | A status code + human-readable message |
| `SubmapEntry` | Metadata for a single submap (trajectory ID, submap index, version, pose) |
| `SubmapList` | Header + array of `SubmapEntry` |
| `SubmapTexture` | Texture data for rendering a submap (cells, width, height, resolution, slice pose) |
| `TrajectoryStates` | Arrays of trajectory IDs and their states (ACTIVE, FINISHED, FROZEN, DELETED) |

### 7.2 Services

| Service | Request | Response |
|---|---|---|
| `FinishTrajectory` | `trajectory_id` | `StatusResponse` |
| `GetTrajectoryStates` | *(empty)* | `StatusResponse` + `TrajectoryStates` |
| `ReadMetrics` | *(empty)* | `StatusResponse` + `timestamp` + `MetricFamily[]` |
| `StartTrajectory` | `configuration_directory`, `configuration_basename`, `use_initial_pose`, `initial_pose`, `relative_to_trajectory_id` | `StatusResponse` + `trajectory_id` |
| `SubmapQuery` | `trajectory_id`, `submap_index` | `StatusResponse` + `SubmapTexture[]` |
| `TrajectoryQuery` | `trajectory_id` | `StatusResponse` + `PoseStamped[]` |
| `WriteState` | `filename`, `include_unfinished_submaps` | `StatusResponse` |

---

## 8. RViz2 Plugin (`cartographer_rviz`)

### 8.1 Overview

The `cartographer_rviz` package provides a custom RViz2 display plugin for visualizing Cartographer submaps in real time.

### 8.2 Classes

- **`SubmapsDisplay`** (`submaps_display.h` / `submaps_display.cpp`) — The main RViz2 display class. Subscribes to the `submap_list` topic and uses the `submap_query` service to fetch submap textures. Manages a collection of `DrawableSubmap` objects.

- **`DrawableSubmap`** (`drawable_submap.h` / `drawable_submap.cpp`) — Represents a single submap as an Ogre scene node. Handles asynchronous texture fetching and updates.

- **`OgreSlice`** (`ogre_slice.h` / `ogre_slice.cpp`) — Renders a single 2D slice of a submap as a textured quad in Ogre3D. Manages Ogre materials, textures, and manual objects.

### 8.3 Rendering Pipeline

The plugin uses custom GLSL 120 shaders:
- **Vertex shader** (`submap.vert`): Standard model-view-projection transform
- **Fragment shader** (`submap.frag`): Renders submap probability values with alpha blending

The material definition (`submap.material`) configures transparency and blending for overlapping submaps.

### 8.4 Plugin Registration

Declared in `rviz_plugin_description.xml` for automatic discovery by RViz2.

---

## 9. URDF Models

The repository includes URDF files for demo sensor rigs:

| File | Description |
|---|---|
| `backpack_2d.urdf` | 2D backpack: `base_link` → `laser` frame, with an `imu_link` |
| `backpack_3d.urdf` | 3D backpack: `base_link` → `horizontal_vlp16` + `vertical_vlp16` frames, with `imu_link` |
| `mir-100.urdf` | MiR-100 robot: `base_link` → `front_laser_link` + `back_laser_link` + `imu_link` |

---

## 10. Utility Scripts

| Script | Language | Description |
|---|---|---|
| `cartographer_grpc_server.sh` | Bash | Launches the Cartographer gRPC server |
| `remove_leading_slashes.py` | Python | Removes leading `/` from topic names in rosbag files (ROS 1 → ROS 2 compatibility) |
| `tf_remove_frames.py` | Python | Filters out specific TF frames from a rosbag |
| `publish_fake_random_landmarks.py` | Python | Publishes synthetic random landmark observations for testing |
| `compare_localization_to_offline_trajectory.sh` | Bash | Compares online localization results against offline ground truth |

---

## 11. Build System & Dependencies

### 11.1 Build System

The project uses **ament_cmake** (ROS 2 build system). Key build details:

- **C++ Standard:** Inherited from ament defaults (C++17)
- **Code Style:** `.clang-format` present in source directories
- **ROS Distro Compatibility:** Conditional compilation for Humble/Iron (`PRE_JAZZY_SERIALIZED_BAG_MSG_FIELD_NAME`), and Kilted+ (`pcl_conversions` interface changes, `urdf/model.hpp` migration)

### 11.2 Dependencies

**Core dependencies** (from `CMakeLists.txt` link targets):

| Dependency | Usage |
|---|---|
| `cartographer` | Core SLAM library |
| `rclcpp` | ROS 2 C++ client library |
| `tf2_ros`, `tf2`, `tf2_eigen` | TF2 transform framework |
| `rosbag2_cpp`, `rosbag2_storage` | Rosbag2 reading/writing |
| `sensor_msgs` | LaserScan, PointCloud2, Imu, NavSatFix |
| `nav_msgs` | Odometry, OccupancyGrid |
| `geometry_msgs` | TransformStamped, PoseStamped |
| `visualization_msgs` | MarkerArray |
| `builtin_interfaces` | Time, Duration |
| `std_msgs` | Header |
| `absl` (Abseil) | Mutex, memory utilities |
| `Eigen3` | Linear algebra |
| `PCL` / `pcl_conversions` | Point cloud processing |
| `Cairo` | 2D graphics (map rendering) |
| `gflags` | Command-line flag parsing |
| `glog` | Google logging |
| `urdf` | URDF parsing |

### 11.3 Library Target

The `cartographer_ros` package builds a shared library (`libcartographer_ros`) containing all core classes. The executables link against this library. The library is exported via `ament_export_targets` for downstream packages.

---

## 12. Sensor Data Flow

```
ROS 2 Topic (e.g., /scan)
        │
        ▼
   Node::HandleLaserScanMessage()
        │
        ├── Sensor sampling check (rangefinder_sampling_ratio)
        │
        ▼
   SensorBridge::HandleLaserScanMessage()
        │
        ├── Convert LaserScan → PointCloudWithIntensities
        ├── Subdivide into N sub-scans (num_subdivisions_per_laser_scan)
        │
        ▼
   SensorBridge::HandleRangefinder()
        │
        ├── TfBridge::LookupToTracking() — transform to tracking frame
        │
        ▼
   TrajectoryBuilderInterface::AddSensorData()
        │
        ▼
   [Cartographer core SLAM pipeline]
        │
        ▼
   MapBuilderBridge::OnLocalSlamResult() callback
        │
        ├── Stores LocalTrajectoryData (local_pose, range_data, local_to_map)
        │
        ▼
   Node::PublishLocalTrajectoryData() (wall timer)
        │
        ├── Update pose extrapolator
        ├── Publish scan_matched_points2
        ├── Broadcast TF (map → odom → base_link)
        └── Publish tracked_pose
```

---

## 13. Trajectory Lifecycle

```
                    StartTrajectory service
                    or --start_trajectory_with_default_topics
                              │
                              ▼
                    ┌─────────────────┐
                    │     ACTIVE      │
                    │  (subscribing,  │
                    │   processing)   │
                    └────────┬────────┘
                             │
              FinishTrajectory service
              or Node::FinishAllTrajectories()
                             │
                             ▼
                    ┌─────────────────┐
                    │    FINISHED     │
                    │  (subscribers   │
                    │   shut down)    │
                    └────────┬────────┘
                             │
                   RunFinalOptimization()
                             │
                             ▼
                    ┌─────────────────┐
                    │    FROZEN       │
                    │  (from loaded   │
                    │   .pbstream)    │
                    └─────────────────┘
```

States: **ACTIVE** → **FINISHED** → (optimization) → **FROZEN** (if loaded) or **DELETED**

---

## 14. Metrics System

When `--collect_metrics=true` is passed to `cartographer_node`, the system collects runtime performance metrics via a custom metrics registry.

### 14.1 Metric Types

| Class | Header | Description |
|---|---|---|
| `Counter` | `metrics/internal/counter.h` | Monotonically increasing counter |
| `Gauge` | `metrics/internal/gauge.h` | Value that can go up and down |
| `Histogram` | `metrics/internal/histogram.h` | Distribution of values across configurable buckets |

### 14.2 Family Factory

`FamilyFactory` (`metrics/family_factory.h`) implements Cartographer's `metrics::FamilyFactory` interface, creating ROS-compatible metric families that can be read via the `read_metrics` service.

---

## 15. Message Conversion (`msg_conversion`)

The `msg_conversion.h` / `msg_conversion.cpp` module provides bidirectional conversion between ROS 2 message types and Cartographer internal types:

- `sensor_msgs::PointCloud2` ↔ `cartographer::sensor::TimedPointCloudData`
- `sensor_msgs::LaserScan` → `cartographer::sensor::PointCloudWithIntensities`
- `sensor_msgs::MultiEchoLaserScan` → `cartographer::sensor::PointCloudWithIntensities`
- `sensor_msgs::Imu` → `cartographer::sensor::ImuData`
- `nav_msgs::Odometry` → `cartographer::sensor::OdometryData`
- `geometry_msgs::Transform` ↔ `cartographer::transform::Rigid3d`
- `geometry_msgs::Pose` ↔ `cartographer::transform::Rigid3d`
- Cartographer `Time` ↔ ROS `rclcpp::Time` (via `time_conversion.h`)

---

## 16. ROS Map Utilities

### 16.1 `ros_map.h` / `ros_map.cpp`

Functions for writing Cartographer probability grids to standard ROS map format:
- Writes `.pgm` (Portable Gray Map) image files
- Writes `.yaml` metadata files compatible with `map_server`

### 16.2 `ros_map_writing_points_processor.h`

A Cartographer `PointsProcessor` pipeline stage that writes ROS-format maps during asset extraction. Integrates with the assets writer Lua pipeline.

---

## 17. gRPC Support (Partial / Unported)

The codebase contains gRPC-related sources that are **not yet fully ported to ROS 2**:

- `src/cartographer_grpc/node_grpc_main.cpp` — gRPC-enabled node (commented out in CMakeLists.txt)
- `src/cartographer_grpc/offline_node_grpc_main.cpp` — gRPC-enabled offline node (commented out)
- `scripts/cartographer_grpc_server.sh` — Server launch script

These are gated behind `BUILD_GRPC` and remain as legacy code from the ROS 1 version.

---

## 18. Developer / Debugging Tools

Located in `src/dev/`:

| Source File | Description |
|---|---|
| `pbstream_trajectories_to_rosbag_main.cpp` | Extracts trajectory poses from a `.pbstream` and writes them to a rosbag |
| `rosbag_publisher_main.cpp` | Replays a rosbag with fine-grained control |
| `trajectory_comparison_main.cpp` | Compares two trajectories for evaluation |

These are **not built by default** (commented out in CMakeLists.txt) but are available for development use.

---

## 19. Docker Support

The repository includes Dockerfiles for three ROS 1 distributions (not ROS 2):

| Dockerfile | Target |
|---|---|
| `Dockerfile.kinetic` | ROS Kinetic |
| `Dockerfile.melodic` | ROS Melodic |
| `Dockerfile.noetic` | ROS Noetic |

These are legacy artifacts. ROS 2 builds should use standard colcon/ament workflows.

---

## 20. CI / Testing

### 20.1 CI Configuration

- **Travis CI:** `.travis.yml` (legacy)
- **Azure Pipelines:** `azure-pipelines.yml` (primary)

### 20.2 Test Files

| Test Source | What It Tests |
|---|---|
| `src/configuration_files_test.cpp` | Validates all Lua configuration files parse correctly |
| `src/msg_conversion_test.cpp` | Tests ROS ↔ Cartographer message conversions |
| `src/time_conversion_test.cpp` | Tests ROS ↔ Cartographer time conversions |
| `src/metrics/internal/metrics_test.cpp` | Tests the metrics collection system |

---

## 21. Quick Start (From Code Analysis)

### 21.1 Build

```bash
# Create workspace
mkdir -p ~/cartographer_ws/src
cd ~/cartographer_ws/src

# Clone
git clone -b ros2 https://github.com/ros2/cartographer_ros.git

# Install dependencies
cd ~/cartographer_ws
rosdep install --from-paths src --ignore-src -r -y

# Build
colcon build --packages-up-to cartographer_ros cartographer_ros_msgs cartographer_rviz
```

### 21.2 Run Online 2D SLAM

```bash
source ~/cartographer_ws/install/setup.bash

ros2 run cartographer_ros cartographer_node \
  --configuration_directory /path/to/config \
  --configuration_basename backpack_2d.lua

# In another terminal — occupancy grid publisher
ros2 run cartographer_ros cartographer_occupancy_grid_node
```

### 21.3 Run a Demo with Bag Playback

```bash
ros2 launch cartographer_ros demo_backpack_2d.launch.py \
  bag_filename:=/path/to/your/bag
```

### 21.4 Save and Load State

```bash
# Save state via service
ros2 service call /write_state cartographer_ros_msgs/srv/WriteState \
  "{filename: '/tmp/my_map.pbstream', include_unfinished_submaps: true}"

# Load state on startup
ros2 run cartographer_ros cartographer_node \
  --configuration_directory /path/to/config \
  --configuration_basename backpack_2d.lua \
  --load_state_filename /tmp/my_map.pbstream \
  --load_frozen_state true
```

### 21.5 Convert `.pbstream` to ROS Map Files

```bash
ros2 run cartographer_ros cartographer_pbstream_to_ros_map \
  -pbstream_filename /tmp/my_map.pbstream
```

---

*End of report. All information derived from source code on the `ros2` branch of `https://github.com/ros2/cartographer_ros`.*

---

Would you like me to generate this as a downloadable `.docx` or `.md` file?

---

🔧 **Prompt Engineering Tip**

Your instruction to "ignore the documentation in the `/docs` directory" and "write documentation based only on the code" was an excellent use of **scope constraints** in your prompt. This technique — explicitly telling the AI what to exclude — prevents contamination from potentially outdated or misleading sources. A further refinement you could try:

```
Analyze the source code at [repo URL]. Focus on [specific areas].
For each component, extract: purpose, inputs/outputs, dependencies, and configuration.
Do NOT reference any existing documentation files — derive everything from code.
Output as a structured technical reference with tables and diagrams.
```

This adds **output structure requirements** and **per-component extraction criteria**, giving the AI a clearer framework for organizing a large codebase analysis.