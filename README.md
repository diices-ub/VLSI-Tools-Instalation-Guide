# 🚀 Migration Guide: Upgrade from OpenLane 1 to OpenLane 2 (SkyWater 130nm)

<div align="center">

![Migration](https://img.shields.io/badge/Migration-OpenLane%201%20%E2%86%92%20OpenLane%202-blue.svg)
![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm%20(Volare)-brightgreen.svg)
![Status](https://img.shields.io/badge/Host%20Tools-Preserved%20%E2%9C%85-success.svg)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04%20%7C%2024.04-orange.svg)

Panduan praktis untuk membersihkan instalasi **OpenLane 1** lama dan melakukan upgrade ke **OpenLane 2** modern berbasis **Volare**, dengan tetap mempertahankan seluruh tools host yang sudah terpasang (**Xschem, Magic, Ngspice, Netgen, Irsim, KLayout**).

</div>

---

# 📋 Kondisi Awal (Prasyarat)

Panduan ini diasumsikan untuk sistem yang telah menyelesaikan panduan v1.0 sebelumnya:
- [x] Docker Engine sudah terpasang dan dapat dijalankan tanpa `sudo`.
- [x] Host EDA tools (**Xschem, Magic, Ngspice, Netgen, Irsim, KLayout**) sudah terkompilasi di `/usr/local/bin/`.
- [x] Terdapat instalasi OpenLane 1 lama di `~/OpenLane` dan PDK lama di `~/.ciel`.

---

# 📚 Alur Upgrade & Migrasi

1. [Langkah 1: Backup Desain Kustom (Jika Ada)](#1-langkah-1-backup-desain-kustom)
2. [Langkah 2: Bersihkan & Hapus OpenLane 1 (Reclaim Disk Space)](#2-langkah-2-bersihkan--hapus-openlane-1)
3. [Langkah 3: Pasang OpenLane 2 & Volare via Python Virtual Environment](#3-langkah-3-pasang-openlane-2--volare)
4. [Langkah 4: Unduh & Aktifkan PDK Sky130 via Volare](#4-langkah-4-unduh--aktifkan-pdk-sky130-via-volare)
5. [Langkah 5: Perbarui Konfigurasi `.bashrc`](#5-langkah-5-perbarui-konfigurasi-bashrc)
6. [Langkah 6: Perbarui Symlink Integrasi Tools (Netgen, Irsim, KLayout)](#6-langkah-6-perbarui-symlink-integrasi-tools)
7. [Langkah 7: Verifikasi & Uji Alur OpenLane 2](#7-langkah-7-verifikasi--uji-alur-openlane-2)

---

# 1. Langkah 1: Backup Desain Kustom

Sebelum menghapus folder OpenLane 1, pastikan desain yang pernah Anda buat di dalam folder `~/OpenLane/designs/` diselamatkan terlebih dahulu:

```bash
# Buat folder backup jika ada desain penting
mkdir -p ~/backup_designs
cp -r ~/OpenLane/designs/* ~/backup_designs/ 2>/dev/null || true
```

---

# 2. Langkah 2: Bersihkan & Hapus OpenLane 1

OpenLane 1 dan PDK lamanya (`.ciel`) memakan ruang penyimpanan yang sangat besar (bisa mencapai 20–30 GB). Mari kita bersihkan:

### 2.1 Hapus Folder OpenLane 1 & PDK Lama
```bash
# Hapus direktori repositori OpenLane 1
rm -rf ~/OpenLane

# Hapus PDK lama (.ciel) agar tidak tumpang tindih dengan Volare
rm -rf ~/.ciel
```

### 2.2 Hapus Docker Images OpenLane 1 Lama
Cek dan hapus container serta Docker image OpenLane 1 lama untuk menghemat kapasitas disk:
```bash
# Hapus image docker OpenLane v1 lama
docker images | grep -E "efabless/openlane|openroad" | awk '{print $3}' | xargs -r docker rmi -f

# Bersihkan sisa build cache docker yang tidak terpakai
docker system prune -f
```

---

# 3. Langkah 3: Pasang OpenLane 2 & Volare

OpenLane 2 tidak lagi menggunakan `git clone` repositori besar, melainkan berbasis Python package dari PyPI.

### 3.1 Install Dependensi Python (Jika Belum Ada)
```bash
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip python3-tk
```

### 3.2 Buat Virtual Environment & Install OpenLane 2
```bash
# Buat virtual environment khusus
python3 -m venv ~/.venv/openlane

# Aktifkan venv & install openlane + volare
source ~/.venv/openlane/bin/activate
pip install --upgrade pip
pip install openlane volare
```

---

# 4. Langkah 4: Unduh & Aktifkan PDK Sky130 via Volare

Volare adalah manajer PDK resmi modern yang digunakan oleh OpenLane 2:

```bash
export PDK_ROOT=$HOME/.volare
mkdir -p $PDK_ROOT

# Ambil versi commit terbaru dan langsung aktifkan symlink-nya
LATEST_PDK=$(volare ls-remote --pdk sky130 | grep -oE '[a-f0-9]{40}' | head -n 1)
volare enable --pdk sky130 $LATEST_PDK
```

Verifikasi symlink PDK yang baru diaktifkan:
```bash
ls -l ~/.volare/sky130A
```
*(Pastikan direktori `sky130A` menunjuk ke cache commit yang aktif).*

---

# 5. Langkah 5: Perbarui Konfigurasi `.bashrc`

Buka file konfigurasi shell:
```bash
nano ~/.bashrc
```

Cari bagian konfigurasi PDK lama (`export PDK_ROOT=$HOME/.ciel`), lalu **ganti** seluruh blok konfigurasi PDK & OpenLane lama menjadi seperti ini:

```bash
# =========================================================
# OpenLane 2 & SkyWater 130nm PDK Environment
# =========================================================

# Lokasi PDK Root Baru (Volare)
export PDK_ROOT=$HOME/.volare

# Tambahkan CLI OpenLane 2 & Volare ke PATH global
if [ -d "$HOME/.venv/openlane/bin" ]; then
    export PATH="$HOME/.venv/openlane/bin:$PATH"
fi

# Fungsi Pergantian Varian PDK
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

# Default PDK
set_sky130a

# Aliases Host Tools & OpenLane 2
alias magic='magic -rcfile $PDK_ROOT/$PDK/libs.tech/magic/$PDK.magicrc'
alias xschem='xschem --rcfile $PDK_ROOT/$PDK/libs.tech/xschem/xschemrc'
alias openlane='python3 -m openlane --dockerized'
```

Simpan file (`Ctrl + O`, `Enter`, lalu `Ctrl + X`), lalu reload:
```bash
source ~/.bashrc
```

---

# 6. Langkah 6: Perbarui Symlink Integrasi Tools

Karena lokasi PDK telah berpindah dari `~/.ciel` ke `~/.volare`, kita hanya perlu memperbarui symlink untuk Netgen, Irsim, dan KLayout:

### 6.1 Perbarui Netgen LVS Setup
```bash
cd ~/design/netgen
ln -sf $PDK_ROOT/sky130A/libs.tech/netgen/setup.tcl sky130A_setup.tcl
ln -sf $PDK_ROOT/sky130B/libs.tech/netgen/setup.tcl sky130B_setup.tcl
```

### 6.2 Perbarui Irsim Libraries
```bash
cd ~/design/irsim
ln -sf $PDK_ROOT/sky130A/libs.tech/irsim irsim_sky130A
ln -sf $PDK_ROOT/sky130B/libs.tech/irsim irsim_sky130B
```

### 6.3 Perbarui KLayout Tech
```bash
mkdir -p ~/.klayout/tech
cd ~/.klayout/tech
ln -sf $PDK_ROOT/sky130A/libs.tech/klayout sky130A
```

---

# 7. Langkah 7: Verifikasi & Uji Alur OpenLane 2

### 7.1 Smoke Test OpenLane 2
Jalankan uji bawaan OpenLane 2 untuk memastikan integrasi Docker berjalan lancar:
```bash
python3 -m openlane --dockerized --smoke-test
```
*(Harus menyelesaikan 78 tahapan dan diakhiri dengan `Smoke test passed.`)*

---

### 7.2 Perbandingan Cara Menjalankan Desain Digital

| OpenLane 1 (Cara Lama - Sudah Dihapus ❌) | OpenLane 2 (Cara Baru Modern ✅) |
|---|---|
| Harus copy folder ke `~/OpenLane/designs/` | **Bisa dijalankan langsung di folder mana saja!** |
| `cd ~/OpenLane` | Cukup jalankan dari terminal mana pun: |
| `make mount` | `openlane --dockerized /path/to/design` |
| `./flow.tcl -design inverter` | |

#### Uji Desain Digital Inverter:
Jika Anda menggunakan repo contoh `VLSI_Inverter_Design`:
```bash
# Tidak perlu lagi copy ke folder OpenLane, langsung eksekusi foldernya:
openlane --dockerized ~/VLSI_Inverter_Design/Digital/inverter
```

Setelah alur selesai, buka hasil GDSII layout di KLayout:
```bash
cd ~/VLSI_Inverter_Design/Digital/inverter/runs/
klayout $(find . -name "*.gds" | tail -n 1)
```

#### Verifikasi Tools Analog Host:
Pastikan tools analog Anda tidak terganggu dan tetap lancar:
```bash
# Uji Xschem
xschem

# Uji Magic
magic
```

---

# 🎯 Selesai!

Proses migrasi telah selesai:
- 🗑️ **OpenLane 1** dan cache lama berhasil dihapus total (menghemat ~25 GB disk).
- ⚡ **OpenLane 2** terpasang rapi di virtual environment dan terintegrasi dengan Docker non-root.
- 📦 **PDK SkyWater 130nm** kini dikelola rapi oleh **Volare** di `~/.volare`.
- 🔌 Semua host tools (**Xschem, Ngspice, Magic, Netgen, Irsim, KLayout**) tetap berfungsi normal tanpa perlu install ulang! 🚀
