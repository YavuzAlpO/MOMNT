# MOMNT — proje kuralları

MOMNT, konum tabanlı anlık buluşma / check-in uygulamasıdır. Aşağıdaki sabitler ürünün çekirdek kurallarıdır; kod, UI ve iş mantığında bu değerler değiştirilmeden kullanılmalıdır.

## Konum sabitleri

| Kural | Değer | Anlamı |
| --- | --- | --- |
| Keşif haritası | **20 km** | Haritada ve keşif listesinde yalnızca kullanıcının 20 km yarıçapındaki etkinlikler / MOMNT’ler gösterilir. |
| Check-in yakınlığı | **30 m** | Kullanıcı bir MOMNT’e check-in yapabilmek için konumunun etkinlik noktasına en fazla 30 metre mesafede olması gerekir. |
| Otomatik çıkış | **1 km** | Check-in yapılmış bir kullanıcı, etkinlik noktasına 1 km’den fazla uzaklaşırsa otomatik olarak check-out edilir. |
| Zaman aşımı | **4 saat** | Check-in oturumu en fazla 4 saat sürer; süre dolunca kullanıcı otomatik olarak check-out edilir. |

Kodda bu değerler `lib/services/location_service.dart` içindeki `MomntLocationRules` sabitleriyle tutulur:

- `discoveryRadiusMeters = 20000`
- `checkInProximityMeters = 30`
- `autoExitDistanceMeters = 1000`
- `sessionTimeout = Duration(hours: 4)`

## Uygulama kuralları

- Mesafe hesaplamalarında `geolocator` (`Geolocator.distanceBetween`) kullanılmalıdır.
- Check-in öncesi konum izni istenmeli; izin yoksa veya servis kapalıysa check-in yapılmamalıdır.
- Keşif sorguları her zaman 20 km yarıçapı ile sınırlanmalıdır.
- Check-in yalnızca 30 m içinde ve izinli konum ile yapılabilir.
- Aktif check-in’de konum 1 km’yi aşarsa veya 4 saat dolarsa otomatik çıkış tetiklenmelidir.
- Sabitleri sihirli sayı olarak dağıtma; `MomntLocationRules` kullan.
