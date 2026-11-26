Product Requirements Document (PRD) — Aplikasi Touring & Konvoi (Frontend MVP)

1. Ringkasan Proyek (Project Overview)

Aplikasi mobile berbasis Flutter untuk komunitas motor dan penggemar road trip yang menggabungkan navigasi konvoi real-time, sistem keamanan dan komunikasi tanpa perangkat keras tambahan (standalone), serta manajemen logistik perjalanan.

Berbeda dari aplikasi navigasi konvensional yang kaku, aplikasi ini mengusung pendekatan Playful Organic Adventure UI yang hangat, bersih, ramah mata, namun tetap memiliki ergonomi tombol besar yang aman digunakan saat berkendara.

2. Instruksi Eksekusi untuk AI Agent (Workspace Directives)

PERHATIAN UNTUK AI AGENT (Antigravity CLI / Claude Code):

Gunakan Installed Skills: Wajib memanfaatkan seluruh skills, rules, MCP servers, atau custom templates yang sudah terinstal di lingkungan kerja ini (termasuk Flutter UI/UX guidelines, state management conventions, dan asset generators).

Fokus Tahap Awal (Frontend First): Bangun struktur frontend lengkap dengan mock data dan simulasi state interaktif terlebih dahulu sebelum integrasi backend Golang/WebSocket.

Referensi Visual: Jadikan seluruh aset gambar di folder /ref (Refrensi 1.png s.d. Refrensi 6.png, serta Maskot.png dan Icon Maskot.png) sebagai acuan utama proporsi, tipografi, warna, dan gaya ilustrasi.

Dokumentasi: Simpan dan perbarui progres arsitektur komponen ke dalam file markdown lokal agar pengembangan tetap konsisten dan modular.

3. Desain Sistem & Panduan UI/UX (Visual Identity)

A. Gaya Visual (Aesthetic Direction)

Theme: Playful Organic Flat-Illustration & Clean Light Mode (dengan opsi High-Contrast Riding Mode saat navigasi aktif).

Surface & Cards: Latar belakang utama putih bersih (#FFFFFF / #FAFAFA) dengan kartu konten ber-sudut membulat besar (BorderRadius.circular(24)), padding lega, dan soft diffuse shadow (blurRadius: 16, opasitas 5–8%).

Ilustrasi & Maskot: Mengintegrasikan karakter maskot (Maskot.png) pada halaman Home/Dashboard, Empty States, dan Gamification Badges dengan gaya vektor flat tanpa outline hitam tebal.

B. Palet Warna (Color Palette)

Primary Brand (Adventure Green / Mint): #2ECC71 / #4ADE80 (Aksi utama, status aman, rute aktif).

Secondary Accent (Warm Sunset Orange): #FF7A3D / #F59E0B (Tombol CTA penting, highlight jarak/waktu, notifikasi peringatan).

Soft Surface Tints: #E8F8F5 (Mint lembut), #FEF3C7 (Krem hangat), #F3F4F6 (Abu-abu netral untuk kolom pencarian).

Text Hierarchy: Hitam arang #1E293B untuk judul utama, Abu-abu batu #64748B untuk subjudul/metadata.

C. Tipografi & Ergonomi

Font Family: Plus Jakarta Sans atau Nunito (bulat, ramah, modern, dan sangat terbaca).

Riding Ergonomics: Tombol aksi di layar navigasi (Walkie-Talkie, Hazard Pin, SOS) wajib berukuran besar (minimal tinggi 56px–64px) agar mudah ditekan menggunakan sarung tangan motor (glove-friendly).

4. Arsitektur Fitur Utama (Core Features Scope)

Pilar 1: Live Convoy Radar & Offline-First Routing

Dynamic Group Map (Custom Styled Map):

Tampilan peta bersih berwarna terang dengan jalur rute berwarna hijau/oranye.

Avatar setiap anggota konvoi tampil secara real-time di atas peta lengkap dengan label nama dan status (misal: Leader, Sweeper, You).

Gap Alert System (Radar Formasi):

Indikator visual jarak antar-anggota konvoi.

Banner peringatan otomatis (warna oranye hangat) muncul jika ada anggota yang tertinggal melebihi radius batas (misal > 500m dari Sweeper).

Offline-First Route & Checkpoints:

Kartu rute interaktif (menampilkan estimasi jarak km, durasi min, titik kumpul, dan checkpoint istirahat).

Tombol unduh rute untuk penyimpanan lokal (simulasi SQLite/Hive di tahap frontend).

Pilar 2: In-App Safety & Convoy Communication (Standalone)

Push-to-Talk (Walkie-Talkie Mode):

Floating Action Button (FAB) atau Bottom Overlay berukuran besar di layar peta.

Animasi gelombang suara (audio visualizer) saat tombol ditekan dan ditahan (Press & Hold) untuk berbicara ke seluruh grup.

Phone-Based Crash Detection (Simulasi Sensor):

Layar simulasi darurat (Emergency Countdown Overlay 10 detik) dengan tombol geser/tekan besar "Saya Baik-Baik Saja" untuk membatalkan, atau otomatis mengirim sinyal SOS beserta koordinat ke seluruh anggota.

Route Hazard Pinning (Quick-Tap Reporting):

Menu quick-tap 1 sentuhan di peta untuk menandai bahaya jalan: Jalan Berlubang, Jalan Licin/Hujan, Macet/Longsor, atau Butuh Bensin/Trouble.

Pilar 3: Logistik & Komunitas (Trip & Gamification)

Touring Split-Bill (Patungan Perjalanan):

Fitur pencatatan pengeluaran grup (bensin, makan bersama, penginapan).

Kalkulasi pembagian tagihan otomatis per anggota dengan status pembayaran (Lunas / Belum Bayar).

Digital Patch & Milestones:

Halaman profil bergaya kartu pencapaian (terinspirasi Refrensi 4.png & Refrensi 2.png).

Koleksi badge/stiker ilustrasi (misal: Penakluk Tanjakan, Touring Lintas Provinsi, Zero Gap Convoy) beserta leaderboard jarak tempuh komunitas.

5. Struktur Halaman & Navigasi (Screen Architecture)

Gunakan Floating Bottom Navigation Bar (4 tab utama dengan ikon organik dan indikator aktif berbentuk pil):

Home / Explore (Beranda):

Header sapaan personal + Avatar user + Notifikasi.

Hero Banner dengan ilustrasi maskot (Maskot.png) & CTA "Mulai Konvoi Baru" / "Gabung Kode Rute".

Search Bar & Category Pills (Rute Pegunungan, Pantai, Lintas Kota, Camping).

Horizontal Carousel "Rute Populer & Rekomendasi".

Live Radar & Navigation (Peta Konvoi):

Peta layar penuh dengan kontrol zoom minimalis dan kartu detail rute di bagian bawah.

Bar status anggota konvoi di bagian atas (indikator jarak & status koneksi).

Panel kontrol glove-friendly: Tombol Push-to-Talk (HT), Quick Hazard Pin, dan akses cepat Simulasi SOS.

Trips & Split-Bill (Perjalanan):

Daftar riwayat dan jadwal touring aktif (My Trips).

Detail Trip: Rincian checkpoint, daftar peserta konvoi, dan tab Split-Bill untuk patungan biaya.

Profile & Patches (Profil):

Header ilustrasi alam dengan avatar pengguna, total kilometer, dan level rider.

Grid koleksi Digital Patch (lencana ilustrasi) & Leaderboard komunitas.

6. Tahapan Pengembangan Frontend (Milestones untuk Agent)

Phase 1: Setup & Design System

Inisialisasi tema Flutter (AppTheme), palet warna, tipografi, dan komponen UI dasar (Custom Cards, Floating Navbar, Primary/Secondary Buttons).

Phase 2: Core Screens & Navigation Flow

Implementasi halaman Home, Trips & Split-Bill, dan Profile & Patches lengkap dengan aset visual dari folder /ref.

Phase 3: Interactive Convoy Map & Safety Overlays

Implementasi halaman Peta Konvoi dengan simulasi pergerakan marker anggota, UI Walkie-Talkie (Push-to-Talk), Hazard Pinning, dan modal Crash Detection Countdown.

Phase 4: Polish & Micro-Animations

Penambahan transisi halaman yang mulus, efek haptic feedback pada tombol riding, dan pengecekan responsivitas di berbagai ukuran layar ponsel.