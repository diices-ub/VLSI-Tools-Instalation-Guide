# 🛠️ Open-Source ASIC Design Flow Installation Guide (SkyWater 130nm & OpenLane 2)

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04%20%7C%2024.04-orange.svg)
![OpenLane](https://img.shields.io/badge/OpenLane-2.x-blue.svg)
![Sky130](https://img.shields.io/badge/PDK-SkyWater%20130nm-brightgreen.svg)
![Docker](https://img.shields.io/badge/Docker-Engine%2024%2B-blue.svg)

A comprehensive, production-grade guide for installing and configuring **open-source analog and digital VLSI design tools** powered by **OpenLane 2** and the **SkyWater 130nm PDK**.
</div>

---

# 🎯 Target Audience

- 🎓 IC Design students, researchers, and hobbyists
- 🔰 Analog & Mixed-Signal (AMS) VLSI learners
- 💻 Users of Xschem, Ngspice, Magic, Netgen, Irsim, and KLayout
- 🐧 Ubuntu Linux operating system (20.04 LTS, 22.04 LTS, 24.04 LTS)

---

# 📚 Table of Contents
1. [System Prerequisites](#1-system-prerequisites)
2. [Tools & Architecture Overview](#2-tools--architecture-overview)
3. [Docker Engine Installation & Non-Root Setup](#3-docker-engine-installation--non-root-setup)
4. [System Dependencies Installation](#4-system-dependencies-installation)
5. [EDA Tools Installation (From Source)](#5-eda-tools-installation-from-source)
6. [OpenLane 2 & Sky130 PDK Setup](#6-openlane-2--sky130-pdk-setup)
7. [Environment Variables & PDK Integration](#7-environment-variables--pdk-integration)
8. [Running Design Examples & Simulations](#8-running-design-examples--simulations)
9. [Troubleshooting & Pro Tips](#9-troubleshooting--pro-tips)

---

# 1. System Prerequisites

| Requirement | Minimum Specification | Recommended Specification |
|------------|------------------------|---------------------------|
| **OS** | Ubuntu 20.04 LTS (x86_64) | Ubuntu 22.04 / 24.04 LTS |
| **CPU** | Quad-core CPU @ 2.0 GHz+ | 6th Gen Intel Core / AMD Ryzen 1000+ (8+ cores) |
| **RAM** | 8 GiB | 16 GiB or more |
| **Storage** | ≥ 25 GB free disk space (SSD) | ≥ 40 GB free space |
| **Network**| Stable High-Speed Internet | Required for Docker images & PDK tarballs |

> 📷 *Example of Ubuntu Environment*  
> ![Ubuntu Environment](images/ubuntu.png)

---

# 2. Tools & Architecture Overview

| Tool | Category | Role / Description |
|------|----------|--------------------|
| **OpenLane 2** | Digital Flow | Next-generation Python-driven RTL-to-GDSII flow infrastructure |
| **Volare** | PDK Manager | Automated versioned installer & manager for open-source PDKs |
| **Xschem** | Analog / Front-end | Schematic capture & Netlist generation (SPICE/Verilog) |
| **Ngspice** | Simulation | Mixed-signal / SPICE engine (with XSpice & OpenMP support) |
| **GAW** | Waveform Viewer | Analog waveform viewer for Xschem & Ngspice |
| **Magic** | Layout / Physical | VLSI layout editor, DRC checker, and parasitic extraction |
| **Netgen** | Verification | LVS (Layout vs. Schematic) tool |
| **Irsim** | Digital Simulation | Switch-level digital simulator |
| **KLayout** | Layout / Tape-out | High-performance GDSII/OASIS viewer and mask data editor |
| **Docker** | Containerization | Sandboxed container runtime powering OpenLane 2 flows |

> 📷 *Analog & Digital IC Design Flow*  
> ![Analog Flow](images/flow.png)

---

# 3. Docker Engine Installation & Non-Root Setup

OpenLane 2 runs all synthesis, placement, routing, and signoff tools inside containerized environments via Docker. **Configuring Docker for non-root execution is mandatory.**

## 3.1 Remove Old / Conflicting Docker Packages
```bash
sudo apt-get remove -y docker docker-engine docker.io containerd runc
```

## 3.2 Add Docker's Official GPG Key & APT Repository
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Create keyring directory
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository to APT sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

## 3.3 Install Docker Engine & Plugins
```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 3.4 Enable Docker Service on Boot
```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo systemctl start docker
```

## 3.5 Configure Non-Root Access (CRITICAL ⚠️)
Without this step, OpenLane 2 will fail with socket permission errors.

```bash
# Create docker group (if not already present)
sudo groupadd docker

# Add your current user to the docker group
sudo usermod -aG docker $USER

# Apply group changes to current subshell (or reboot)
newgrp docker
```

> ⚠️ **IMPORTANT**: It is strongly recommended to restart your machine (`sudo reboot`) or log out and log back in to ensure Docker group permissions apply system-wide.

## 3.6 Verify Non-Root Docker
Test Docker without using `sudo`:
```bash
docker run --rm hello-world
```
If you see `Hello from Docker!`, your Docker daemon is properly configured!

---

# 4. System Dependencies Installation

## 4.1 System Update & Git Configuration
```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y build-essential gcc g++ make perl git curl
```

Configure your Git identity:
```bash
git config --global user.name "Your Name"
git config --global user.email "email@domain.com"
```

## 4.2 Python Environment & OpenLane 2 Prerequisites
```bash
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-tk \
    python3-dev
```

## 4.3 EDA Compilation Libraries (Host Tools)
Install libraries required to compile Xschem, Ngspice, Magic, Netgen, and Irsim:
```bash
sudo apt-get install -y \
    m4 tcsh csh \
    libx11-dev libx11-xcb-dev \
    tcl-dev tcllib tk-dev \
    libcairo2-dev mesa-common-dev libglu1-mesa-dev \
    libncurses-dev clang \
    bison flex libreadline-dev gawk \
    libffi-dev graphviz xdot pkg-config \
    adms autoconf automake libtool \
    libxpm-dev libxaw7-dev libssl-dev \
    libgtk-3-dev \
    libboost-system-dev libboost-python-dev libboost-filesystem-dev \
    zlib1g-dev \
    xterm graphicsmagick ghostscript vim
```

---

# 5. EDA Tools Installation (From Source)

Prepare your build directory:
```bash
mkdir -p ~/open_source/tools
cd ~/open_source/tools
```

---

## 5.1 Xschem (Schematic Editor)
```bash
cd ~/open_source/tools
git clone https://github.com/StefanSchippers/xschem.git
cd xschem
./configure
make -j$(nproc)
sudo make install
cd ..
```
> 📷 *Xschem Capture*  
> ![Xschem](images/xschem-1.png)

---

## 5.2 Ngspice (SPICE Simulator)
```bash
cd ~/open_source/tools
git clone https://git.code.sf.net/p/ngspice/ngspice ngspice_git
cd ngspice_git
./autogen.sh --adms
mkdir -p release && cd release
../configure \
    --with-x \
    --enable-xspice \
    --enable-cider \
    --enable-openmp \
    --with-readline=yes \
    --disable-debug
make -j$(nproc)
sudo make install
cd ../..
```
> 📷 *Ngspice CLI*  
> ![Ngspice](images/ngspice-1.png)

---

## 5.3 GAW (Waveform Viewer - Optional)
```bash
cd ~/open_source/tools
git clone https://github.com/StefanSchippers/xschem-gaw
cd xschem-gaw
aclocal
automake --add-missing
autoconf
./configure
make -j$(nproc)
sudo make install
cd ..
```
> 📷 *GAW Waveform*  
> ![GAW](images/gaw-1.png)

---

## 5.4 Magic (Layout Editor & DRC)
```bash
cd ~/open_source/tools
git clone https://github.com/RTimothyEdwards/magic
cd magic
./configure
make -j$(nproc)
sudo make install
cd ..
```
> 📷 *Magic Layout Editor*  
> ![Magic](images/magic-1.png)

---

## 5.5 Netgen (LVS Tool)
```bash
cd ~/open_source/tools
git clone https://github.com/RTimothyEdwards/netgen
cd netgen
./configure
make -j$(nproc)
sudo make install
cd ..
```
> 📷 *Netgen LVS*  
> ![Netgen](images/netgen-1.png)

---

## 5.6 Irsim (Switch-Level Digital Simulator)
```bash
cd ~/open_source/tools
git clone https://github.com/RTimothyEdwards/irsim
cd irsim
./configure
make -j$(nproc)
sudo make install
cd ..
```

---

## 5.7 KLayout (Layout Viewer & GDS Editor)

Install Qt5 dependencies:
```bash
sudo apt-get install -y \
  qtbase5-dev qttools5-dev libqt5xmlpatterns5-dev \
  qtmultimedia5-dev libqt5multimediawidgets5 libqt5svg5-dev \
  ruby ruby-dev \
  libz-dev
```

You can install KLayout via APT or download the latest official `.deb` package:

### Option A: Install via APT (Simple)
```bash
sudo apt-get install -y klayout
```

### Option B: Install Latest `.deb` from Official Site
1. Visit: [https://www.klayout.de/build.html](https://www.klayout.de/build.html)
2. Download the `.deb` matching your Ubuntu version (e.g., `klayout_0.30.x_amd64.deb`).
3. Install:
```bash
cd ~/Downloads
sudo dpkg -i klayout_*.deb
sudo apt-get install -f -y
```

---

# 6. OpenLane 2 & Sky130 PDK Setup

Unlike OpenLane 1 (which used git repositories and Makefiles), **OpenLane 2** is a modular Python package distributed via PyPI that interacts with pre-built, version-pinned Docker images and manages PDKs using **Volare**.

## 6.1 Install OpenLane 2 via Python Virtual Environment (Recommended)

To avoid breaking system-managed Python packages on modern Ubuntu (22.04 / 24.04), create a dedicated virtual environment:

```bash
# Create and activate virtual environment
python3 -m venv ~/.venv/openlane
source ~/.venv/openlane/bin/activate

# Upgrade pip and install OpenLane 2 and Volare
python3 -m pip install --upgrade pip
python3 -m pip install openlane volare
```

> 💡 **Tip:** If you prefer installing directly to your user path without a virtual environment:
> ```bash
> python3 -m pip install --upgrade pip
> python3 -m pip install --user openlane volare
> ```

## 6.2 Install & Enable the SkyWater 130nm PDK via Volare

Volare downloads pre-built, verified PDK builds into `~/.volare`:

```bash
# Ensure PDK_ROOT is set
export PDK_ROOT=$HOME/.volare
mkdir -p $PDK_ROOT

# Download and enable the latest compatible SkyWater 130nm PDK
volare enable --pdk sky130
```

Check the active PDK version:
```bash
volare ls --pdk sky130
```

## 6.3 Run the OpenLane 2 Smoke Test

Run the built-in smoke test to verify Docker integration, PDK mounting, and execution:

```bash
# If using the venv, ensure it is active: source ~/.venv/openlane/bin/activate
python3 -m openlane --dockerized --smoke-test
```

> ⏳ *Note:* The first run will automatically pull the required OpenLane 2 Docker image. This may take 5–10 minutes depending on your internet connection.
>
> ✅ **Expected Result**: A success message indicating that the synthesis, placement, routing, and signoff flow passed the smoke test.

---

# 7. Environment Variables & PDK Integration

To ensure host tools (Xschem, Magic, Ngspice, Netgen, Irsim, KLayout) can find the Sky130 PDK installed by Volare, configure your environment variables.

## 7.1 Setup Design Directories
```bash
mkdir -p ~/design/{netgen,irsim}
```

## 7.2 Configure `.bashrc`

Open `~/.bashrc`:
```bash
nano ~/.bashrc
```

Append the following configuration to the bottom:

```bash
# ==========================================
# OpenLane 2 & SkyWater 130nm PDK Setup
# ==========================================
# PDK Root location used by Volare and OpenLane 2
export PDK_ROOT=$HOME/.volare

# OpenLane 2 Virtual Environment (optional auto-activate)
if [ -f "$HOME/.venv/openlane/bin/activate" ]; then
    alias activate_openlane="source $HOME/.venv/openlane/bin/activate"
fi

# Switch PDK Variants (Sky130A vs Sky130B)
set_sky130a() {
    export PDK=sky130A
    if [ -f "$PDK_ROOT/$PDK/libs.tech/ngspice/spinit" ]; then
        ln -sf "$PDK_ROOT/$PDK/libs.tech/ngspice/spinit" ~/.spiceinit
    fi
    if [[ -t 1 ]]; then
        echo "Active PDK is now: $PDK"
    fi
}

set_sky130b() {
    export PDK=sky130B
    if [ -f "$PDK_ROOT/$PDK/libs.tech/ngspice/spinit" ]; then
        ln -sf "$PDK_ROOT/$PDK/libs.tech/ngspice/spinit" ~/.spiceinit
    fi
    if [[ -t 1 ]]; then
        echo "Active PDK is now: $PDK"
    fi
}

# Set default PDK to sky130A
set_sky130a

# Aliases for Magic & Xschem with PDK tech files
alias magic='magic -rcfile $PDK_ROOT/$PDK/libs.tech/magic/$PDK.magicrc'
alias xschem='xschem --rcfile $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc'
alias openlane='python3 -m openlane --dockerized'
```

Save and exit (`Ctrl + O`, `Enter`, then `Ctrl + X`).

Reload your shell:
```bash
source ~/.bashrc
```

Verify your environment:
```bash
echo $PDK_ROOT
# Expected: /home/<username>/.volare
```

---

## 7.3 Tool-Specific Integrations

### Netgen LVS Setup
```bash
cd ~/design/netgen
ln -sf $PDK_ROOT/sky130A/libs.tech/netgen/setup.tcl sky130A_setup.tcl
ln -sf $PDK_ROOT/sky130B/libs.tech/netgen/setup.tcl sky130B_setup.tcl
```

### Irsim Setup
```bash
cd ~/design/irsim
ln -sf $PDK_ROOT/sky130A/libs.tech/irsim irsim_sky130A
ln -sf $PDK_ROOT/sky130B/libs.tech/irsim irsim_sky130B
```

### KLayout Tech Files
```bash
mkdir -p ~/.klayout/tech
cd ~/.klayout/tech
ln -sf $PDK_ROOT/sky130A/libs.tech/klayout sky130A
```

---

# 8. Running Design Examples & Simulations

Clone the reference VLSI Inverter repository:
```bash
cd ~
git clone https://github.com/raisrmdhnar2/VLSI_Inverter_Design
cd VLSI_Inverter_Design
```

---

## 8.1 Analog Design Flow: Schematic, Layout, LVS, & Simulation

```bash
cd ~/VLSI_Inverter_Design/Analog
```

### 1. View Schematic (Xschem)
```bash
xschem InverterX.sch
```
> 📷 *Analog Inverter Schematic*  
> ![Analog Inverter Schematic](Results/inverter_schem.png)

### 2. View Layout (Magic)
```bash
magic inverter.mag
```
> 📷 *Analog Inverter Layout*  
> ![Analog Inverter Layout](Results/Layout_inverter.png)

### 3. Run LVS (Netgen)
Inside your terminal:
```bash
netgen
```
Then execute inside Netgen:
```tcl
lvs {inverter_layout.spice inverter} {Inverter_schematic.spice InverterX} sky130A_setup.tcl
```
> 📷 *LVS Results*  
> ![LVS Result](Results/Inverter_LVS.png)

### 4. Run SPICE Transient Simulation (Ngspice)
```bash
ngspice tb.spice
```
> 📷 *Ngspice Transient Simulation*  
> ![Spice Simulation](Results/analog_inverter_simulation.png)

---

## 8.2 Digital Design Flow with OpenLane 2

In OpenLane 2, designs are configured with a `config.json` or `config.yaml` file (classic `.tcl` is also supported) and run directly using the `openlane` command.

### 1. Running RTL-to-GDSII with OpenLane 2

To synthesize, place, route, and signoff a digital block:

```bash
# If using venv:
source ~/.venv/openlane/bin/activate

# Run OpenLane 2 in Dockerized mode:
openlane --dockerized ~/VLSI_Inverter_Design/Digital/inverter
```

*(Alternatively, run interactive bash inside the OpenLane 2 container with your home & PDK mounted:)*
```bash
openlane --dockerized
```

### 2. Inspecting Layout Results (KLayout)
After OpenLane finishes, inspect the final GDSII file:
```bash
cd ~/VLSI_Inverter_Design/Digital/inverter/runs
# Navigate to the latest run directory results/final/gds/
klayout inverter.gds
```
> 📷 *Digital Inverter GDS in KLayout*  
> ![Digital Klayout Inverter](Results/klayout_inverter.png)

### 3. Inspecting Layout in Magic
```bash
# Inside results/final/mag/
magic inverter.mag
```
> 💡 *Tip:* Press **`v`** to fit view, or select all and press **`x`** to unhide subcell hierarchy.

### 4. Switch-Level Digital Simulation (Irsim)
```bash
irsim sky130A_tt_nom_27.prm inverter.sim
```
Inside IRSIM terminal:
```tcl
source tb_inverter_irsim.cmd
```
> 📷 *Digital Simulation via Irsim*  
> ![Digital Simulation Irsim](Results/Digital_Inverter_Simulation_irsim.png)

---

# 9. Troubleshooting & Pro Tips

## 💡 Quick Tips
- 🔍 **Unhide Magic Hierarchy:** In Magic, subcells are hidden by default. Click and drag to select everything, then press **`x`** (expand) to show all layer details. Press **`Shift + Z`** / **`Ctrl + Z`** to zoom.
- ⚡ **Interactive Container:** To debug OpenLane 2 steps interactively, invoke `python3 -m openlane --dockerized` without arguments to drop into a container shell with your workspace mounted.
- 🔄 **PDK Switching:** Run `set_sky130a` or `set_sky130b` in your terminal anytime to switch between Sky130 process variations.

## 🔧 Troubleshooting Matrix

| Issue / Error | Cause | Solution |
|--------------|-------|----------|
| `Got permission denied while trying to connect to Docker daemon` | User not in `docker` group | Run `sudo usermod -aG docker $USER`, then run `newgrp docker` or reboot your machine. |
| `externally-managed-environment` when installing OpenLane | Ubuntu 22.04+ PEP 668 restriction | Use Python venv (`python3 -m venv ~/.venv/openlane && source ~/.venv/openlane/bin/activate`) before running `pip install`. |
| `PDK sky130 not found` or `PDK_ROOT not set` | Missing Volare PDK download | Run `export PDK_ROOT=$HOME/.volare && volare enable --pdk sky130`. |
| `Cannot find tech file: sky130A.magicrc` | Incorrect PDK path or missing alias | Ensure `PDK_ROOT` points to `$HOME/.volare` and verify `$PDK_ROOT/sky130A` exists. |
| Xschem cannot find symbols | Missing `xschemrc` configuration | Run Xschem using the provided alias `xschem`, which automatically passes the PDK rcfile. |

---

# 📖 Additional Resources

- 🌐 [OpenLane 2 GitHub Repository](https://github.com/The-OpenROAD-Project/OpenLane)
- 📖 [OpenLane 2 Documentation](https://openlane.readthedocs.io/en/latest/)
- 📦 [Volare PDK Manager Documentation](https://efabless.github.io/volare/)
- 📘 [SkyWater 130nm PDK Documentation](https://skywater-pdk.readthedocs.io/)
- 📐 [Xschem Manual](http://repo.hu/projects/xschem/)
- 🪄 [Magic VLSI Website](http://opencircuitdesign.com/magic/)

---

# 🎉 Congratulations!

Your complete **OpenLane 2 + SkyWater 130nm ASIC Design Environment** is fully operational!

- ✅ Schematic Capture & Netlisting with **Xschem**
- ✅ Analog Simulation with **Ngspice**
- ✅ Custom Physical Layout with **Magic**
- ✅ Physical Verification & LVS with **Netgen**
- ✅ Automated RTL-to-GDSII Digital Flow with **OpenLane 2**

**Happy Designing & Tape-out! 🚀**

---

<div align="center">
Made with ❤️ for the Open-Source Silicon Community
</div>
