## Hint

Please change branch to [Bunker-DVI-Dataset-reg-1](https://github.com/MapsHD/benchmark-FMCW-LIO-to-HDMapping/tree/Bunker-DVI-Dataset-reg-1) for quick experiment.

## Example Dataset:

Download the dataset from [Bunker DVI Dataset](https://charleshamesse.github.io/bunker-dvi-dataset/)

# benchmark-FMCW-LIO-to-HDMapping

Runs the [FMCW-LIO](https://github.com/IMRL/FMCW-LIO) LiDAR-inertial
odometry on a ROS 1 bag file and converts the output to an
[HDMapping](https://github.com/MapsHD/HDMapping) session.

FMCW-LIO (M. Zhao et al., RA-L 2024) is a Doppler LiDAR-inertial odometry: with
an FMCW LiDAR it uses each point's Doppler velocity for motion compensation,
velocity estimation and dynamic point rejection. It also runs on conventional
3D LiDARs (Livox, Ouster, Hesai, Velodyne, ...) without Doppler.

## Prerequisites

- Docker
- A ROS 1 bag with a LiDAR topic and a `sensor_msgs/Imu` topic (ROS 2 bags are
  automatically converted to ROS 1 format). The LiDAR topic is a
  `livox_ros_driver/CustomMsg` (or `livox_ros_driver2/CustomMsg`) for Livox
  sensors and a `sensor_msgs/PointCloud2` for all others.

## Step 1 — Clone with submodules

```bash
git clone https://github.com/MapsHD/benchmark-FMCW-LIO-to-HDMapping.git --recursive
cd benchmark-FMCW-LIO-to-HDMapping
```

## Step 2 — Build the Docker image

```bash
docker build -t fmcw-lio_noetic .
```

This installs:
- Ubuntu 20.04 + ROS 1 Noetic
- Eigen3, PCL, TBB, Ceres (for FMCW-LIO's Free-Init initialization)
- Livox-SDK and livox_ros_driver (Livox message types)
- catkin workspace with `fmcw_lio`, `livox_ros_driver` and `fmcw_lio_to_hdmapping`

## Step 3 — Run the pipeline

```bash
chmod +x docker_session_run-ros1-fmcw-lio.sh
./docker_session_run-ros1-fmcw-lio.sh /path/to/input.bag /path/to/output/dir
```

Or with no arguments to use a GUI file selector (requires `zenity`).

| Variable | Default | Meaning |
|----------|---------|---------|
| `CONFIG_FILE` | `aeva64_fmcw_lio_structured.yaml` | FMCW-LIO parameter file: LiDAR/IMU topics, LiDAR type, LiDAR-IMU extrinsics, noise. A file on the host, or the name of one in FMCW-LIO's [config/](https://github.com/IMRL/FMCW-LIO/tree/main/config) folder |
| `USE_RVIZ` | `1` | RViz live view |
| `PLAY_RATE` | `1.0` | rosbag play rate (lower it if FMCW-LIO cannot keep up) |

FMCW-LIO ships one parameter file per sensor and dataset, for example
`aeva64_fmcw_lio_structured.yaml` (FMCW-LIO dataset, Aeva Aeries II),
`livox_mid360.yaml` (Livox Mid-360), `ouster64_newer_college_dataset.yaml` or
`hesai32_hilti_slam_2022.yaml`; its README lists which file belongs to which
dataset. Select one by name:

```bash
CONFIG_FILE=livox_mid360.yaml \
  ./docker_session_run-ros1-fmcw-lio.sh /path/to/input.bag /path/to/output/dir
```

For your own sensor, copy the closest one, set `common/topic_lidar`,
`common/topic_imu`, `scan_preprocess/lidar_type` and the LiDAR-IMU extrinsics,
and pass the file:

```bash
CONFIG_FILE=/path/to/my_sensor.yaml \
  ./docker_session_run-ros1-fmcw-lio.sh /path/to/input.bag /path/to/output/dir
```

Before anything starts, the script checks that both topics of the parameter
file are in the bag with a type FMCW-LIO reads for that LiDAR type.

**What happens:**

The script opens a Docker container with a tmux session containing five panes on
window 0 and a `control` window (window 1, the attach target):

| Pane | Role |
|------|------|
| 0 | `roscore` |
| 1 | `roslaunch fmcw_lio fmcw_lio_bench.launch` — FMCW-LIO (+ RViz live view) |
| 2 | `rosbag record /odometry /point_cloud_world /clock` |
| 3 | `rosbag play --clock` — plays your input bag |
| 4 | diagnostics — shows active topics and publishing rates |

When playback finishes, the control window stops the recorder, kills all nodes
and RViz, and exits tmux. A second Docker run then converts the recorded bag
into the HDMapping session format.

## Step 4 — Open in HDMapping

Output files appear in `<output_dir>/output_hdmapping-FMCW-LIO/`:

```
lio_initial_poses.reg
poses.reg
scan_lio_0.laz
...
session.json
trajectory_lio_0.csv
...
```

Open `session.json` with the
[multi_view_tls_registration_step_2](https://github.com/MapsHD/HDMapping)
application.

## Notes on FMCW-LIO

FMCW-LIO publishes:

| Topic | Type | Meaning |
|-------|------|---------|
| `/odometry` | `nav_msgs/Odometry` | the 6-DoF IMU (body) pose in the `world` frame, one per scan |
| `/point_cloud_world` | `sensor_msgs/PointCloud2` | the scan in the `world` frame, one per scan (full or downsampled, `publishing/publish_dense_scan`) |
| `/path` | `nav_msgs/Path` | the trajectory so far, for display |

The converter records `/odometry` + `/point_cloud_world`.

**Timestamps:** the benchmark does not change FMCW-LIO's clock (no
`use_sim_time`). FMCW-LIO stamps every output with the scan end time taken from
the input messages, so the result is in bag time; `/clock` is recorded as a
reference and the converter translates the result into bag time only if it is
not (it reports which case applied).

## Contact

januszbedkowski@gmail.com
