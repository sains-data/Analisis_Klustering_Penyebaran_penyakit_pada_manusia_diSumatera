-- Schema untuk Database Penyakit Sumatera Utara
-- Dibuat sesuai dengan document requirement

-- Tabel untuk menyimpan data kabupaten/kota
CREATE TABLE IF NOT EXISTS kabupaten (
    id_kabupaten SERIAL PRIMARY KEY,
    nama_kabupaten VARCHAR(100) UNIQUE NOT NULL
);

-- Tabel untuk menyimpan jenis penyakit
CREATE TABLE IF NOT EXISTS penyakit (
    id_penyakit SERIAL PRIMARY KEY,
    nama_penyakit VARCHAR(100) UNIQUE NOT NULL
);

-- Tabel untuk menyimpan kasus penyakit
CREATE TABLE IF NOT EXISTS kasus_penyakit (
    id_kasus SERIAL PRIMARY KEY,
    id_kabupaten INTEGER REFERENCES kabupaten(id_kabupaten),
    id_penyakit INTEGER REFERENCES penyakit(id_penyakit),
    jumlah_kasus INTEGER NOT NULL DEFAULT 0,
    tahun INTEGER DEFAULT 2024,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel untuk menyimpan hasil clustering
CREATE TABLE IF NOT EXISTS hasil_klaster (
    id SERIAL PRIMARY KEY,
    kabupaten VARCHAR(100) NOT NULL,
    cluster_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel untuk menyimpan data pivot (untuk analysis)
CREATE TABLE IF NOT EXISTS data_pivot (
    id SERIAL PRIMARY KEY,
    kabupaten VARCHAR(100) NOT NULL,
    aids_kasus_baru INTEGER DEFAULT 0,
    aids_kasus_kumulatif INTEGER DEFAULT 0,
    campak_suspek INTEGER DEFAULT 0,
    dbd INTEGER DEFAULT 0,
    diare INTEGER DEFAULT 0,
    hiv_kasus_baru INTEGER DEFAULT 0,
    hiv_kasus_kumulatif INTEGER DEFAULT 0,
    kusta INTEGER DEFAULT 0,
    malaria_suspek INTEGER DEFAULT 0,
    pneumonia_balita INTEGER DEFAULT 0,
    tb_paru INTEGER DEFAULT 0,
    tetanus INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index untuk performa yang lebih baik
CREATE INDEX IF NOT EXISTS idx_kasus_penyakit_kabupaten ON kasus_penyakit(id_kabupaten);
CREATE INDEX IF NOT EXISTS idx_kasus_penyakit_penyakit ON kasus_penyakit(id_penyakit);
CREATE INDEX IF NOT EXISTS idx_hasil_klaster_kabupaten ON hasil_klaster(kabupaten);
CREATE INDEX IF NOT EXISTS idx_hasil_klaster_cluster ON hasil_klaster(cluster_id);

-- Insert data penyakit yang sudah diketahui
INSERT INTO penyakit (nama_penyakit) VALUES 
    ('AIDS Kasus Baru'),
    ('AIDS Kasus Kumulatif'),
    ('Campak Suspek'),
    ('DBD'),
    ('Diare'),
    ('HIV Kasus Baru'),
    ('HIV Kasus Kumulatif'),
    ('Kusta'),
    ('Malaria Suspek'),
    ('Pneumonia Balita'),
    ('TB Paru'),
    ('Tetanus')
ON CONFLICT (nama_penyakit) DO NOTHING;

-- Tampilkan struktur tabel
\dt
\d+ kabupaten
\d+ penyakit
\d+ kasus_penyakit
\d+ hasil_klaster
\d+ data_pivot
