const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, '..', 'lib');
const outputHtml = path.join(__dirname, '..', 'FULL_DOCUMENTATION.html');

// Helper to recursively get all Dart files
function getDartFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      getDartFiles(filePath, fileList);
    } else if (file.endsWith('.dart')) {
      fileList.push(filePath);
    }
  });
  return fileList;
}

// Simple rule-based translation to "monkey-level" Indonesian
function getMonkeyExplanation(name, type = 'method') {
  const lower = name.toLowerCase();
  
  if (type === 'class') {
    if (lower.includes('datasource')) return 'Tukang ambil data mentah dari internet (API) atau database Firebase.';
    if (lower.includes('repositoryimpl')) return 'Jembatan yang menghubungkan pengambilan data mentah dengan aturan bisnis aplikasi.';
    if (lower.includes('repository')) return 'Daftar peraturan/kontrak apa saja yang bisa dilakukan oleh data (belum ada kodenya, baru daftar nama fungsi).';
    if (lower.includes('usecase') || lower.includes('calculate') || lower.includes('save') || lower.includes('delete') || lower.includes('get')) {
      return 'Koki pintar yang punya 1 resep khusus untuk melakukan 1 pekerjaan spesifik (misalnya: menghitung BMI, menyimpan riwayat, atau memuat profil).';
    }
    if (lower.includes('provider')) return 'Manajer pintar yang mengatur data di belakang layar dan memberi tahu layar HP (UI) untuk berubah jika datanya berubah.';
    if (lower.includes('page') || lower.includes('screen') || lower.includes('view')) return 'Layar HP yang dilihat langsung oleh mata pengguna (berisi tombol, teks, gambar).';
    if (lower.includes('widget') || lower.includes('card') || lower.includes('painter')) return 'Komponen hiasan kecil di layar HP (seperti kotak kartu, jarum meteran, atau tombol kustom).';
    if (lower.includes('entity') || lower.includes('model')) return 'Kotak wadah penyimpanan barang (struktur data) agar data rapi saat dikirim ke sana kemari.';
    if (lower.includes('service')) return 'Pelayan khusus yang bekerja di belakang layar untuk mengurusi hal tertentu (seperti kirim notifikasi, setel alarm, atau cek GPS).';
    return 'Komponen sistem yang membantu menjalankan logika aplikasi.';
  }

  // Method translations
  if (lower === 'call') return 'Pemicu utama untuk menjalankan fungsi utama dari berkas ini.';
  if (lower === 'main') return 'Tombol start utama. Tempat aplikasi pertama kali dinyalakan saat HP dibuka.';
  if (lower === 'build') return 'Menggambar tampilan layar HP beserta semua tombol dan teksnya.';
  if (lower === 'initstate' || lower === 'initialize' || lower === 'init') return 'Persiapan awal saat komponen ini pertama kali dihidupkan (seperti menyalakan mesin sebelum jalan).';
  if (lower === 'dispose') return 'Membersihkan memori HP saat layar ditutup agar HP tidak lemot.';
  if (lower === 'fetchfromfirebase') return 'Mengambil data terbaru yang disimpan di server awan Firebase.';
  
  let desc = '';
  if (lower.startsWith('fetch') || lower.startsWith('get') || lower.startsWith('load') || lower.startsWith('read')) {
    desc = 'Mengambil / membaca data ';
  } else if (lower.startsWith('save') || lower.startsWith('store') || lower.startsWith('add') || lower.startsWith('create')) {
    desc = 'Menyimpan / membuat data baru ';
  } else if (lower.startsWith('delete') || lower.startsWith('remove') || lower.startsWith('clear')) {
    desc = 'Menghapus data ';
  } else if (lower.startsWith('update') || lower.startsWith('edit') || lower.startsWith('change') || lower.startsWith('set')) {
    desc = 'Mengubah / memperbarui data ';
  } else if (lower.startsWith('calculate') || lower.startsWith('compute')) {
    desc = 'Melakukan perhitungan matematika untuk ';
  } else if (lower.startsWith('process')) {
    desc = 'Mengolah / memproses data ';
  } else if (lower.startsWith('generate')) {
    desc = 'Membuat rekomendasi otomatis untuk ';
  } else if (lower.startsWith('watch') || lower.startsWith('listen') || lower.startsWith('subscribe')) {
    desc = 'Mengawasi / memantau secara terus-menerus perubahan ';
  } else {
    desc = `Menjalankan fungsi khusus untuk ` + name;
    return desc;
  }

  // Object details
  if (lower.includes('weather')) desc += 'cuaca lokal saat ini.';
  else if (lower.includes('aqi')) desc += 'kualitas udara di sekitar.';
  else if (lower.includes('user') || lower.includes('profile')) desc += 'informasi akun / profil pengguna.';
  else if (lower.includes('bmi')) desc += 'Indeks Massa Tubuh (berat & tinggi badan).';
  else if (lower.includes('history') || lower.includes('riwayat')) desc += 'riwayat aktivitas olahraga yang lalu.';
  else if (lower.includes('sport') || lower.includes('workout') || lower.includes('exercise')) desc += 'latihan olahraga.';
  else if (lower.includes('badge') || lower.includes('medal')) desc += 'lencana penghargaan / medali prestasi.';
  else if (lower.includes('exp')) desc += 'poin pengalaman (Experience Points).';
  else if (lower.includes('streak')) desc += 'barisan hari latihan berturut-turut.';
  else if (lower.includes('login')) desc += 'status masuk/login pengguna.';
  else if (lower.includes('notification') || lower.includes('reminder')) desc += 'notifikasi pengingat latihan.';
  else if (lower.includes('theme') || lower.includes('dark')) desc += 'tema tampilan HP (Gelap/Terang).';
  else if (lower.includes('language') || lower.includes('translation')) desc += 'bahasa yang digunakan aplikasi.';
  else if (lower.includes('calories') || lower.includes('cals')) desc += 'jumlah pembakaran kalori.';
  else desc += 'berkas ini.';

  return desc;
}

// Custom simple parser for Dart files
function parseDartFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const relativePath = path.relative(libDir, filePath);
  
  const fileData = {
    path: relativePath,
    name: path.basename(filePath),
    classes: [],
    functions: [] // Top level functions
  };

  const lines = content.split('\n');
  let currentClass = null;

  // Simple state machine
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // Skip empty or purely comment lines
    if (line.startsWith('//') || line.startsWith('import') || line.startsWith('export')) {
      continue;
    }

    // Match class: class ClassName [extends X] [implements Y] {
    const classMatch = line.match(/^class\s+([A-Za-z0-9_]+)/);
    if (classMatch) {
      if (currentClass) {
        fileData.classes.push(currentClass);
      }
      currentClass = {
        name: classMatch[1],
        explanation: getMonkeyExplanation(classMatch[1], 'class'),
        methods: []
      };
      continue;
    }

    // Match methods/functions inside class or top level
    // Looking for: ReturnType methodName(params) { or Future<X> methodName(params) async {
    // Exclude keywords like if, for, while, switch, return, class, new
    const methodMatch = line.match(/^\s*(?:static\s+|async\s+|override\s+|Future<[^>]+>\s+|[A-Za-z0-9_<>?]+\??\s+)?([A-Za-z0-9_]+)\s*\(([^)]*)\)\s*(?:async\s*)?[\{;=]/);
    if (methodMatch) {
      const methodName = methodMatch[1];
      const params = methodMatch[2].trim() || 'tidak ada input';
      
      const excluded = ['if', 'for', 'while', 'switch', 'return', 'class', 'super', 'catch', 'assert', 'print'];
      if (excluded.includes(methodName)) {
        continue;
      }

      const methodData = {
        name: methodName,
        parameters: params,
        explanation: getMonkeyExplanation(methodName, 'method')
      };

      if (currentClass) {
        currentClass.methods.push(methodData);
      } else {
        fileData.functions.push(methodData);
      }
    }
  }

  if (currentClass) {
    fileData.classes.push(currentClass);
  }

  return fileData;
}

// Generate the HTML report
function main() {
  console.log('🔍 Menelusuri semua berkas Dart di lib/...');
  const files = getDartFiles(libDir);
  console.log(`✅ Menemukan ${files.length} berkas Dart.`);

  const parsedFiles = files.map(file => parseDartFile(file));

  // Build gorgeous HTML
  let html = `<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title>Kamus Lengkap Codingan - Lora Health Management</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&family=Plus+Jakarta+Sans:wght@300;400;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #0b0f19;
      --card-bg: #151c2c;
      --text: #f1f5f9;
      --text-muted: #94a3b8;
      --primary: #38bdf8;
      --primary-dark: #0284c7;
      --accent: #a855f7;
      --border: #334155;
    }
    
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      background-color: var(--bg);
      color: var(--text);
      font-family: 'Plus Jakarta Sans', sans-serif;
      line-height: 1.6;
      padding: 40px 20px;
    }

    .container {
      max-width: 1100px;
      margin: 0 auto;
    }

    /* Print Header Banner */
    .header {
      background: linear-gradient(135deg, #1e1b4b 0%, #0f172a 100%);
      padding: 40px;
      border-radius: 24px;
      border: 1px solid var(--border);
      text-align: center;
      margin-bottom: 40px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
    }

    .header h1 {
      font-family: 'Outfit', sans-serif;
      font-size: 2.8rem;
      font-weight: 800;
      letter-spacing: -1px;
      background: linear-gradient(to right, #38bdf8, #a855f7);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 10px;
    }

    .header p {
      color: var(--text-muted);
      font-size: 1.1rem;
      max-width: 600px;
      margin: 0 auto 20px auto;
    }

    /* PDF Tips Alert Box */
    .pdf-alert {
      background: rgba(168, 85, 247, 0.15);
      border: 1px solid var(--accent);
      padding: 20px;
      border-radius: 16px;
      color: #e9d5ff;
      margin-bottom: 40px;
      display: flex;
      flex-direction: column;
      gap: 10px;
      text-align: left;
    }

    .pdf-alert h3 {
      color: #f3e8ff;
      font-size: 1.2rem;
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .pdf-alert ul {
      margin-left: 20px;
    }

    /* Search Bar */
    .search-box {
      width: 100%;
      padding: 16px 24px;
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 16px;
      color: var(--text);
      font-size: 1.1rem;
      margin-bottom: 40px;
      outline: none;
      transition: all 0.3s ease;
      box-shadow: 0 4px 20px rgba(0,0,0,0.2);
    }

    .search-box:focus {
      border-color: var(--primary);
      box-shadow: 0 0 10px rgba(56, 189, 248, 0.3);
    }

    /* File Section Card */
    .file-card {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 30px;
      margin-bottom: 30px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.1);
      break-inside: avoid; /* PDF Page breaking rule */
    }

    .file-path {
      font-size: 0.85rem;
      color: var(--primary);
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 5px;
    }

    .file-title {
      font-family: 'Outfit', sans-serif;
      font-size: 1.8rem;
      font-weight: 700;
      color: #ffffff;
      margin-bottom: 15px;
      border-bottom: 1px dashed var(--border);
      padding-bottom: 10px;
    }

    /* Classes inside file */
    .class-box {
      background: rgba(255,255,255,0.02);
      border-left: 4px solid var(--primary);
      padding: 15px 20px;
      margin-bottom: 20px;
      border-radius: 0 12px 12px 0;
    }

    .class-header {
      font-size: 1.2rem;
      font-weight: 700;
      color: #38bdf8;
      margin-bottom: 5px;
    }

    .class-desc {
      font-size: 0.95rem;
      color: var(--text-muted);
      margin-bottom: 15px;
    }

    /* Table for Functions/Methods */
    .method-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 10px;
    }

    .method-table th, .method-table td {
      padding: 12px 16px;
      text-align: left;
      border-bottom: 1px solid var(--border);
    }

    .method-table th {
      background-color: rgba(56, 189, 248, 0.05);
      color: #ffffff;
      font-weight: 600;
      font-size: 0.9rem;
    }

    .method-name {
      font-family: 'Courier New', Courier, monospace;
      color: #f472b6;
      font-weight: bold;
      font-size: 1rem;
    }

    .method-params {
      font-size: 0.8rem;
      color: var(--text-muted);
      font-family: 'Courier New', Courier, monospace;
      display: block;
      margin-top: 3px;
      background: rgba(0,0,0,0.2);
      padding: 2px 6px;
      border-radius: 4px;
      width: fit-content;
    }

    .method-explain {
      font-size: 0.95rem;
      color: #e2e8f0;
      font-weight: 500;
    }

    /* Pure Functions List */
    .pure-functions-box {
      background: rgba(168, 85, 247, 0.05);
      border-left: 4px solid var(--accent);
      padding: 15px 20px;
      margin-bottom: 20px;
      border-radius: 0 12px 12px 0;
    }

    .pure-functions-header {
      font-size: 1.2rem;
      font-weight: 700;
      color: var(--accent);
      margin-bottom: 10px;
    }

    /* Page Break for Print */
    @media print {
      body {
        background-color: #ffffff;
        color: #000000;
        padding: 0;
      }
      .container {
        width: 100%;
        max-width: 100%;
      }
      .header {
        border: none;
        background: none;
        color: #000000;
        padding: 0;
        margin-bottom: 20px;
        box-shadow: none;
      }
      .header h1 {
        -webkit-text-fill-color: initial;
        color: #1e3a8a;
        background: none;
      }
      .pdf-alert, .search-box {
        display: none; /* Hide interactive/alert UI in printed PDF */
      }
      .file-card {
        background: #ffffff;
        color: #000000;
        border: 1px solid #cbd5e1;
        box-shadow: none;
        page-break-after: always; /* Ensure each file starts on a new PDF page */
        margin-bottom: 0;
        padding: 20px;
      }
      .file-title {
        color: #1e293b;
        border-bottom: 2px solid #64748b;
      }
      .class-box {
        background: #f8fafc;
        border-left: 4px solid #0284c7;
      }
      .class-header {
        color: #0284c7;
      }
      .pure-functions-box {
        background: #faf5ff;
        border-left: 4px solid #7e22ce;
      }
      .pure-functions-header {
        color: #7e22ce;
      }
      .method-table th {
        background-color: #f1f5f9;
        color: #0f172a;
        border-bottom: 2px solid #cbd5e1;
      }
      .method-table td {
        border-bottom: 1px solid #e2e8f0;
      }
      .method-name {
        color: #be185d;
      }
      .method-explain {
        color: #334155;
      }
      .method-params {
        background: #f1f5f9;
        color: #475569;
        border: 1px solid #e2e8f0;
      }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Kamus Lengkap Codingan Lora</h1>
      <p>Kamus detail Bahasa Indonesia yang menerjemahkan seluruh struktur kelas dan fungsi di balik aplikasi Lora Health Management agar mudah dipahami oleh siapa saja.</p>
      
      <div class="pdf-alert">
        <h3>💡 Cara Ekspor ke PDF dengan Kualitas Premium:</h3>
        <ul>
          <li>Buka file HTML ini di Google Chrome, Microsoft Edge, atau browser favorit Anda.</li>
          <li>Tekan <strong>Ctrl + P</strong> (Windows) atau <strong>Cmd + P</strong> (Mac) untuk membuka menu Cetak.</li>
          <li>Ubah printer tujuan menjadi <strong>"Save as PDF"</strong> / <strong>"Simpan sebagai PDF"</strong>.</li>
          <li>Centang opsi <strong>"Background graphics"</strong> (agar warna dan desain premium tetap tercetak di PDF).</li>
          <li>Klik <strong>Cetak/Simpan</strong> untuk mendapatkan file PDF berkualitas tinggi secara instan!</li>
        </ul>
      </div>
    </div>

    <input type="text" id="search" class="search-box" placeholder="Cari berkas, nama kelas, atau nama fungsi (contoh: loadWeather, BmiResultEntity)..." onkeyup="filterDocs()">

    <div id="documentation-list">
`;

  parsedFiles.forEach(file => {
    // Only show files that have classes or functions
    if (file.classes.length === 0 && file.functions.length === 0) return;

    html += `
      <div class="file-card" data-search="${file.name.toLowerCase()} ${file.path.toLowerCase()}">
        <div class="file-path">lib/${file.path}</div>
        <h2 class="file-title">📄 Berkas: ${file.name}</h2>
    `;

    // Process Classes
    file.classes.forEach(cls => {
      html += `
        <div class="class-box" data-search="${cls.name.toLowerCase()}">
          <div class="class-header">🏫 Kelas: ${cls.name}</div>
          <div class="class-desc"><strong>Gunanya untuk:</strong> ${cls.explanation}</div>
      `;

      if (cls.methods.length > 0) {
        html += `
          <table class="method-table">
            <thead>
              <tr>
                <th style="width: 35%">Nama Fungsi (Method)</th>
                <th style="width: 65%">Fungsi & Penjelasannya (Monkey-Level)</th>
              </tr>
            </thead>
            <tbody>
        `;

        cls.methods.forEach(m => {
          html += `
              <tr data-search="${m.name.toLowerCase()}">
                <td>
                  <span class="method-name">${m.name}</span>
                  <span class="method-params">Input: ${m.parameters}</span>
                </td>
                <td class="method-explain">
                  👉 <strong>Kegunaan:</strong> ${m.explanation}
                </td>
              </tr>
          `;
        });

        html += `
            </tbody>
          </table>
        `;
      } else {
        html += `<p style="font-size: 0.9rem; color: var(--text-muted); font-style: italic;">Kelas ini tidak memiliki fungsi tambahan (biasanya hanya wadah data).</p>`;
      }

      html += `</div>`; // Close class-box
    });

    // Process Pure/Top-level functions in file
    if (file.functions.length > 0) {
      html += `
        <div class="pure-functions-box">
          <div class="pure-functions-header">⚙️ Fungsi Mandiri (Top-level Functions)</div>
          <table class="method-table">
            <thead>
              <tr>
                <th style="width: 35%">Nama Fungsi</th>
                <th style="width: 65%">Fungsi & Penjelasannya (Monkey-Level)</th>
              </tr>
            </thead>
            <tbody>
      `;

      file.functions.forEach(m => {
        html += `
              <tr data-search="${m.name.toLowerCase()}">
                <td>
                  <span class="method-name">${m.name}</span>
                  <span class="method-params">Input: ${m.parameters}</span>
                </td>
                <td class="method-explain">
                  👉 <strong>Kegunaan:</strong> ${m.explanation}
                </td>
              </tr>
        `;
      });

      html += `
            </tbody>
          </table>
        </div>
      `;
    }

    html += `</div>`; // Close file-card
  });

  html += `
    </div>
  </div>

  <script>
    function filterDocs() {
      const query = document.getElementById('search').value.toLowerCase();
      const cards = document.getElementsByClassName('file-card');

      for (let i = 0; i < cards.length; i++) {
        const card = cards[i];
        const cardText = card.getAttribute('data-search');
        let cardMatches = cardText.includes(query);

        // Check if query matches child elements
        const rows = card.getElementsByTagName('tr');
        const classBoxes = card.getElementsByClassName('class-box');
        let childMatches = false;

        // Reset visibility
        for (let row of rows) {
          const rowText = row.getAttribute('data-search') || '';
          if (rowText.includes(query)) {
            row.style.display = '';
            childMatches = true;
          } else {
            row.style.display = 'none';
          }
        }

        for (let cb of classBoxes) {
          const cbText = cb.getAttribute('data-search') || '';
          if (cbText.includes(query)) {
            cb.style.display = '';
            childMatches = true;
          } else {
            // Keep visible if inner rows matched
            let hasVisibleRow = false;
            const cbRows = cb.getElementsByTagName('tr');
            for (let r of cbRows) {
              if (r.style.display === '') {
                hasVisibleRow = true;
                break;
              }
            }
            cb.style.display = (hasVisibleRow || query === '') ? '' : 'none';
          }
        }

        if (cardMatches || childMatches || query === '') {
          card.style.display = '';
        } else {
          card.style.display = 'none';
        }
      }
    }
  </script>
</body>
</html>
`;

  fs.writeFileSync(outputHtml, html);
  console.log(`\n🎉 SUKSES! File dokumentasi super detail berhasil dibuat di:`);
  console.log(`👉 ${outputHtml}`);
}

main();
