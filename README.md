# KelasKu

Prototipe Flutter + Riverpod untuk aplikasi sekolah **KelasKu** dengan role:
- Admin / Wakil Kelas
- Guru
- Siswa

## Demo login
- `admin@kelasku.id`
- `guru@kelasku.id`
- `siswa@kelasku.id`

## Flow register
User baru akan masuk ke status **pending** sampai di-approve oleh admin.
Jika di-approve sebagai guru, saat login pertama user wajib melengkapi:
- mapel
- panggilan guru

## Fitur
- Landing auth
- Approval dashboard admin
- Dashboard guru
- Dashboard siswa (read-only)
- Beranda
- Jadwal multi-item per slot 30 menit
- Tugas dengan filter semua/belum/selesai
- Kehadiran guru
- Pengaturan sekolah & jam sekolah
- Dummy CRUD in-memory

## Menjalankan
```bash
flutter pub get
flutter run
```

## Catatan
- Project ini memakai **dummy local state**, belum backend.
- Cocok sebagai fondasi untuk integrasi Firebase / Supabase / REST API.
