FROM ubuntu:20.04

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# ── Base tools ────────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    lsb-release \
    software-properties-common \
    build-essential \
    cmake \
    git \
    apt-transport-https \
    ca-certificates \
    wget \
    libeigen3-dev \
    libpcl-dev \
    libtbb-dev \
    libceres-dev \
    libapr1-dev \
    libaprutil1-dev \
    nlohmann-json3-dev \
    tmux \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# ── ROS 1 Noetic ─────────────────────────────────────────────────────────────
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
    http://packages.ros.org/ros/ubuntu $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/ros.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-desktop-full \
    ros-noetic-tf \
    ros-noetic-pcl-conversions \
    ros-noetic-pcl-ros \
    ros-noetic-topic-tools \
    ros-noetic-angles \
    python3-rosdep \
    python3-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

# ── rosbags (used to convert ROS 2 bags to ROS 1, if needed) ─────────────────
RUN pip3 install --no-cache-dir "rosbags==0.9.22"

# ── Livox-SDK ────────────────────────────────────────────────────────────────
# Needed by livox_ros_driver (src/livox_ros_driver), which provides the
# livox_ros_driver/CustomMsg FMCW-LIO reads; without it the driver's CMake
# would try to download the SDK during the build.
RUN git clone https://github.com/Livox-SDK/Livox-SDK.git /tmp/Livox-SDK && \
    cd /tmp/Livox-SDK/build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/Livox-SDK

# ── Build catkin workspace (FMCW-LIO + livox_ros_driver + converter) ─────────
WORKDIR /ros_ws

COPY ./src/FMCW-LIO              ./src/FMCW-LIO
COPY ./src/livox_ros_driver      ./src/livox_ros_driver
COPY ./src/fmcw-lio-to-hdmapping ./src/fmcw-lio-to-hdmapping

# Benchmark launch (parameter file as a roslaunch arg) added into the
# fmcw_lio package; preflight check used by the run script.
COPY ./overlay/launch/  ./src/FMCW-LIO/launch/
COPY ./overlay/scripts/ /ros_ws/scripts/

# Build FMCW-LIO (with Free-Init, its default) and the converter. The final
# guard fails the image build loudly if an executable is missing.
RUN source /opt/ros/noetic/setup.bash && \
    catkin_make -DCMAKE_BUILD_TYPE=Release -j$(nproc) && \
    test -f /ros_ws/devel/lib/fmcw_lio/fmcw_lio && \
    test -f /ros_ws/devel/lib/fmcw_lio_to_hdmapping/listener && \
    echo "[build] fmcw_lio and converter present"

# ── Non-root user ─────────────────────────────────────────────────────────────
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID ros && \
    useradd -m -u $UID -g $GID -s /bin/bash ros && \
    chown -R $UID:$GID /ros_ws

RUN echo "source /opt/ros/noetic/setup.bash"   >> /root/.bashrc && \
    echo "source /ros_ws/devel/setup.bash"     >> /root/.bashrc && \
    echo "source /opt/ros/noetic/setup.bash"   >> /home/ros/.bashrc && \
    echo "source /ros_ws/devel/setup.bash"     >> /home/ros/.bashrc

CMD ["bash"]
