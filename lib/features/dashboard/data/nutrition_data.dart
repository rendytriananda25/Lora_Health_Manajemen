import 'package:firebase_database/firebase_database.dart';

class NutritionData {
  static const Map<String, dynamic> guidelines = {
    "NEVER": {
      "daily_focus": "Adaptasi metabolisme",
      "calorie_guideline": "Kalori maintenance",
      "protein_guideline": "0.8–1.0 g/kg BB",
      "hydration": "2–2.5 L/hari",
      "expert_note": "WHO: Pola makan seimbang.",
    },
    "SOMETIMES": {
      "daily_focus": "Energi latihan ringan",
      "calorie_guideline": "Maintenance / Sedikit Defisit",
      "protein_guideline": "1.0–1.2 g/kg BB",
      "hydration": "2.5–3 L/hari",
      "expert_note": "ACSM: Tingkatkan protein.",
    },
    "OFTEN": {
      "daily_focus": "Pemulihan otot",
      "calorie_guideline": "Maintenance / Surplus Ringan",
      "protein_guideline": "1.4–1.6 g/kg BB",
      "hydration": "3–3.5 L/hari",
      "expert_note": "ISSN: Protein & Karbo penting.",
    },
    "DAILY": {
      "daily_focus": "Performa optimal",
      "calorie_guideline": "Surplus Terkontrol",
      "protein_guideline": "1.6–2.0 g/kg BB",
      "hydration": "3.5–4 L/hari",
      "expert_note": "ACSM: Fokus energi atlet.",
    },
  };

  static const Map<String, Map<String, dynamic>> foodRecommendations = {
    "WEIGHT_LOSS": {
      "reason_good": "Rendah kalori, tinggi serat & protein.",
      "reason_bad": "Tinggi gula, tepung olahan & lemak jenuh.",
      "foods": [
        {
          "name": "Putih Telur",
          "cal": 52,
          "type": "good",
          "reason": "Protein murni tanpa lemak, sangat mengenyangkan.",
        },
        {
          "name": "Telur Rebus",
          "cal": 155,
          "type": "good",
          "reason": "Protein lengkap & lemak sehat untuk metabolisme.",
        },
        {
          "name": "Dada Ayam Rebus",
          "cal": 165,
          "type": "good",
          "reason": "Raja protein diet, menjaga otot saat defisit kalori.",
        },
        {
          "name": "Ikan Kukus",
          "cal": 128,
          "type": "good",
          "reason": "Kaya Omega-3, rendah kalori, baik untuk jantung.",
        },
        {
          "name": "Tahu Kukus",
          "cal": 76,
          "type": "good",
          "reason": "Protein nabati ringan yang mudah dicerna.",
        },
        {
          "name": "Tempe Panggang",
          "cal": 193,
          "type": "good",
          "reason": "Serat tinggi & probiotik alami untuk pencernaan.",
        },
        {
          "name": "Sayur Bayam",
          "cal": 23,
          "type": "good",
          "reason": "Superfood rendah kalori, kaya zat besi.",
        },
        {
          "name": "Sayur Kangkung",
          "cal": 19,
          "type": "good",
          "reason": "Volume besar dengan kalori minimal, sangat mengenyangkan.",
        },
        {
          "name": "Brokoli",
          "cal": 34,
          "type": "good",
          "reason": "Tinggi serat & antioksidan, membantu detox alami.",
        },
        {
          "name": "Lalapan",
          "cal": 20,
          "type": "good",
          "reason": "Kaya air & serat, kontrol nafsu makan alami.",
        },
        {
          "name": "Gado-gado (No Lontong)",
          "cal": 180,
          "type": "good",
          "reason": "Salad lokal kaya nutrisi (jaga porsi bumbu!).",
        },
        {
          "name": "Pecel Sayur",
          "cal": 150,
          "type": "good",
          "reason": "Variasi mikronutrien dari beragam sayuran.",
        },
        {
          "name": "Soto Ayam (No Santan)",
          "cal": 120,
          "type": "good",
          "reason": "Kuah hangat mengenyangkan, rendah lemak.",
        },
        {
          "name": "Sup Ayam Bening",
          "cal": 95,
          "type": "good",
          "reason": "Comfort food yang hydrating & tinggi protein.",
        },
        {
          "name": "Apel",
          "cal": 52,
          "type": "good",
          "reason": "Serat pektin membantu menahan rasa lapar.",
        },
        {
          "name": "Pepaya",
          "cal": 43,
          "type": "good",
          "reason": "Enzim papain melancarkan pencernaan.",
        },
        {
          "name": "Semangka",
          "cal": 30,
          "type": "good",
          "reason": "Cemilan manis alami dengan 90% air.",
        },
        {
          "name": "Teh Hijau",
          "cal": 2,
          "type": "good",
          "reason": "Katekin meningkatkan pembakaran lemak alami.",
        },
        {
          "name": "Air Putih",
          "cal": 0,
          "type": "good",
          "reason": "Esensial untuk metabolisme pembakaran lemak.",
        },
        {
          "name": "Air Kelapa Murni",
          "cal": 19,
          "type": "good",
          "reason": "Elektrolit alami tanpa gula tambahan.",
        },

        {
          "name": "Nasi Putih Besar",
          "cal": 260,
          "type": "bad",
          "reason": "Lonjakan gula darah cepat, memicu lapar lagi.",
        },
        {
          "name": "Gorengan",
          "cal": 250,
          "type": "bad",
          "reason": "Spons minyak! Kalori kosong dari lemak jenuh.",
        },
        {
          "name": "Bakwan",
          "cal": 280,
          "type": "bad",
          "reason": "Dominasi tepung & minyak, minim nutrisi.",
        },
        {
          "name": "Martabak Manis",
          "cal": 350,
          "type": "bad",
          "reason": "Kombinasi gula & lemak yang menghambat diet.",
        },
        {
          "name": "Mie Instan",
          "cal": 380,
          "type": "bad",
          "reason": "Tinggi natrium, menyebabkan perut buncit (air).",
        },
        {
          "name": "Rendang Berlemak",
          "cal": 470,
          "type": "bad",
          "reason": "Santan kental membuat kalori sangat padat.",
        },
        {
          "name": "Minuman Boba",
          "cal": 300,
          "type": "bad",
          "reason": "Gula cair murni, tidak bikin kenyang.",
        },
        {
          "name": "Es Teh Manis",
          "cal": 120,
          "type": "bad",
          "reason": "'Hidden calories' dari gula yang sering diremehkan.",
        },
        {
          "name": "Soda",
          "cal": 140,
          "type": "bad",
          "reason": "Gula tinggi tanpa serat/nutrisi sama sekali.",
        },
        {
          "name": "Kue Kering",
          "cal": 450,
          "type": "bad",
          "reason": "Sangat padat kalori, mudah over-eating.",
        },
      ],
    },

    "MUSCLE_GAIN": {
      "reason_good": "Protein tinggi & kalori berkualitas untuk otot.",
      "reason_bad": "Menghambat recovery & sintesis protein.",
      "foods": [
        {
          "name": "Daging Sapi",
          "cal": 250,
          "type": "good",
          "reason": "Kreatin alami & protein untuk kekuatan otot.",
        },
        {
          "name": "Ayam Panggang",
          "cal": 239,
          "type": "good",
          "reason": "Protein staple binaraga, mudah diserap tubuh.",
        },
        {
          "name": "Telur Utuh",
          "cal": 155,
          "type": "good",
          "reason": "Lemak baik di kuning telur dukung hormon anabolik.",
        },
        {
          "name": "Ikan Tuna",
          "cal": 132,
          "type": "good",
          "reason": "Protein 'lean' praktis untuk meal prep.",
        },
        {
          "name": "Ikan Salmon",
          "cal": 208,
          "type": "good",
          "reason": "Omega-3 kurangi nyeri otot pasca latihan.",
        },
        {
          "name": "Tempe",
          "cal": 193,
          "type": "good",
          "reason": "Asam amino lengkap setara daging, superfood lokal.",
        },
        {
          "name": "Tahu",
          "cal": 76,
          "type": "good",
          "reason": "Sumber protein & kalsium yang fleksibel.",
        },
        {
          "name": "Nasi Merah",
          "cal": 110,
          "type": "good",
          "reason": "Energi lepas lambat untuk latihan panjang.",
        },
        {
          "name": "Ubi Rebus",
          "cal": 86,
          "type": "good",
          "reason": "Karbohidrat kompleks favorit atlet binaraga.",
        },
        {
          "name": "Kentang Rebus",
          "cal": 87,
          "type": "good",
          "reason": "Kaya potasium, cegah kram otot.",
        },
        {
          "name": "Oatmeal",
          "cal": 68,
          "type": "good",
          "reason": "Bahan bakar ideal sebelum latihan beban.",
        },
        {
          "name": "Susu Full Cream",
          "cal": 60,
          "type": "good",
          "reason": "Cara termudah tambah kalori & protein.",
        },
        {
          "name": "Whey/Susu Protein",
          "cal": 120,
          "type": "good",
          "reason": "Serap cepat, langsung masuk otot pasca gym.",
        },
        {
          "name": "Kacang Tanah",
          "cal": 567,
          "type": "good",
          "reason": "Padat energi/protein untuk surplus kalori.",
        },
        {
          "name": "Almond",
          "cal": 579,
          "type": "good",
          "reason": "Magnesium tinggi optimalkan fungsi otot.",
        },
        {
          "name": "Selai Kacang",
          "cal": 588,
          "type": "good",
          "reason": "Kalori sehat yang enak untuk bulking.",
        },

        {
          "name": "Alkohol",
          "cal": 200,
          "type": "bad",
          "reason": "Racun otot! Menurunkan testosteron & sintesis protein.",
        },
        {
          "name": "Keripik",
          "cal": 536,
          "type": "bad",
          "reason": "Lemak trans merusak kesehatan kardiovaskular.",
        },
        {
          "name": "Gula Berlebih",
          "cal": 387,
          "type": "bad",
          "reason": "Menambah lemak perut, bukan massa otot.",
        },
        {
          "name": "Soda",
          "cal": 140,
          "type": "bad",
          "reason": "Insulin spike yang tidak berguna tanpa nutrisi.",
        },
        {
          "name": "Fast Food",
          "cal": 500,
          "type": "bad",
          "reason": "Inflamasi tinggi, hambat recovery otot.",
        },
      ],
    },

    "KEEP_FIT": {
      "reason_good":
          "Nutrisi seimbang untuk stamina & kesehatan jangka panjang.",
      "reason_bad": "Memicu penyakit metabolik & inflamasi.",
      "foods": [
        {
          "name": "Buah Campur",
          "cal": 60,
          "type": "good",
          "reason": "Vitamin lengkap untuk imunitas tubuh.",
        },
        {
          "name": "Ikan Bakar",
          "cal": 206,
          "type": "good",
          "reason": "Protein sehat tanpa minyak berlebih.",
        },
        {
          "name": "Sup Sayur",
          "cal": 70,
          "type": "good",
          "reason": "Serat & hidrasi untuk pencernaan lancar.",
        },
        {
          "name": "Capcay",
          "cal": 90,
          "type": "good",
          "reason": "Sayuran beragam, antioksidan tinggi.",
        },
        {
          "name": "Nasi Merah",
          "cal": 110,
          "type": "good",
          "reason": "Gula darah stabil, energi terjaga seharian.",
        },
        {
          "name": "Telur Rebus",
          "cal": 155,
          "type": "good",
          "reason": "Snack protein paling praktis & sehat.",
        },
        {
          "name": "Yoghurt Plain",
          "cal": 59,
          "type": "good",
          "reason": "Probiotik untuk kesehatan usus (gut health).",
        },
        {
          "name": "Air Putih",
          "cal": 0,
          "type": "good",
          "reason": "Kunci utama fungsi organ tubuh optimal.",
        },
        {
          "name": "Air Kelapa",
          "cal": 19,
          "type": "good",
          "reason": "Refreshment alami terbaik setelah aktivitas.",
        },
        {
          "name": "Smoothie (No Gula)",
          "cal": 120,
          "type": "good",
          "reason": "Cara enak konsumsi buah & sayur sekaligus.",
        },

        {
          "name": "Asin Berlebih",
          "cal": 0,
          "type": "bad",
          "reason": "Memicu hipertensi & kerja ginjal berat.",
        },
        {
          "name": "Margarin",
          "cal": 717,
          "type": "bad",
          "reason": "Lemak trans pemicu kolesterol jahat.",
        },
        {
          "name": "Jeroan",
          "cal": 150,
          "type": "bad",
          "reason": "Kolesterol & purin tinggi (risiko asam urat).",
        },
        {
          "name": "Santan Berlebih",
          "cal": 230,
          "type": "bad",
          "reason": "Kalori & lemak jenuh tinggi, hati-hati jantung.",
        },
        {
          "name": "Makanan Instan",
          "cal": 350,
          "type": "bad",
          "reason": "Pengawet & kimia tambahan membebani tubuh.",
        },
        {
          "name": "Minuman Kemasan",
          "cal": 180,
          "type": "bad",
          "reason": "Gula tersembunyi penyebab diabetes tipe 2.",
        },
      ],
    },
  };

  static Future<void> seedToFirebase() async {
    try {
      final ref = FirebaseDatabase.instance.ref("data/nutrition_data");
      await ref.set(foodRecommendations);
      print("✅ Firebase Data Seeded Successfully with Independent Reasons!");
    } catch (e) {
      print("⚠️ Upload Failed: $e");
    }
  }

  static Future<Map<String, dynamic>?> fetchFromFirebase() async {
    try {
      final ref = FirebaseDatabase.instance.ref("data/nutrition_data");
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print("Gagal ambil data nutrisi: $e");
    }
    return null;
  }

  static List<String> getFoodsForBmiCategory(
    String bmiCategory,
    Map<String, dynamic> foodRecommendations, {
    bool goodFoodsOnly = false,
  }) {
    final goal = bmiCategory == 'FAT_LOSS'
        ? 'WEIGHT_LOSS'
        : bmiCategory == 'MUSCLE_GAIN'
            ? 'MUSCLE_GAIN'
            : 'KEEP_FIT';

    if (!foodRecommendations.containsKey(goal)) {
      return [];
    }

    final goalData = foodRecommendations[goal] as Map<String, dynamic>;
    final foods = (goalData['foods'] as List<dynamic>?) ?? [];

    if (goodFoodsOnly) {
      return foods
          .where((f) => (f as Map)['type'] == 'good')
          .map((f) => (f as Map)['name'] as String)
          .toList();
    }

    return foods
        .map((f) => (f as Map)['name'] as String)
        .toList();
  }

  static List<String> getGoodFoods(
    String bmiCategory,
    Map<String, dynamic> foodRecommendations,
  ) {
    return getFoodsForBmiCategory(
      bmiCategory,
      foodRecommendations,
      goodFoodsOnly: true,
    );
  }

  static List<String> getFoodsToAvoid(
    String bmiCategory,
    Map<String, dynamic> foodRecommendations,
  ) {
    final goal = bmiCategory == 'FAT_LOSS'
        ? 'WEIGHT_LOSS'
        : bmiCategory == 'MUSCLE_GAIN'
            ? 'MUSCLE_GAIN'
            : 'KEEP_FIT';

    if (!foodRecommendations.containsKey(goal)) {
      return [];
    }

    final goalData = foodRecommendations[goal] as Map<String, dynamic>;
    final foods = (goalData['foods'] as List<dynamic>?) ?? [];

    return foods
        .where((f) => (f as Map)['type'] == 'bad')
        .map((f) => (f as Map)['name'] as String)
        .toList();
  }
}
