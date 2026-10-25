#!/usr/bin/env python3
"""Preflight check for the FMCW-LIO benchmark run.

FMCW-LIO subscribes to the LiDAR and IMU topics named in its parameter file
(common/topic_lidar, common/topic_imu). If either is missing from the bag, or
the LiDAR topic has a type FMCW-LIO does not read, it processes nothing and the
run records no output, so the check stops the run first (exit code 42, the run
script then skips the conversion).

LiDAR message type by scan_preprocess/lidar_type:
  6 (Livox)   livox_ros_driver/CustomMsg; livox_ros_driver2/CustomMsg has the
              same layout and is decoded the same way
  1-5 (Aeva, Hesai, RoboSense, Ouster, Velodyne)   sensor_msgs/PointCloud2

Usage: fmcw_lio_preflight.py <parameter_file.yaml> <input.bag>
"""

import sys

import rosbag
import yaml

LIVOX = 6
LIVOX_TYPES = ("livox_ros_driver/CustomMsg", "livox_ros_driver2/CustomMsg")


def main():
    config_path, bag_path = sys.argv[1], sys.argv[2]
    try:
        with open(config_path) as f:
            config = yaml.safe_load(f)
        lidar_topic = config["common"]["topic_lidar"]
        imu_topic = config["common"]["topic_imu"]
        lidar_type = int(config["scan_preprocess"]["lidar_type"])
    except (OSError, KeyError, TypeError, ValueError, yaml.YAMLError) as e:
        print(f"[preflight] ERROR: cannot read topics and lidar_type from parameter file {config_path}: {e}")
        sys.exit(42)
    lidar_types = LIVOX_TYPES if lidar_type == LIVOX else ("sensor_msgs/PointCloud2",)
    print(f"[preflight] parameter file: {config_path}")
    print(f"[preflight] LiDAR topic: {lidar_topic} (lidar_type {lidar_type})  IMU topic: {imu_topic}")

    bag = rosbag.Bag(bag_path)
    topics = bag.get_type_and_topic_info().topics
    bag.close()

    ok = True
    for name, accepted in ((lidar_topic, lidar_types), (imu_topic, ("sensor_msgs/Imu",))):
        info = topics.get(name)
        if info is None or info.msg_type not in accepted:
            found = info.msg_type if info else "not in the bag"
            print(f"[preflight] ERROR: {name} must be {' or '.join(accepted)} ({found}).")
            ok = False
        else:
            print(f"[preflight] {name}: {info.message_count} msgs ({info.msg_type})")
    if not ok:
        for msg_type in lidar_types + ("sensor_msgs/Imu",):
            names = [t for t, i in topics.items() if i.msg_type == msg_type]
            print(f"[preflight] {msg_type} topics in this bag: {', '.join(names) or '(none)'}")
        print("[preflight] Choose the parameter file of your sensor (CONFIG_FILE) or set "
              "common/topic_lidar, common/topic_imu and scan_preprocess/lidar_type in it.")
        sys.exit(42)


if __name__ == "__main__":
    main()
