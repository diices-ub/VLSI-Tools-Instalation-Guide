# 🛠️ Open-Source ASIC Design Flow Installation Guide (SkyWater 130nm & OpenLane 2)

<div align="center">

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04%20%7C%2024.04-orange.svg)
![OpenLane](https://img.shields.io/badge/OpenLane-2.x-blue.svg)
![Sky130](https://img.shields.io/badge/PDK-SkyWater%20130nm-brightgreen.svg)
![Docker](https://img.shields.io/badge/Docker-Engine%2024%2B-blue.svg)

Panduan instalasi lengkap, terstruktur, dan teruji untuk membangun lingkungan **IC Design Analog & Digital** open-source berbasis **OpenLane 2** dan **SkyWater 130nm PDK** di Ubuntu Linux.

</div>

---

# 📚 Table of Contents
1. [System Prerequisites](#1-system-prerequisites)
2. [Arsitektur Lingkungan Desain](#2-arsitektur-lingkungan-desain)
3. [Langkah 1: System Dependencies & Build Tools](#3-langkah-1-system-dependencies--build-tools)
4. [Langkah 2: Docker Engine & Non-Root Setup](#4-langkah-2-docker-engine--non-root-setup)
5. [Langkah 3: OpenLane 2 & SkyWater 130nm PDK Setup](#5-langkah-3-openlane-2--skywater-130nm-pdk-setup)
6. [Langkah 4: Kompilasi Host EDA Tools (Xschem, Magic, Ngspice, Netgen, Irsim, KLayout)](#6-langkah-4-kompilasi-host-eda-tools)
7. [Langkah 5: Konfigurasi Environment Variables & Symlinks](#7-langkah-5-konfigurasi-environment-variables--symlinks)
8. [Langkah 6: Verifikasi & Uji Desain Contoh](#8-langkah-6-verifikasi--uji-desain-contoh)
9. [Troubleshooting](#9-troubleshooting)

---

# 1. System Prerequisites

| Requirement | Spesifikasi Minimum | Rekomendasi |
|------------|---------------------|-------------|
| **OS** | Ubuntu 20.04 / 22.04 / 24.04 LTS (x86_64) | Ubuntu 22.04 LTS |
| **Processor** | Quad-Core CPU @ 2.0 GHz+ | Multi-core (8+ Cores) |
| **RAM** | 8 GiB | 16 GiB atau lebih |
| **Disk Space** | ≥ 25 GB free space (SSD) | ≥ 40 GB free space |
| **Internet** | Koneksi stabil | Diperlukan saat mengunduh Docker image & PDK |

---

# 2. Arsitektur Lingkungan Desain

Tools dibagi menjadi 2 ekosistem yang terintegrasi menggunakan **PDK yang sama**:

```text
 💻 Ubuntu Host OS (Aplikasi GUI Interaktif)       🐳 Docker Container (OpenLane 2)
┌──────────────────────────────────────────┐     ┌──────────────────────────────────┐
│ • Xschem  : Editor Skematik Analog       │     │ • Yosys      : Logika Sintesis   │
│ • Magic   : Editor Layout & DRC          │     │ • OpenROAD   : PnR Otomatis      │
│ • Ngspice : Simulator SPICE              │     │ • Signoff    : DRC/LVS Digital   │
│ • Netgen  : LVS (Layout vs Schematic)    │     └────────────────┬─────────────────┘
│ • KLayout : GDSII/OASIS Viewer           │                      │
└────────────────────┬─────────────────────┘                      │
                     │                                            │
                     └───────────────► 📂 PDK ◄───────────────────┘
                                (~/.volare/sky130A)
```

---

# 3. Langkah 1: System Dependencies & Build Tools

Jalankan perintah berikut untuk memperbarui sistem dan memasang seluruh pustaka kompilasi sekaligus:

```bash
sudo apt-get update && sudo apt-get upgrade -y

# Dependencies kompilasi C/C++, Tcl/Tk, X11, Python, dan EDA
sudo apt-get install -y \
    build-essential gcc g++ make perl git curl wget \
    python3 python3-pip python3-venv python3-tk python3-dev \
    m4 tcsh csh \
    libx11-dev libx11-xcb-dev libxpm-dev libxaw7-dev \
    tcl-dev tcllib tk-dev \
    libcairo2-dev mesa-common-dev libglu1-mesa-dev \
    libncurses-dev clang \
    bison flex libreadline-dev gawk \
    libffi-dev graphviz xdot pkg-config \
    adms autoconf automake libtool \
    libgtk-3-dev libssl-dev zlib1g-dev \
    libboost-system-dev libboost-python-dev libboost-filesystem-dev \
    xterm graphicsmagick ghostscript vim
```

Konfigurasi identitas Git:
```bash
git config --global user.name "Your Name"
git config --global user.email "email@domain.com"
```

---

# 4. Langkah 2: Docker Engine & Non-Root Setup

OpenLane 2 membutuhkan Docker Engine dengan hak akses non-root.

### 4.1 Hapus Versi Lama (Jika Ada)
```bash
sudo apt-get remove -y docker docker-engine docker.io containerd runc
```

### 4.2 Tambah Repositori Resmi Docker
```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 4.3 Install Docker Engine & Aktifkan Service
```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo systemctl start docker
```

### 4.4 Berikan Hak Akses Docker Tanpa Root (WAJIB ⚠️)
```bash
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER
newgrp docker
```

Verifikasi Docker non-root:
```bash
docker run --rm hello-world
```
*(Harus menampilkan: `Hello from Docker!` tanpa error).*

---

# 5. Langkah 3: OpenLane 2 & SkyWater 130nm PDK Setup

### 5.1 Buat Python Virtual Environment untuk OpenLane 2
```bash
# Buat direktori venv terisolasi
python3 -m venv ~/.venv/openlane

# Aktifkan venv dan install openlane + volare
source ~/.venv/openlane/bin/activate
pip install --upgrade pip
pip install openlane volare
```

### 5.2 Pasang dan Aktifkan PDK Sky130 via Volare (Otomatis & Anti-Gagal)
Jalankan baris berikut untuk langsung mengunduh dan membuat *symlink* versi stabil terbaru:
```bash
export PDK_ROOT=$HOME/.volare
mkdir -p $PDK_ROOT

# Mengambil hash commit terbaru secara otomatis dan mengaktifkannya
LATEST_PDK=$(volare ls-remote --pdk sky130 | grep -oE '[a-f0-9]{40}' | head -n 1)
volare enable --pdk sky130 $LATEST_PDK
```

Verifikasi symlink PDK di host:
```bash
ls -l ~/.volare/sky130A
```
*(Pasti langsung mengarah ke direktori PDK yang valid).*

### 5.3 Jalankan OpenLane 2 Smoke Test
```bash
python3 -m openlane --dockerized --smoke-test
```
> ⏳ *Catatan:* Perintah ini akan mengunduh Docker image resmi OpenLane 2 (~1.5 GB) dan menjalankan uji end-to-end (78 tahap). Tunggu hingga keluar pesan: **`Smoke test passed.`**

---

# 6. Langkah 4: Kompilasi Host EDA Tools

Tools ini berjalan langsung di desktop Ubuntu untuk kebutuhan desain analog, simulasi, dan tata letak manual.

### 6.1 Persiapan Folder Kerja
```bash
mkdir -p ~/open_source/tools
cd ~/open_source/tools
```

---

### 6.2 Xschem (Schematic Capture)
```bash
cd ~/open_source/tools
git clone https://github.com/StefanSchippers/xschem.git
cd xschem
./configure
make -j$(nproc)
sudo make install
```

---

### 6.3 Ngspice (SPICE Engine)
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
```

---

### 6.4 GAW (Waveform Viewer - Opsional)
```bash
cd ~/open_source/tools
git clone https://github.com/StefanSchippers/xschem-gaw.git
cd xschem-gaw
aclocal && automake --add-missing && autoconf
./configure
make -j$(nproc)
sudo make install
```

---

### 6.5 Magic (Layout Editor & DRC)
```bash
cd ~/open_source/tools
git clone https://github.com/RTimothyEdwards/magic.git
cd magic
./configure
make -j$(nproc)
sudo make install
```

---

### 6.6 Netgen (LVS Tool)
```bash
cd ~/open_source/tools
git clone https://github.com/RTimothyEdwards/netgen.git
cd netgen
./configure
make -j$(nproc)
sudo make install
```

---

### 6.7 Irsim (Digital Switch Simulator)
```bash
cd ~/open_source/tools
git clone https://github.com/RTimothyEdwards/irsim.git
cd irsim
./configure
make -j$(nproc)
sudo make install
```

---

### 6.8 KLayout (Layout & Mask Viewer)
```bash
sudo apt-get install -y klayout
```

---

# 7. Langkah 5: Konfigurasi Environment Variables & Symlinks

### 7.1 Setup Folder Kerja Netgen & Irsim
```bash
mkdir -p ~/design/{netgen,irsim}

# Symlink setup file Netgen
ln -sf $HOME/.volare/sky130A/libs.tech/netgen/setup.tcl ~/design/netgen/sky130A_setup.tcl
ln -sf $HOME/.volare/sky130B/libs.tech/netgen/setup.tcl ~/design/netgen/sky130B_setup.tcl

# Symlink library Irsim
ln -sf $HOME/.volare/sky130A/libs.tech/irsim ~/design/irsim/irsim_sky130A
ln -sf $HOME/.volare/sky130B/libs.tech/irsim ~/design/irsim/irsim_sky130B

# Symlink tech file KLayout
mkdir -p ~/.klayout/tech
ln -sf $HOME/.volare/sky130A/libs.tech/klayout ~/.klayout/tech/sky130A
```

---

### 7.2 Konfigurasi `~/.bashrc`
Buka file `~/.bashrc`:
```bash
nano ~/.bashrc
```

Tambahkan baris berikut di bagian paling bawah:

```bash
# =========================================================
# Open-Source ASIC Design Flow Environment (SkyWater 130nm)
# =========================================================

# Path PDK Root
export PDK_ROOT=$HOME/.volare

# Tambahkan binary virtual environment OpenLane ke PATH
if [ -d "$HOME/.venv/openlane/bin" ]; then
    export PATH="$HOME/.venv/openlane/bin:$PATH"
fi

# Fungsi penggantian varian PDK (Sky130A vs Sky130B)
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

# Aktifkan default sky130A
set_sky130a

# Aliases untuk Xschem, Magic, dan OpenLane 2
alias magic='magic -rcfile $PDK_ROOT/$PDK/libs.tech/magic/$PDK.magicrc'
alias xschem='xschem --rcfile $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc'
alias openlane='python3 -m openlane --dockerized'
```

Simpan file (`Ctrl + O`, `Enter`, lalu `Ctrl + X`), lalu muat ulang:
```bash
source ~/.bashrc
```

---

# 8. Langkah 6: Verifikasi & Uji Desain Contoh

### 8.1 Verifikasi Cepat Peluncuran Tools
Jalankan satu per satu di terminal untuk memastikan tidak ada error konfigurasi:
1. `xschem` ➡️ Harus membuka GUI Xschem dengan pustaka Sky130.
2. `magic` ➡️ Konsol harus mencetak: `Using technology "sky130A"...`.
3. `ngspice` ➡️ Harus membuka prompt `ngspice 1 ->` (ketik `quit` untuk keluar).
4. `openlane --version` ➡️ Menampilkan versi OpenLane 2.

---

### 8.2 Uji Coba Proyek Lengkap (Inverter Design)
Clone repositori contoh:
```bash
cd ~
git clone https://github.com/raisrmdhnar2/VLSI_Inverter_Design
cd VLSI_Inverter_Design
```

#### A. Alur Analog: Skematik, Layout, LVS, & Simulasi
Masuk ke direktori:
```bash
cd ~/VLSI_Inverter_Design/Analog
```

1. **Buka Skematik**:
   ```bash
   xschem InverterX.sch
   ```
2. **Buka Layout**:
   ```bash
   magic inverter.mag
   ```
   *(Tekan tombol **`x`** untuk unhide seluruh layer transistor & metal).*
3. **Jalankan LVS (Layout vs Schematic)**:
   ```bash
   netgen
   ```
   Di dalam konsol Netgen:
   ```tcl
   lvs {inverter_layout.spice inverter} {Inverter_schematic.spice InverterX} ~/design/netgen/sky130A_setup.tcl
   ```
   *(Output sukses: `Circuits match uniquely`)*
4. **Simulasi SPICE**:
   ```bash
   ngspice tb.spice
   ```

---

#### B. Alur Digital: Sintesis Otomatis RTL-to-GDSII dengan OpenLane 2
```bash
# Jalankan flow OpenLane 2 langsung ke folder desain digital
openlane --dockerized ~/VLSI_Inverter_Design/Digital/inverter
```

Setelah alur selesai (**`Flow complete`**), buka hasil GDSII layout menggunakan KLayout:
```bash
cd ~/VLSI_Inverter_Design/Digital/inverter/runs/
klayout $(find . -name "*.gds" | tail -n 1)
```

---

# 9. Troubleshooting

| Masalah | Penyebab | Solusi |
|---------|----------|--------|
| `Got permission denied while trying to connect to Docker daemon` | User belum aktif di grup docker | Jalankan `sudo usermod -aG docker $USER && newgrp docker` atau restart PC (`sudo reboot`). |
| `cannot find /home/.../.volare/sky130A/libs.tech/xschem/xschemrc` | Symlink PDK belum dibuat | Jalankan `volare enable --pdk sky130 $(volare ls-remote --pdk sky130 \| grep -oE '[a-f0-9]{40}' \| head -n 1)`. |
| `Command 'openlane' not found` | Virtualenv belum masuk PATH | Jalankan `source ~/.venv/openlane/bin/activate` atau pastikan blok `.bashrc` di Bab 7 sudah di-source. |
| Subcell layout di Magic terlihat kotak hitam | Hierarki tersembunyi secara default | Sorot seluruh area layout dengan mouse, lalu tekan tombol **`x`** di keyboard. |

---

# 🎉 Selesai!

Lingkungan **OpenLane 2 & SkyWater 130nm ASIC Design Flow** Anda kini 100% siap digunakan untuk:
- ✅ Desain Skematik & Analisis Rangkaian dengan **Xschem**
- ✅ Simulasi Sirkuit Analog & Mixed-Signal dengan **Ngspice**
- ✅ Desain Layout Kustom & DRC dengan **Magic**
- ✅ Verifikasi Fisik LVS dengan **Netgen**
- ✅ Alur Otomatis RTL-to-GDSII Digital dengan **OpenLane 2**

**Selamat Berkarya & Happy Tape-Out! 🚀**
