class SetupConstants {
  static const List<Map<String, String>> sports = [
    {"name": "Basketball", "img": "assets/images/basket2.jpg"},
    {"name": "Running", "img": "assets/images/mlayu.jpg"},
    {"name": "Football", "img": "assets/images/bal.jpg"},
    {"name": "Home Workout", "img": "assets/images/wo.png"},
    {"name": "Cycling", "img": "assets/images/pedah.jpg"},
  ];

  static const List<Map<String, String>> fitnessLevels = [
    {"label": "Tidak Pernah", "value": "NEVER"},
    {"label": "1 - 2 kali seminggu", "value": "SOMETIMES"},
    {"label": "3 - 4 kali seminggu", "value": "OFTEN"},
    {"label": "Setiap Hari", "value": "DAILY"},
  ];

  static const List<Map<String, String>> fitnessGoals = [
    {
      "label": "Turun Berat Badan",
      "value": "WEIGHT_LOSS",
      "desc": "Fokus bakar kalori & kardio",
    },
    {
      "label": "Bentuk Otot",
      "value": "MUSCLE_GAIN",
      "desc": "Fokus kekuatan & repetisi",
    },
    {
      "label": "Jaga Kesehatan",
      "value": "KEEP_FIT",
      "desc": "Latihan seimbang & santai",
    },
  ];

  static const List<Map<String, String>> genderOptions = [
    {"label": "Laki-laki", "value": "MALE"},
    {"label": "Perempuan", "value": "FEMALE"},
  ];
}
