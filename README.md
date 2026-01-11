# 🛠️ Open-Source ASIC Design Flow Installation Guide (SkyWater 130nm & OpenLane)

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20|%2022.04-orange.svg)
![Sky130](https://img.shields.io/badge/PDK-SkyWater%20130nm-brightgreen.svg)
![Sky130](images/diices.png)

A comprehensive and well-structured guide for installing and configuring *open-source analog and digital VLSI design tools* integrated with the **SkyWater 130nm PDK**.
</div>

---
# 🎯 Target Audience

- 🎓 IC design students & researchers
- 🔰 Beginner Analog VLSI learners
- 💻 Xschem + Ngspice + Magic users
- 🐧 Ubuntu Linux operating system

---

# 📚 Table of Contents
1. [System Prerequisites](#1-system-prerequisites)
2. [Tools & Their Functions](#2-tools--their-functions)
3. [Docker Installation](#3-docker-installation)
4. [System Dependencies Installation](#4-system-dependencies-installation)
5. [EDA Tools Instalation](#5-eda-tools-instalation)
6. [Setup OpenLane & Sky130 PDK](#6-setup-openlane--sky130-pdk)
7. [Environment Variables Configuration and Tools Integration with Sky130 PDK](#7-environment-variables-configuration-and-tools-integration-with-sky130-pdk)
8. [Running Design Examples and Simulations](#8-running-design-examples-and-simulations)
9. [Notes & Tips](#9-notes--tips)
---

# 1. System Prerequisites

| Requirement | Specification |
|------------|---------------|
| **OS** | Ubuntu 20.04 / 22.04 (recommended) |
| **Disk Space** | ≥ 10 GB |
| **RAM** | ≥ 8 GB |
| **Internet** | Required |
| **Processor** | Multi-core (recommended) |

> 📷 *Example of Ubuntu environment*  
> ![Ubuntu Environment](images/ubuntu.png)

---

# 2. Tools & Their Functions

| Tool | Function | Status |
|------|----------|--------|
| **Xschem** | Schematic capture & netlist generation | ✅ Core |
| **Ngspice** | SPICE simulator | ✅ Core |
| **GAW** | Waveform viewer | 🔶 Optional |
| **Magic** | VLSI layout editor | ✅ Core |
| **Netgen** | LVS (Layout vs. Schematic) | ✅ Core |
| **Irsim** | Digital Simulator | ✅ Core |
| **Docker** | Container platform | ✅ Core |
| **KLayout** | Layout viewer | ✅ Core |

> 📷 *Analog & DIgital IC Design Flow*  
> ![Analog Flow](images/flow.png)

---

# 3. Docker Installation

## 3.1 Remove Old Versions (If Any)

```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

## 3.2 Setup Repository Docker

```bash
# Install prerequisites
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Setup repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

## 3.3 Install Docker Engine

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## 3.4 Verify Installation

```bash
sudo docker run hello-world
```

## 3.5 Add User to Docker Group (Optional)

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```
⚠️ Log out and log back in for the group changes to take effect

## 3.6 Enable Docker di Startup

```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

---

# 4. System Dependencies Installation

## 4.1 System Update

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y build-essential gcc make perl git
```

Git requires an identity for each commit.  

```bash
git config --global user.name "Your Name"
git config --global user.email "email@domain.com"
```

Check configuration:

```bash
git config --global --list
```

## 4.2 EDA Supporting Libraries

```bash
sudo apt install -y \
    m4 tcsh csh \
    libx11-dev libx11-xcb-dev \
    tcl-dev tcllib tk-dev \
    libcairo2-dev mesa-common-dev libglu1-mesa-dev \
    libncurses-dev clang \
    bison flex libreadline-dev gawk \
    libffi-dev graphviz xdot pkg-config \
    python3 python3-pip libboost-system-dev \
    adms autoconf automake libtool \
    libxpm-dev libxaw7-dev libssl-dev \
    libgtk-3-dev libboost-python-dev \
    libboost-filesystem-dev zlib1g-dev \
    xterm graphicsmagick ghostscript vim
```

---

# 5. EDA Tools Instalation

## 5.1 Directory Preparation

```bash
mkdir -p ~/open_source/tools
cd ~/open_source/tools
```

## 5.2 Xschem (Schematic Editor)

```bash
git clone https://github.com/StefanSchippers/xschem.git
cd xschem
./configure
make -j$(nproc)
sudo make install
cd ..
```

> 📷 *Xschem run*  
> ![Xschem](images/xschem-1.png)

## 5.3 Ngspice (Simulator)

```bash
git clone https://git.code.sf.net/p/ngspice/ngspice ngspice_git
cd ngspice_git
./autogen.sh --adms
mkdir release && cd release
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

## 5.4 GAW (🔶 Optional)

```bash
git clone https://github.com/StefanSchippers/xschem-gaw
cd xschem-gaw
aclocal
automake --add-missing
autoconf
./configure
sudo make -j$(nproc)
sudo make install
cd ..
```

> 📷 *GAW waveform*  
> ![GAW](images/gaw-1.png)

## 5.5 Magic (Layout Editor)

```bash
git clone https://github.com/RTimothyEdwards/magic
cd magic
./configure
make -j$(nproc)
sudo make install
cd ..
```

> 📷 *Magic layout editor*  
> ![Magic](images/magic-1.png)

## 5.6 Netgen (LVS Tool)

```bash
git clone https://github.com/RTimothyEdwards/netgen
cd netgen
./configure
make -j$(nproc)
sudo make install
cd ..
```

> 📷 *Netgen LVS*  
> ![Netgen](images/netgen-1.png)

## 5.7 Irsim (Digital Simulator)
```bash
git clone https://github.com/RTimothyEdwards/irsim
cd irsim
./configure
sudo make
sudo make install
cd ..
```

## 5.8 Klayout (Layout Viewer)
```bash
mkdir klayout
cd klayout
sudo apt install \
  gcc g++ make \
  qtbase5-dev qttools5-dev libqt5xmlpatterns5-dev \
  qtmultimedia5-dev libqt5multimediawidgets5 libqt5svg5-dev \
  ruby ruby-dev \
  python3 python3-dev \
  libz-dev

```
Go to:
```bash
https://www.klayout.de/build.html
```
Choose the appropriate Ubuntu version, then download the latest KLayout .deb file.

> 📷 *In this tutorial, select klayout_0.30.5-1_amd64.deb.*  
> ![klayout_deb](images/klayout_deb.png)

Place the KLayout .deb file in this path: ```/open_source/tools/klayout```
Run:
```bash
cd
cd ~/open_source/tools/klayout
sudo dpkg -i (#sesuai nama file yang kalian download)
sudo apt-get install -f
```

---

# 6. Setup OpenLane & Sky130 PDK 

```bash
cd ~
git clone https://github.com/The-OpenROAD-Project/OpenLane
cd OpenLane
make pdk
make test
```

> ⏳ Note: This process may take a long time and requires a stable internet connection.

---

# 7. Environment Variables Configuration And Tools Integration with Sky130 PDK

## 7.1 Setup Directory Desain

```bash
cd
cd open_source
mkdir -p ~/design/{netgen, irsim}
```

## 7.2 PDK Root Configuration and Integration with Xschem, Ngspice, and Magic

 Edit `.bashrc`

```bash
nano ~/.bashrc
```
Add them at the end of the file.  

```bash
# Path PDK
export PDK_ROOT=$HOME/.ciel
set_sky130a() {
    export PDK=sky130A
    ln -sf $PDK_ROOT/sky130A/libs.tech/ngspice/spinit ~/.spiceinit
    if [[ -t 1 ]]; then
     echo "PDK is now set to: $PDK"
    fi
}
set_sky130b() {
    export PDK=sky130B
    ln -sf $PDK_ROOT/sky130B/libs.tech/ngspice/spinit ~/.spiceinit
    if [[ -t 1 ]]; then
     echo "PDK is now set to: $PDK"
    fi
}

set_sky130a
alias magic='magic -rcfile $PDK_ROOT/$PDK/libs.tech/magic/$PDK.magicrc'
alias xschem='xschem --rcfile $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc'
```
Note: Library selection
- Run in terminal: `set_sky130a` to use the Sky130A library
- Run in terminal: `set_sky130b` to use the Sky130B library

## 7.3 Reload Configuration

```bash
source ~/.bashrc
```

## 7.4 Verify Environment Variables, Xschem and magic

```bash
echo $PDK_ROOT
```
> ✅ **Expected output**: The configured paths should appear when checked.

run xschem:
```bash
xschem
```
> 📷 *Xschem is connected to Sky130.*  
> ![Xschem Sky130](images/xshem-2.png)

run magic:
```bash
magic
```
> 📷 *Magic is conected to sky130*  
> ![Magic Sky130](images/magic-2.png)


## 7.5 Netgen

```bash
cd ~/design/netgen

ln -sf $PDK_ROOT/sky130A/libs.tech/netgen/setup.tcl sky130A_setup.tcl
ln -sf $PDK_ROOT/sky130B/libs.tech/netgen/setup.tcl sky130B_setup.tcl

```

> 📷 *Netgen*  
> ![Netgen](images/netgen_pdk.png)

## 7.6 Irsim

```bash
mkdir -p ~/design/irsim
cd ~/design/irsim

ln -sf $PDK_ROOT/sky130A/libs.tech/irsim irsim_sky130A
ln -sf $PDK_ROOT/sky130B/libs.tech/irsim irsim_sky130B

```
> 📷 *Irsim PDK Library*  
> ![irsim_library](Results/irsim_lib.png)

## 7.7 Klayout
```bash
mkdir -p ~/.klayout/tech
cd ~/.klayout/tech

ln -sf $PDK_ROOT/sky130A/libs.tech/klayout sky130A

```

> 📷 *Klayout*  
> ![Klayout Sky130](images/KlayoutSky.png)
---

# 8. Running Design Examples and Simulations
**Note: Make sure all the open-source core tools, OpenLane, and the PDK listed above have been successfully installed.**
run :
```bash
cd
git clone https://github.com/raisrmdhnar2/VLSI_Inverter_Design
cd VLSI_Inverter_Design
```
## 8.1 Inverter Analog Design, LVS and Simulation
```bash
cd Analog
```
### Open the schematic and layout inverter
 Open schematic  : 
```bash
xschem InverterX.sch
```
> 📷 *Analog Inverter Schematic*  
> ![analog inverter schem](Results/inverter_schem.png)
 Open Layout     : 
```bash
magic inverter.mag
```
> 📷 *Analog Inverter Layout*  
> ![analog inverter kayout](Results/Layout_inverter.png)

### run layout vs schematic:
 run in terminal         : 
```bash
netgen
```
run in terminal netgen  :
```bash
lvs {inverter_layout.spice inverter} {Inverter_schematic.spice InverterX} sky130A_setup.tcl
```
> 📷 *LVS Inverter*  
> ![LVS](Results/Inverter_LVS.png)

### Ngspice Simulation
run testbench :
```bash
ngspice tb.spice
```
> 📷 *Inverter Spice Simulation*  
> ![Spice Simulation](Results/analog_inverter_simulation.png)

## 8.2 Inverter Digital Design and Simulation

```bash
cd ..
cd Digital/inverter/runs/inverter_layout/results/final/
```
### Layout Viewer Klayout
Open Layout:
```bash
cd gds
klayout inverter.gds
```
> 📷 *Klayout Digital Inverter*  
> ![Digital Klayout Inverter](Results/klayout_inverter.png)

### Layout Magic
Open layout:
```bash
cd ..
cd mag
magic inverter.mag
```
> 📷 *Digital Layout Inverter Magic*  
> ![Digital Layout Inverter](Results/digital_layout_inverter.png)
> If the layout is still hidden, select (block) all layouts and then click the X button.

### run testbench irsim
In terminal runs : 
```bash
irsim sky130A_tt_nom_27.prm inverter.sim
```
in terminal irsim run: 
```bash
source tb_inverter_irsim.cmd
```
> 📷 *Digital Simulation Irsim*  
> ![Digital Simulation Irsim](Results/Digital_Inverter_Simulation_irsim.png)

### run testbench ngspice
In terminal run: 
```bash
ngspice tb_inverter_spice.spice
```
> 📷 *Digital Simulation Irsim*  
> ![Digital Simulation Irsim](Results/Digital_Inverter_Simulation_Spice.png)

### How to run a design on OpenLane?
Copy the project to designs folder in OpenLane:
```bash
cd
cp -r ~/VLSI_Inverter_Design/Digital/inverter ~/OpenLane/designs
```
enter the container OpenLane:
```bash
cd OpenLane
make mount
```
Run design :
```bash
./flow.tcl -design inverter
```
> 📷 *OpenLane RUns*  
> ![OpenLane Runs](Results/openLane_runs.png)

Check the results:
After the flow completed, you can find the ```results``` in the runs folder inside the project directory.
---
# 9. Notes & Tips

## 💡 General Tips

- ⚠️ Magic usually **hides hierarchy** by default
- 🖱️ Select all areas → press **`x`** to display
- ⏰ Long build times are **normal**
- 💾 Sky130 PDK is **large and storage-intensive**

## 🔧 Troubleshooting

| Issue | Solution |
|------|----------|
| Docker permission denied | Add user to the docker group |
| PDK not detected | Verify `PDK_ROOT` |
| Build error | Make sure all dependencies are installed |

## 📖 Additional Resources

- [SkyWater PDK Documentation](https://skywater-pdk.readthedocs.io/)
- [OpenLane Documentation](https://openlane.readthedocs.io/)
- [Xschem Tutorial](http://repo.hu/projects/xschem/)
- [Magic VLSI](http://opencircuitdesign.com/magic/)

---

# 🎉 DONE!

The **Sky130-based Analog and Digital VLSI Design Environment** is ready to use for:

- ✅ Schematic design with Xschem
- ✅ Circuit simulation with Ngspice
- ✅ Layout design with Magic
- ✅ LVS verification with Netgen
- ✅ Full RTL-to-GDSII flow with OpenLane

**Happy Designing! 🚀**

---

<div align="center">

Made with ❤️ for the Open Source IC Design Community

</div>
---
