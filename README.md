Berikut adalah panduan migrasi lengkap yang telah disesuaikan sepenuhnya menggunakan **Miniconda / Conda (Python 3.12)**. 

Panduan ini disusun mulai dari nol (instalasi Miniconda), menangani isu lisensi/ToS Anaconda (`conda-forge`), membersihkan sisa virtual environment lama (`.venv`) yang sempat membajak command `python3`, hingga konfigurasi symlink host tools dan smoke test.

---

# 🚀 Migration Guide: Upgrade from OpenLane 1 to OpenLane 2 (SkyWater 130nm) via Conda

<div align="center">

![Migration](https://img.shields.io/badge/Migration-OpenLane%201%20%E2%86%92%20OpenLane%202-blue.svg)
![PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm%20(Volare)-brightgreen.svg)
![Python](https://img.shields.io/badge/Python-3.12%20(Conda)-yellow.svg)
![Host Tools](https://img.shields.io/badge/Host%20Tools-Preserved%20%E2%9C%85-success.svg)
![OS](https://img.shields.io/badge/Ubuntu%20%2F%20WSL-20.04%20%7C%2022.04%20%7C%2024.04%20%7C%2026.04-orange.svg)

Panduan praktis untuk membersihkan instalasi **OpenLane 1** lama dan melakukan upgrade ke **OpenLane 2** modern berbasis **Volare & Conda (Python 3.12)**, dengan tetap mempertahankan seluruh tools host yang sudah terpasang (**Xschem, Magic, Ngspice, Netgen, Irsim, KLayout**).

</div>

---

## 📋 Mengapa Menggunakan Conda (Python 3.12)?
Di distro Linux terbaru (seperti Ubuntu 24.10 / 26.04), Python sistem bawaan adalah **Python 3.14** yang belum memiliki *pre-built wheel* untuk library kompilasi seperti `klayout` dan `libparse`. Menggunakan Conda memungkinkan kita memasang **Python 3.12 yang stabil dan terisolasi** tanpa merusak Python bawaan sistem operasi.

---

## 📚 Alur Upgrade & Migrasi

1. [Langkah 1: Backup Desain Kustom (Jika Ada)](#1-langkah-1-backup-desain-kustom)
2. [Langkah 2: Bersihkan OpenLane 1, PDK Lama, & Residu `.venv`](#2-langkah-2-bersihkan-openlane-1-pdk-lama--residu-venv)
3. [Langkah 3: Instalasi Miniconda & Pembuatan Environment Python 3.12](#3-langkah-3-instalasi-miniconda--pembuatan-environment-python-312)
4. [Langkah 4: Unduh & Aktifkan PDK Sky130 via Volare](#4-langkah-4-unduh--aktifkan-pdk-sky130-via-volare)
5. [Langkah 5: Perbarui Konfigurasi `.bashrc`](#5-langkah-5-perbarui-konfigurasi-bashrc)
6. [Langkah 6: Perbarui Symlink Integrasi Tools (Netgen, Irsim, KLayout)](#6-langkah-6-perbarui-symlink-integrasi-tools)
7. [Langkah 7: Verifikasi & Uji Alur OpenLane 2](#7-langkah-7-verifikasi--uji-alur-openlane-2)

---

### 1. Langkah 1: Backup Desain Kustom

Sebelum menghapus OpenLane 1, selamatkan folder desain Anda terlebih dahulu:

```bash
mkdir -p ~/backup_designs
cp -r ~/OpenLane/designs/* ~/backup_designs/ 2>/dev/null || true
```

---

### 2. Langkah 2: Bersihkan OpenLane 1, PDK Lama, & Residu `.venv`

Hapus instansi OpenLane 1, PDK lama (`.ciel`), serta folder virtual environment lama (`.venv`) agar tidak membajak path Python:

```bash
# 1. Hapus direktori OpenLane 1 dan PDK lama
rm -rf ~/OpenLane
rm -rf ~/.ciel

# 2. Hapus sisa venv lama (penyebab konflik path 'no module named openlane')
rm -rf ~/.venv/openlane

# 3. Hapus image Docker OpenLane 1 lama untuk menghemat kapasitas disk
docker images | grep -E "efabless/openlane|openroad" | awk '{print $3}' | xargs -r docker rmi -f

# 4. Bersihkan sisa container & cache Docker yang tidak terpakai
docker system prune -f
```

---

### 3. Langkah 3: Instalasi Miniconda & Pembuatan Environment Python 3.12

#### 3.1 Unduh & Pasang Miniconda *(Lewati langkah ini jika Miniconda sudah terpasang)*
```bash
# Unduh installer resmi Miniconda untuk Linux 64-bit
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh

# Jalankan instalasi otomatis
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3

# Hapus file installer
rm -f ~/miniconda3/miniconda.sh

# Inisialisasi ke shell bash
~/miniconda3/bin/conda init bash
source ~/.bashrc
```

#### 3.2 Buat Environment `openlane` dengan Python 3.12
> **PENTING:** Gunakan channel `-c conda-forge` agar tidak terkena error *CondaToSNonInteractiveError (Terms of Service)*.

```bash
conda create -n openlane -c conda-forge python=3.12 pip -y
```

#### 3.3 Aktifkan Environment & Install OpenLane 2 + Volare
```bash
# Aktifkan environment
conda activate openlane

# Pastikan pip mutakhir
pip install --upgrade pip

# Install OpenLane 2 dan manajer PDK Volare
pip install openlane volare
```

Verifikasi instalasi berhasil:
```bash
which python3
# Output HARUS mengarah ke: /home/<user>/miniconda3/envs/openlane/bin/python3

openlane --version
volare --version
```

---

### 4. Langkah 4: Unduh & Aktifkan PDK Sky130 via Volare

Volare adalah manajer PDK modern yang mengelola versi commit PDK secara presisi:

```bash
# Pastikan environment conda masih aktif
conda activate openlane

# Tetapkan lokasi root PDK baru
export PDK_ROOT=$HOME/.volare
mkdir -p $PDK_ROOT

# Cari versi PDK SkyWater 130nm terbaru dan langsung aktifkan
LATEST_PDK=$(volare ls-remote --pdk sky130 | grep -oE '[a-f0-9]{40}' | head -n 1)
volare enable --pdk sky130 $LATEST_PDK
```

Periksa hasil unduhan dan symlink aktif:
```bash
ls -l ~/.volare/sky130A
```
*(Pastikan `sky130A` menunjuk ke folder hash commit PDK yang baru diunduh).*

---

### 5. Langkah 5: Perbarui Konfigurasi `.bashrc`

Buka konfigurasi shell Anda:
```bash
nano ~/.bashrc
```

1. **HAPUS** baris lama yang mengarah ke `.venv` (jika ada):
   *(Hapus blok `if [ -d "$HOME/.venv/openlane/bin" ]; then ... fi`)*
2. Tambahkan atau ganti bagian konfigurasi PDK & OpenLane di bagian paling bawah dengan blok berikut:

```bash
# =========================================================
# OpenLane 2 & SkyWater 130nm PDK Environment (Conda)
# =========================================================

# Lokasi PDK Root Baru (Volare)
export PDK_ROOT=$HOME/.volare

# Fungsi Pergantian Varian PDK
set_sky130a() {
    export PDK=sky130A
    export PDKPATH=$PDK_ROOT/$PDK
    echo "PDK is now set to: $PDK"
}

set_sky130b() {
    export PDK=sky130B
    export PDKPATH=$PDK_ROOT/$PDK
    echo "PDK is now set to: $PDK"
}

# Default ke sky130A saat terminal baru dibuka
set_sky130a

# Shortcut Praktis OpenLane 2 Dockerized
alias openlane-run='conda run --no-capture-output -n openlane openlane --dockerized'
```

Simpan file (`Ctrl + O`, lalu `Enter`, kemudian `Ctrl + X`), lalu muat ulang shell:
```bash
source ~/.bashrc
```

---

### 6. Langkah 6: Perbarui Symlink Integrasi Tools

Tools host EDA (**Magic, Netgen, Irsim, KLayout, Xschem**) membutuhkan symlink konfigurasi PDK Sky130. Karena PDK lama (`.ciel`) sudah dihapus, hubungkan ke folder PDK Volare baru:

```bash
# Pastikan PDK default aktif
set_sky130a

# 1. Setup Konfigurasi Netgen
sudo mkdir -p /usr/local/share/pdk
sudo ln -sfn $PDK_ROOT /usr/local/share/pdk/sky130A

# 2. Setup Symlink IRSIM
sudo mkdir -p /usr/local/share/irsim
sudo ln -sfn $PDKPATH/libs.tech/irsim/sky130A.prm /usr/local/share/irsim/sky130A.prm

# 3. Setup Konfigurasi KLayout Tech
mkdir -p ~/.klayout/tech
ln -sfn $PDKPATH/libs.tech/klayout/tech/sky130A.lyt ~/.klayout/tech/sky130A.lyt
ln -sfn $PDKPATH/libs.tech/klayout/tech/sky130A.lyp ~/.klayout/tech/sky130A.lyp

# 4. Setup Symlink Magic System Tech
sudo ln -sfn $PDKPATH/libs.tech/magic/sky130A.magicrc /usr/local/lib/magic/sys/sky130A.magicrc 2>/dev/null || true
```

---

### 7. Langkah 7: Verifikasi & Uji Alur OpenLane 2

#### 7.1 Smoke Test OpenLane 2 (Uji Docker & Engine)
Jalankan tes bawaan untuk memastikan OpenLane 2 dapat memanggil container Docker dengan lancar:

```bash
conda activate openlane
openlane --dockerized --smoke-test
```
*(Proses ini akan mengunduh Docker image OpenLane 2 resmi jika belum ada di cache, lalu menjalankan sintesis miniatur `spm` hingga selesai).*

#### 7.2 Uji Sintesis Desain Mandiri
Untuk menjalankan desain kustom di OpenLane 2:
```bash
# Masuk ke direktori desain yang ingin dijalankan
cd ~/backup_designs/inverter   # (contoh)

# Jalankan flow lengkap
openlane --dockerized config.json
```

---

### 💡 Tips Penting Sehari-Hari

1. **Memulai Sesi Kerja OpenLane:**
   Cukup aktifkan conda environment di terminal Anda:
   ```bash
   conda activate openlane
   ```
2. **Menjalankan Tanpa Masuk ke Conda:**
   Gunakan alias yang sudah kita tambahkan di `.bashrc`:
   ```bash
   openlane-run <path/ke/config.json>
   ```
3. **Mengecek Versi PDK yang Aktif:**
   ```bash
   conda activate openlane
   volare ls
   ```
