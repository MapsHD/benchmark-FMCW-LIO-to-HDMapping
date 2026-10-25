# FMCW-LIO to HDMapping simplified instruction

## Step 1 (prepare data)
Download the dataset `reg-1.bag` by clicking [link](https://cloud.cylab.be/public.php/dav/files/7PgyjbM2CBcakN5/reg-1.bag) or from the [Zenodo](https://zenodo.org/records/23069933) mirror (it is part of [Bunker DVI Dataset](https://charleshamesse.github.io/bunker-dvi-dataset)).

On Zenodo the bag archive is split into `reg-1.zip.part-000`, `reg-1.zip.part-001`, etc.,
download all parts, then merge and extract them:

```bash
cd ~/Downloads
cat reg-1.zip.part-0* > full.zip
zip -F full.zip --out full-fixed.zip
unzip full-fixed.zip
```

File `reg-1.bag` is an input for further calculations.
It should be located in `~/hdmapping-benchmark/data`.

## Step 2 (prepare docker)
```shell
mkdir -p ~/hdmapping-benchmark
cd ~/hdmapping-benchmark
git clone https://github.com/MapsHD/benchmark-FMCW-LIO-to-HDMapping.git --recursive
cd benchmark-FMCW-LIO-to-HDMapping
git checkout Bunker-DVI-Dataset-reg-1
docker build -t fmcw-lio_noetic .
```

## Step 3 (run docker, file `reg-1.bag` should be in `~/hdmapping-benchmark/data`)
```shell
cd ~/hdmapping-benchmark/benchmark-FMCW-LIO-to-HDMapping
chmod +x docker_session_run-ros1-fmcw-lio.sh
cd ~/hdmapping-benchmark/data
~/hdmapping-benchmark/benchmark-FMCW-LIO-to-HDMapping/docker_session_run-ros1-fmcw-lio.sh reg-1.bag .
```

While the bag plays you can watch FMCW-LIO build the map live in RViz:

![FMCW-LIO running in RViz](images/RVIZ.png)

## Step 4 (Open and visualize data)
Expected data should appear in `~/hdmapping-benchmark/data/output_hdmapping-FMCW-LIO`.
Use tool [multi_view_tls_registration_step_2](https://github.com/MapsHD/HDMapping) to open `session.json` from `~/hdmapping-benchmark/data/output_hdmapping-FMCW-LIO`.

![FMCW-LIO session opened in HDMapping multi_view_tls_registration_step_2, top view](images/STEP2_1.png)

![FMCW-LIO session opened in HDMapping multi_view_tls_registration_step_2, side view](images/STEP_2.png)

You should see the following data in folder `~/hdmapping-benchmark/data/output_hdmapping-FMCW-LIO`:

lio_initial_poses.reg

poses.reg

scan_lio_*.laz

session.json

trajectory_lio_*.csv

## Contact email
januszbedkowski@gmail.com
