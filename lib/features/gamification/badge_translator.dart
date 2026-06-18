import 'package:lora_1/core/services/language_provider.dart';

class BadgeTranslator {
  static String translateTitle(String title, LanguageProvider lang) {
    if (lang.currentLanguage == 'id') return title;

    switch (title) {
      case "Pencapaian & Badges":
        return lang.currentLanguage == 'en' ? "Achievements & Badges" : lang.currentLanguage == 'es' ? "Logros e Insignias" : "実績とバッジ";
      case "Langkah Pertama":
        return lang.currentLanguage == 'en' ? "First Step" : lang.currentLanguage == 'es' ? "Primer Paso" : "第一歩";
      case "On Fire!":
        return title;
      case "Dedikasi":
        return lang.currentLanguage == 'en' ? "Dedication" : lang.currentLanguage == 'es' ? "Dedicación" : "献身";
      case "Pelari 10K":
        return lang.currentLanguage == 'en' ? "10K Runner" : lang.currentLanguage == 'es' ? "Corredor 10K" : "10Kランナー";
      case "Calorie Burner":
        return lang.currentLanguage == 'en' ? "Calorie Burner" : lang.currentLanguage == 'es' ? "Quemador de Calorías" : "カロリーバーナー";
      case "Early Bird":
        return title;
      case "Night Owl":
        return title;
      case "Marathoner":
        return lang.currentLanguage == 'en' ? "Marathoner" : lang.currentLanguage == 'es' ? "Maratonista" : "マラソンランナー";
      default:
        return title;
    }
  }

  static String translateDescription(String description, LanguageProvider lang) {
    if (lang.currentLanguage == 'id') return description;

    switch (description) {
      case "Selesaikan latihan pertamamu.":
        return lang.currentLanguage == 'en' ? "Complete your first workout." : lang.currentLanguage == 'es' ? "Completa tu primer entrenamiento." : "最初のワークアウトを完了する。";
      case "Latihan 3 hari berturut-turut.":
        return lang.currentLanguage == 'en' ? "Workout for 3 consecutive days." : lang.currentLanguage == 'es' ? "Entrena 3 días consecutivos." : "3日間連続でワークアウト。";
      case "Selesaikan total 10 sesi latihan.":
        return lang.currentLanguage == 'en' ? "Complete 10 total workout sessions." : lang.currentLanguage == 'es' ? "Completa 10 sesiones en total." : "合計10回のセッションを完了。";
      case "Capai total jarak 10 KM.":
        return lang.currentLanguage == 'en' ? "Reach a total distance of 10 KM." : lang.currentLanguage == 'es' ? "Alcanza un total de 10 KM." : "合計距離10KMに到達。";
      case "Bakar total 1000 kalori.":
        return lang.currentLanguage == 'en' ? "Burn a total of 1000 calories." : lang.currentLanguage == 'es' ? "Quema un total de 1000 calorías." : "合計1000カロリーを消費。";
      case "Latihan di pagi hari (04:00 - 08:00).":
        return lang.currentLanguage == 'en' ? "Workout in the morning (04:00 - 08:00)." : lang.currentLanguage == 'es' ? "Entrena por la mañana (04:00 - 08:00)." : "朝（04:00〜08:00）にワークアウト。";
      case "Latihan di malam hari (20:00 - 00:00).":
        return lang.currentLanguage == 'en' ? "Workout at night (20:00 - 00:00)." : lang.currentLanguage == 'es' ? "Entrena por la noche (20:00 - 00:00)." : "夜（20:00〜00:00）にワークアウト。";
      case "Capai total jarak 42 KM (Marathon).":
        return lang.currentLanguage == 'en' ? "Reach a total distance of 42 KM (Marathon)." : lang.currentLanguage == 'es' ? "Alcanza un total de 42 KM (Maratón)." : "合計距離42KM（マラソン）に到達。";
      default:
        return description;
    }
  }

  static String translateUi(String text, LanguageProvider lang) {
    if (lang.currentLanguage == 'id') return text;

    switch (text) {
      case "TERBUKA! 🎉":
        return lang.currentLanguage == 'en' ? "UNLOCKED! 🎉" : lang.currentLanguage == 'es' ? "¡DESBLOQUEADO! 🎉" : "ロック解除! 🎉";
      case "TERKUNCI 🔒":
        return lang.currentLanguage == 'en' ? "LOCKED 🔒" : lang.currentLanguage == 'es' ? "BLOQUEADO 🔒" : "ロック 🔒";
      case "Tutup":
        return lang.currentLanguage == 'en' ? "Close" : lang.currentLanguage == 'es' ? "Cerrar" : "閉じる";
      case "OK":
        return lang.currentLanguage == 'en' ? "OK" : lang.currentLanguage == 'es' ? "Aceptar" : "OK";
      case "BADGE UNLOCKED! 🏆":
        return lang.currentLanguage == 'en' ? "BADGE UNLOCKED! 🏆" : lang.currentLanguage == 'es' ? "¡INSIGNIA DESBLOQUEADA! 🏆" : "バッジ獲得! 🏆";
      case "KEREN!":
        return lang.currentLanguage == 'en' ? "AWESOME!" : lang.currentLanguage == 'es' ? "¡GENIAL!" : "すごい!";
      case "Terus latihan untuk naik rank!":
        return lang.currentLanguage == 'en' ? "Keep training to rank up!" : lang.currentLanguage == 'es' ? "¡Sigue entrenando para subir de rango!" : "ランクアップのためにトレーニングを続けよう！";
      case "Rank":
        return lang.currentLanguage == 'en' ? "Rank" : lang.currentLanguage == 'es' ? "Rango" : "ランク";
      default:
        return text;
    }
  }

  static String translateRank(String rankName, LanguageProvider lang) {
    if (lang.currentLanguage == 'id') return rankName;
    switch(rankName) {
      case "No Rank":
        return lang.currentLanguage == 'en' ? "No Rank" : lang.currentLanguage == 'es' ? "Sin Rango" : "ランクなし";
      case "Lemah":
        return lang.currentLanguage == 'en' ? "Weak" : lang.currentLanguage == 'es' ? "Débil" : "弱い";
      case "Lumayan":
        return lang.currentLanguage == 'en' ? "Average" : lang.currentLanguage == 'es' ? "Promedio" : "平均";
      case "Kuat":
        return lang.currentLanguage == 'en' ? "Strong" : lang.currentLanguage == 'es' ? "Fuerte" : "強い";
      case "Sangat Kuat":
        return lang.currentLanguage == 'en' ? "Very Strong" : lang.currentLanguage == 'es' ? "Muy Fuerte" : "とても強い";
      case "Atlit":
        return lang.currentLanguage == 'en' ? "Athlete" : lang.currentLanguage == 'es' ? "Atleta" : "アスリート";
      case "Dewa":
        return lang.currentLanguage == 'en' ? "God" : lang.currentLanguage == 'es' ? "Dios" : "神";
      default:
        return rankName;
    }
  }
}
