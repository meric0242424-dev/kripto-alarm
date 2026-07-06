# Kripto Alarm Merkezi

Piyasayı anlık takip et, fırsatları kaçırma. Flutter ile yazılmış, Binance
public API üzerinden gerçek zamanlı veri kullanan kripto alarm uygulaması.

## Özellikler (v1)
- Ana sayfa: canlı fiyat takibi, en çok yükselen/düşenler
- Coin detay: fiyat grafiği, RSI(14), MACD, AI Piyasa Puanı (0-100)
- Alarm Merkezi: fiyat üstü/altı ve RSI bazlı alarm kurma
- Arkaplan kontrolü: uygulama kapalıyken bile 15 dakikada bir alarmları
  kontrol edip yerel bildirim gönderir (Firebase gerekmez, WorkManager kullanır)

## GitHub üzerinden APK nasıl derlenir? (Android Studio KURMADAN)

1. **GitHub'da yeni bir repo oluştur** (örn. `kripto-alarm`), Public veya Private
   fark etmez.

2. **Bu klasördeki tüm dosyaları** o repoya yükle. En kolay yol:
   - GitHub'da repo sayfasında "Add file" > "Upload files" ile bu klasörün
     içindeki her şeyi (lib/, pubspec.yaml, .github/ klasörü dahil) sürükle-bırak yap.
   - `.github` klasörü gizli göründüğü için dosya gezgininde "gizli dosyaları göster"
     seçeneğini açman gerekebilir, yoksa GitHub web arayüzünden yüklerken
     otomatik görünür.

3. **Commit'i onayla** ("Commit changes"). Bu push işlemi otomatik olarak
   GitHub Actions'ı tetikleyecek.

4. **Actions sekmesine git** (repo üstündeki menüde "Actions"). "Build APK"
   adında bir workflow çalışıyor olacak. Birkaç dakika sürer (Flutter kurulumu +
   derleme).

5. Workflow yeşil tik ile bitince, workflow sayfasının en altında
   **Artifacts** bölümünde `kripto-alarm-apk` dosyasını göreceksin. Ona tıkla,
   bir zip inecek, içinde `app-release.apk` var.

6. Bu APK'yı telefonuna aktar (Google Drive, WhatsApp kendine gönderme, USB
   kablo — hangisi kolaysa), telefon ayarlarından "bilinmeyen kaynaklardan
   yükleme" iznini aç, APK'ya dokun, kur.

## Eğer derleme hata verirse
Actions sekmesindeki kırmızı X'e tıklayıp log çıktısını bana yapıştır, hatayı
birlikte çözeriz. Bu genelde ya bir paket sürüm uyuşmazlığı ya da Android
Gradle ayarındaki küçük bir detaydır — repo'daki dosyaları güncelleyip tekrar
push ederek düzeltiriz, sen hiçbir yerel kurulum yapmadan.

## Notlar
- Fiyat verisi Binance public API'sinden çekiliyor, API anahtarı gerekmiyor.
- Alarmlar telefonda yerel olarak (SharedPreferences) saklanıyor.
- Arka plan kontrolü Android'in izin verdiği minimum periyot olan 15 dakikada
  bir çalışır; anlık (saniyeler içinde) tetiklenme istiyorsan bu bir sunucu +
  push bildirim (Firebase) mimarisi gerektirir — istersen bunu v2 olarak
  ekleyebiliriz.
