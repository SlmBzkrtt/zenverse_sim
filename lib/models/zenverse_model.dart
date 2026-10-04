import 'package:flutter/material.dart';

class ScenicPoint {
  final String label;
  final double angle;

  const ScenicPoint({
    required this.label,
    required this.angle,
  });
}

class DirectionZone {
  final double startAngle;
  final double endAngle;
  final String label;

  const DirectionZone({
    required this.startAngle,
    required this.endAngle,
    required this.label,
  });
}

class ZenVerseModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String environmentName;
  final String displayLocationName;
  final String actionButtonLabel;
  final String quote;
  final bool isUnlocked;
  final List<Color> themeColors;
  final IconData icon;
  final List<String> features;
  final List<ScenicPoint> scenicPoints;
  final List<String> thoughts;
  final List<String> styleLabels;
  final List<String> atmosphereLabels;
  final List<String> ambientWeatherLabels;
  final List<DirectionZone> directionZones;
  final String defaultDirectionLabel;

  const ZenVerseModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.environmentName,
    required this.displayLocationName,
    required this.actionButtonLabel,
    required this.quote,
    required this.isUnlocked,
    required this.themeColors,
    required this.icon,
    required this.features,
    required this.scenicPoints,
    required this.thoughts,
    required this.styleLabels,
    required this.atmosphereLabels,
    required this.ambientWeatherLabels,
    required this.directionZones,
    required this.defaultDirectionLabel,
  });

  String getDirectionLabel(double yaw) {
    final double a = yaw % 360.0;
    for (final zone in directionZones) {
      if (zone.startAngle > zone.endAngle) {
        if (a >= zone.startAngle || a < zone.endAngle) {
          return zone.label;
        }
      } else {
        if (a >= zone.startAngle && a < zone.endAngle) {
          return zone.label;
        }
      }
    }
    return defaultDirectionLabel;
  }
}

typedef SimulatorModel = ZenVerseModel;

const List<ZenVerseModel> availableSimulators = [
  // 1. COCONUT SIMULATOR
  ZenVerseModel(
    id: 'coconut',
    title: 'Coconut Simulator',
    subtitle: 'Canlı Sahil Köyü & Gün Batımı',
    description:
        'Altın sarısı kumsalda, kıyıya vuran sıcak okyanus dalgalarının hemen önünde duran bir Hindistan cevizisin. Arkanda ışıkları yanan iki katlı sahil köyü evleri, kamp ateşi etrafında gitar çalıp sohbet eden insanlar, Tiki Bar müdavimleri, iskelede gün batımını izleyenler, ufukta zıplayan yunuslar ve rüzgarda salınan palmiye koruları... 360 derece yaşayan bu dünyayı huzurla izle.',
    environmentName: 'Pasifik Koyu • Canlı 360° Sahil Köyü',
    displayLocationName: 'PASİFİK KOYU',
    actionButtonLabel: 'SİMÜLASYONA BAŞLA (HİNDİSTAN CEVİZİ OL)',
    quote:
        '"Bazen hayattaki en büyük eylem, sadece kumsalda duran bir hindistan cevizi olmaktır."',
    isUnlocked: true,
    themeColors: [
      Color(0xFFFF6B4A),
      Color(0xFFFFB347),
      Color(0xFF1E5F74),
    ],
    icon: Icons.beach_access_rounded,
    features: [
      '360° Canlı Kumsal, Okyanus & Tüten Volkanik Adalar',
      'İki Katlı Sahil Köyü Evleri, Verandalar & Ahşap Yürüyüş Yolu',
      'Kamp Ateşi Başında Sohbet Eden & Gitar Çalan 7 İnsan',
      'Canlı Tiki Bar, Barmen, İskele İnsanları & Balıkçı Sandalı',
      'Ufukta Zıplayan Yunuslar, Dilek Fenerleri & 6 Yelkenli',
      'Voleybol Oynayanlar, Şezlongda Güneşlenenler & Kumdan Kale',
      '4 Atmosfer Modu (Gün Batımı, Biyolüminesans Gece, Öğle, Yağmur)',
      '5 Kamera Dönüş Şekli & 5 Farklı Hindistan Cevizi Stili',
      'Gezen Yengeçler, Martı Sürüleri, Kayan Yıldızlar & Display Modu',
    ],
    scenicPoints: [
      ScenicPoint(label: '🌅 Gün Batımı (0°)', angle: 0.0),
      ScenicPoint(label: '🌉 Ahşap İskele (74°)', angle: 74.0),
      ScenicPoint(label: '🏡 Sahil Köyü (125°)', angle: 125.0),
      ScenicPoint(label: '🔥 Kamp Ateşi (163°)', angle: 163.0),
      ScenicPoint(label: '🍹 Tiki Bar & Koy (215°)', angle: 215.0),
    ],
    thoughts: [
      'Şu an bir Hindistan cevizisin. Yapacak hiçbir şey yok. Sadece anın tadını çıkar.',
      'Arkandaki kamp ateşinin etrafında 7 kişi akustik gitar eşliğinde sohbet ediyor.',
      'İki katlı ahşap sahil evinin bacasından tüten duman akşam rüzgarına karışıyor.',
      'Ufuk çizgisinde iki yunus suyun içinden süzülerek zıplıyor.',
      'İskelenin ucunda oturan iki kişi ayaklarını denize sarkıtmış gün batımını izliyor.',
      'Bir yengeç ailesi yanından geçip gitti. Onların telaşı var, senin ise hiç acelen yok.',
      'Tiki Bar\'da barmen renkli kokteyller hazırlarken taburedeki müdavimler gülüşüyor.',
      'Palmiyelerin arasındaki hamakta uzanan biri hasır şapkasının altında şekerleme yapıyor.',
      'Sahil köyü yürüyüş yolundaki yanan tiki meşaleleri akşam esintisinde titreşiyor.',
      'Kıyıya yakın balıkçı sandalındaki ihtiyar oltasını denize bırakmış sabırla bekliyor.',
      'Gökyüzüne bırakılan sıcak dilek fenerleri sahil köyünün üzerinden yıldızlara doğru yükseliyor.',
      'Kumsalda voleybol filesinin iki yanında zıplayan oyuncular topu karşıya aşırıyor.',
      'Uzaktaki volkanik adanın zirvesinden ince bir buhar bulutu gökyüzüne doğru kıvrılıyor.',
      'Deniz fenerinin döner ışığı batı kayalıklarını ve açık okyanusu sessizce tarıyor.',
      'Çocukların yaptığı kırmızı bayraklı kumdan kale dalgalara meydan okuyor.',
      'Açıkta demirlemiş katamaran yatın parti ışıkları okyanus yüzeyinde parıldıyor.',
      'Biyolüminesans gece modunda kıyıya vuran her dalga mavi-turkuaz ışıklar saçıyor.',
      'Lo-Fi yağmur modunda sıcak sahil evlerinin pencereleri daha da huzurlu görünüyor.',
      'Zaman akıp gidiyor, martılar kanat çırpıyor, okyanus nefes alıyor ve sen buradasın.',
      'Hiçbir görev yok. Puan yok. Sadece yaşayan bu 360° sahil, rüzgar ve sen.',
    ],
    styleLabels: [
      '🥥 Realistic',
      '🕶️ Arcade',
      '🍹 Kokteyl',
      '👑 Ada Kralı',
      '🎧 Lo-Fi Chill',
    ],
    atmosphereLabels: [
      '🌅 Gün Batımı',
      '🌌 Gece Modu',
      '☀️ Öğle Güneşi',
      '🌧️ Lo-Fi Yağmur',
    ],
    ambientWeatherLabels: [
      '26°C • Altın Saat Meltemi',
      '22°C • Biyolüminesans Medcezir',
      '30°C • Parlak Tropikal Esinti',
      '21°C • Ilık Lo-Fi Yaz Yağmuru',
    ],
    directionZones: [
      DirectionZone(
        startAngle: 345,
        endAngle: 12,
        label: 'GÜN BATIMI, OKYANUS & UFUK ÇİZGİSİ',
      ),
      DirectionZone(
        startAngle: 12,
        endAngle: 35,
        label: 'ZIPLAYAN YUNUSLAR & DOĞU DENİZİ',
      ),
      DirectionZone(
        startAngle: 35,
        endAngle: 56,
        label: 'KIYI YÜRÜYÜŞÜ YAPAN ÇİFT & KUMSAL',
      ),
      DirectionZone(
        startAngle: 56,
        endAngle: 86,
        label: 'BALIKÇI SANDALI & AHŞAP İSKELE İNSANLARI',
      ),
      DirectionZone(
        startAngle: 86,
        endAngle: 112,
        label: 'PALMİYE HAMAĞI, VOLEYBOL & KUMDAN KALE',
      ),
      DirectionZone(
        startAngle: 112,
        endAngle: 152,
        label: 'İKİ KATLI SAHİL EVİ, SÖRF VİLLASI & VERANDA',
      ),
      DirectionZone(
        startAngle: 152,
        endAngle: 188,
        label: 'KAMP ATEŞİ SOHBETİ, GİTARİST & ŞELALE',
      ),
      DirectionZone(
        startAngle: 188,
        endAngle: 220,
        label: 'CANLI TİKİ BAR, BARMEN & MEYDAN IŞIKLARI',
      ),
      DirectionZone(
        startAngle: 220,
        endAngle: 272,
        label: 'BALIKÇI KULÜBELERİ & BATI KOYU ATEŞİ',
      ),
      DirectionZone(
        startAngle: 272,
        endAngle: 310,
        label: 'DENİZ FENERİ, BEKÇİ EVİ & KAYALIKLAR',
      ),
    ],
    defaultDirectionLabel: 'KATAMARAN YAT & TÜTEN VOLKANİK ADALAR',
  ),

  // 2. PINE TREE SIMULATOR
  ZenVerseModel(
    id: 'pine_tree',
    title: 'Pine Tree Simulator',
    subtitle: 'Karlı Laponya, Viyadük Treni & Kuzey Işıkları',
    description:
        'Bembeyaz karlarla kaplı Laponya ve İskandinav Alpleri\'nde, sarkıtlı bir granit kayalığın zirvesinde duran görkemli bir Kuzey Çamısın. Karşında dev taş viyadük köprüsünden buharlar saçarak geçen kırmızı Kutup Ekspresi treni, donmuş buzul gölünde kayan patenciler ve iglo; etrafında Norveç ahşap kilisesi (Stavkirke), kayak pistinden süzülen kayakçılar, köpekli kızak, açık hava jakuzisi ve gökyüzünde dans eden Kuzey Işıkları (Aurora)...',
    environmentName: 'Kuzey Laponya • 360° Kutup Treni, Kayak Köyü & Aurora',
    displayLocationName: 'KUZEY LAPONYA ALPLERİ',
    actionButtonLabel: 'SİMÜLASYONA BAŞLA (ÇAM AĞACI OL)',
    quote:
        '"Köklerin karlı kayaların kalbindeyse, kuzey rüzgarı dallarında sadece şarkı söyler."',
    isUnlocked: true,
    themeColors: [
      Color(0xFF1E88E5),
      Color(0xFF00ACC1),
      Color(0xFF0D2137),
    ],
    icon: Icons.park_rounded,
    features: [
      '360° Karlı Alpler, Dev Taş Viyadük Köprüsü & Buharlı Kutup Ekspresi Treni',
      'Donmuş Buzul Gölünde Buz Pateni Yapanlar, İglo & Buz Balıkçısı',
      'Gökyüzünde Dans Eden Kuzey Işıkları (Aurora) & Sıçrayan Balinalar',
      'Tarihi Norveç Ahşap Kilisesi (Stavkirke), Kırmızı Kulübeler & Buharlı Jakuzi',
      'Kayak Pistinden Süzülen Kayakçılar, Dağ Şaleleri & Su Değirmeni',
      'Laponya Kamp Ateşi, Dağcılar, Husky Köpekli Kızak & Ren Geyiği Kızağı',
      'Dağ Teleferiği, Otlayan 6 Boynuzlu Ren Geyiği, Sincap & Kardinal Kuşu',
      '5 Çam Ağacı Stili (Realistic, Kayak Gözlüklü, Yılbaşı, Bilge Ent, Lo-Fi)',
      '4 Atmosfer Modu, 5 Kamera Dönüş Şekli & Sinematik Display Modu',
    ],
    scenicPoints: [
      ScenicPoint(label: '🚂 Viyadük Treni & Buz Gölü (0°)', angle: 0.0),
      ScenicPoint(label: '⛪ Stavkirke & Jakuzi (74°)', angle: 74.0),
      ScenicPoint(label: '⛷️ Kayak Pisti & Köy (128°)', angle: 128.0),
      ScenicPoint(label: '🛷 Köpekli Kızak & Kamp (165°)', angle: 165.0),
      ScenicPoint(label: '🦌 Ren Geyikleri & Teleferik (218°)', angle: 218.0),
    ],
    thoughts: [
      'Şu an karlı Laponya vadisine bakan ulu bir çam ağacısın. Dalların kar tanelerini tutuyor.',
      'Karşıdaki dev taş viyadük köprüsünden kırmızı buharlı Kutup Ekspresi treni dumanlar saçarak geçiyor.',
      'Donmuş buzul gölünün üzerinde atkılı patenciler zarif kavisler çizerek kayıyor.',
      'Kubbeli kar iglosunun girişinden dışarıya sıcacık altın rengi bir ışık süzülüyor.',
      'Gökyüzünde yeşil ve mor Kuzey Işıkları (Aurora Borealis) sessiz bir senfoni gibi dalgalanıyor.',
      'Kayak pistinden aşağıya süzülen kayakçılar taze karların üzerinde kıvrımlı izler bırakıyor.',
      'Kırmızı balıkçı kulübesinin verandasındaki sıcak ahşap jakuziden buharlar yükseliyor.',
      'Arkandaki Laponya kampında üç Husky köpeğinin çektiği ahşap kızak yeni bir maceraya hazır.',
      'Köklerinin arasındaki sevimli sincap elindeki meşe palamuduyla etrafı kolaçan ediyor.',
      'Tarihi Norveç ahşap kilisesinin (Stavkirke) ejderha başlı çatıları karların arasında yükseliyor.',
      'İki zirve arasındaki teleferik kabini sarı ışıklarını yakmış bulutların arasından süzülüyor.',
      'Çatallı boynuzlu altı ren geyiği karlı çam korusunun kıyısında sakin sakin otluyor.',
      'Fiyort kanalında su yüzüne sıçrayan balinalar ve kırmızı-beyaz yelkenli Viking gemisi görünüyor.',
      'A-Frame dağ şalesinin dev üçgen camından dışarıya sıcacık şömine ışığı vuruyor.',
      'Yılbaşı modunda dallarındaki rengarenk ışıklar ve tepedeki yıldız tüm karlı yamacı aydınlatıyor.',
      'Dallarına konan küçük kırmızı kardinal kuşu seninle birlikte buzul vadisini seyrediyor.',
      'Yüzyıllar geçer, kar yağar, trenler geçer; sen ise köklerinle bu zirvede dimdik durursun.',
      'Hiçbir yere yetişmen gerekmiyor. Sadece bir kuzey çamı olmanın huzurunu yaşa.',
      'Kar fırtınası başladığında her bir dalın bembeyaz bir sessizliğe bürünüyor.',
      'Kuzeyin kalbinde, zamanın dışında, 360 derece yaşayan bir kış masalındasın.',
    ],
    styleLabels: [
      '🌲 Realistic',
      '🕶️ Kayakçı Çam',
      '🎄 Yılbaşı Ağacı',
      '🦉 Bilge Ent',
      '🎧 Lo-Fi Çam',
    ],
    atmosphereLabels: [
      '🌌 Aurora Alacakaranlık',
      '🌠 Kutup Gecesi',
      '☀️ Alpler Güneşi',
      '🌨️ Kar Fırtınası',
    ],
    ambientWeatherLabels: [
      '-3°C • Aurora Alacakaranlığı & Kar',
      '-9°C • Kutup Işıkları Gecesi',
      '2°C • Parlak Karlı Alpler Güneşi',
      '-11°C • Yoğun Laponya Kar Tipisi',
    ],
    directionZones: [
      DirectionZone(
        startAngle: 335,
        endAngle: 28,
        label: 'TAŞ VİYADÜK KÖPRÜSÜ, KUTUP TRENİ, İGLO & BUZ PATENCİLERİ',
      ),
      DirectionZone(
        startAngle: 28,
        endAngle: 56,
        label: 'VİKİNG GEMİSİ, SIÇRAYAN BALİNALAR & FİYORT KANALI',
      ),
      DirectionZone(
        startAngle: 56,
        endAngle: 98,
        label: 'STAVKİRKE AHŞAP KİLİSE, İSKELE & BUHARLI JAKUZİ',
      ),
      DirectionZone(
        startAngle: 98,
        endAngle: 152,
        label: 'KAYAK PİSTİ, KAYAKÇILAR, DAĞ KÖYÜ & SU DEĞİRMENİ',
      ),
      DirectionZone(
        startAngle: 152,
        endAngle: 195,
        label: 'LAPONYA KAMP ATEŞİ, KÖPEKLİ KIZAK & BUZUL ŞELALESİ',
      ),
      DirectionZone(
        startAngle: 195,
        endAngle: 248,
        label: 'REN GEYİĞİ KIZAĞI, OTLAYAN GEYİKLER & TELEFERİK',
      ),
      DirectionZone(
        startAngle: 248,
        endAngle: 335,
        label: 'KARLI ÇAM ORMANI, KUTUP TİLKİLERİ & TAŞ GÖZETLEME KULESİ',
      ),
    ],
    defaultDirectionLabel: 'TAŞ VİYADÜK KÖPRÜSÜ & KUTUP EKSPRESİ TRENİ',
  ),

  // 3. MOSSY ROCK SIMULATOR
  ZenVerseModel(
    id: 'mossy_rock',
    title: 'Mossy Rock Simulator',
    subtitle: 'Kyoto Zen Vadisi, Altın Köşk & Onsen',
    description:
        'Kyoto vadisinde, tırmıklanmış beyaz Zen çakılları ve zümrüt göletin kıyısında, yanındaki bambu oluktan (Kakei) billur sular damlayan kadim bir yosunlu tapınak kayasısın. Karşında karlı Fuji Dağı, suyun içindeki dev kırmızı Yüzen Torii Kapısı ve Altın Köşk (Kinkaku-ji); etrafında kırmızı kemer köprü, mor salkım (Wisteria) tüneli, beş katlı Pagoda, Çay Evi, Ryokan kaplıcası (Onsen), kapibara ve uçuşan Sakura yaprakları...',
    environmentName: 'Kyoto Vadisi • 360° Altın Köşk, Yüzen Torii & Onsen',
    displayLocationName: 'KYOTO ZEN VADİSİ',
    actionButtonLabel: 'SİMÜLASYONA BAŞLA (ZEN KAYASI OL)',
    quote:
        '"Bambu oluktan su damlar, sakura yaprakları uçuşur; kaya bin yıllık sükunetle kalır."',
    isUnlocked: true,
    themeColors: [
      Color(0xFF388E3C),
      Color(0xFFE91E63),
      Color(0xFF1D3557),
    ],
    icon: Icons.spa_rounded,
    features: [
      '360° Fuji Dağı, Gölette Yüzen Dev Torii Kapısı & Altın Köşk (Kinkaku-ji)',
      'Bambu Su Oluğu (Kakei), Kurbağa & Yusufçuklu Dev Yosunlu Tapınak Kayası',
      'Kırmızı Kemer Köprü (Taiko-bashi), Kimonolu Gezginler & Mor Salkım Tüneli',
      '5 Katlı Pagoda, Karesansui Taş Bahçesi, Çay Evi & Çay Seremonisi',
      'Geleneksel Ryokan Hanı, Buharlı Doğal Kaplıca (Onsen), Kapibara & Maymunlar',
      '14 Fushimi Inari Torii Kapısı Yolu, Arashiyama Bambu Ormanı & Şelaleler',
      'Dev Bronz Buda Heykeli, Kırmızı Önlüklü Jizo Heykelleri & Tapınak Çanı',
      '5 Zen Kayası Stili (Realistic, Karate, Kutsal Shimenawa, Sakura Ruhu, Lo-Fi)',
      '4 Atmosfer Modu, 5 Kamera Dönüş Şekli & Sinematik Display Modu',
    ],
    scenicPoints: [
      ScenicPoint(label: '⛩️ Fuji, Yüzen Torii & Altın Köşk (0°)', angle: 0.0),
      ScenicPoint(label: '🌸 Kırmızı Köprü & Mor Salkım (72°)', angle: 72.0),
      ScenicPoint(label: '🍵 Pagoda, Zen Bahçesi & Çay Evi (126°)', angle: 126.0),
      ScenicPoint(label: '♨️ Ryokan & Sıcak Onsen (166°)', angle: 166.0),
      ScenicPoint(label: '🎍 Torii Yolu, Bambu & Buda (220°)', angle: 220.0),
    ],
    thoughts: [
      'Şu an Kyoto vadisinde kutsal bir Zen kayasısın. Yanındaki bambu oluktan serin su damlıyor.',
      'Göletin ortasında yükselen dev kırmızı Yüzen Torii Kapısı suya kusursuzca yansıyor.',
      'Kıyıdaki iki katlı Altın Köşk (Kinkaku-ji) ve çatısındaki altın Zümrüdüanka kuşu güneşte parıldıyor.',
      'Üzerindeki minik yeşil kurbağa ve kanat çırpan mavi yusufçuk seninle birlikte göleti izliyor.',
      'Kırmızı kemer köprünün yanındaki çardaktan sarkan mor salkım (Wisteria) çiçekleri rüzgarda salınıyor.',
      'Zen rahibi, beş katlı Pagoda\'nın önündeki beyaz çakıl bahçesini (Karesansui) özenle tırmıklıyor.',
      'Geleneksel Çay Evi\'nin verandasında matcha çayı ikram edilirken tatlı bir sohbet sürüyor.',
      'Ryokan hanının önündeki doğal taş kaplıcanın (Onsen) sıcak sularından buharlar yükseliyor.',
      'Kaplıcanın kenarında başında beyaz havlusuyla keyif yapan kapibara ve kar maymunları gözlerini kapatmış.',
      'Bambu su çeşmesi (Shishi-odoshi) dolup taşarak vadide huzurlu bir "tak" sesi yankılatıyor.',
      'Rüzgar estikçe pembe Sakura yaprakları göletin ve senin kadife yosunlarının üzerine konuyor.',
      'On dört kırmızı Torii kapısının dizildiği dağ patikasından tapınağa doğru yürüyen gezginler var.',
      'Fenerli ahşap kayıklar (Yakatabune) göletin zümrüt sularında sessizce süzülüyor.',
      'Gece modunda suya bırakılan kağıt dilek fenerleri (Toro Nagashi) yıldızlarla yarışıyor.',
      'Bronz Buda heykelinin önündeki tütsüden yükselen ince duman bambu ormanına karışıyor.',
      'Tapınak çan kulesindeki (Bonsho) rahip ahşap tokmağı salladığında derin bir huzur yayılıyor.',
      'Zihin durulduğunda, bir kayanın hareketsizliğinde bütün evrenin hareketini görebilirsin.',
      'Lo-Fi yağmur damlaları nilüfer yapraklarının üzerinde minik halkalar oluşturuyor.',
      'Gökyüzünden geçen telli turna sürüsü karlı Fuji Dağı\'na doğru kanat çırpıyor.',
      'Sadece nefes al ve bu 360° Kyoto Zen bahçesinin senin etrafında akmasına izin ver.',
    ],
    styleLabels: [
      '🪨 Realistic',
      '🕶️ Karate Kaya',
      '🏮 Tapınak Taşı',
      '🌸 Sakura Ruhu',
      '🎧 Lo-Fi Zen',
    ],
    atmosphereLabels: [
      '🌅 Kızıl Kyoto',
      '🏮 Fener Gecesi',
      '☀️ Zen Öğlesi',
      '🌧️ Bambu Yağmuru',
    ],
    ambientWeatherLabels: [
      '21°C • Sakura Meltemi',
      '16°C • Ateşböceği & Fener Gecesi',
      '25°C • Berrak Kyoto Güneşi',
      '18°C • Huzurlu Muson Çisenti',
    ],
    directionZones: [
      DirectionZone(
        startAngle: 335,
        endAngle: 22,
        label: 'FUJİ DAĞI, YÜZEN TORİİ KAPISI & KOİ GÖLETİ',
      ),
      DirectionZone(
        startAngle: 22,
        endAngle: 56,
        label: 'ALTIN KÖŞK (KİNKAKU-Jİ) & FENERLİ KAYIKLAR',
      ),
      DirectionZone(
        startAngle: 56,
        endAngle: 98,
        label: 'KIRMIZI KEMER KÖPRÜ, KİMONOLULAR & MOR SALKIM TÜNELİ',
      ),
      DirectionZone(
        startAngle: 98,
        endAngle: 152,
        label: 'BEŞ KATLI PAGODA, ZEN TAŞ BAHÇESİ & ÇAY EVİ',
      ),
      DirectionZone(
        startAngle: 152,
        endAngle: 195,
        label: 'RYOKAN HANI, BUHARLI ONSEN KAPLICASI & KAPİBARA',
      ),
      DirectionZone(
        startAngle: 195,
        endAngle: 242,
        label: 'FUSHİMİ İNARİ TORİİ YOLU, ŞELALE & BAMBU ORMANI',
      ),
      DirectionZone(
        startAngle: 242,
        endAngle: 335,
        label: 'DEV BRONZ BUDA, JİZO HEYKELLERİ & ÇAN KULESİ',
      ),
    ],
    defaultDirectionLabel: 'YÜZEN TORİİ KAPISI & FUJİ DAĞI GÖLETİ',
  ),

  // 4. STREET LAMP SIMULATOR
  ZenVerseModel(
    id: 'street_lamp',
    title: 'Street Lamp Simulator',
    subtitle: 'Avrupa Gece Meydanı, Tramvay & Kafeler',
    description:
        'Avrupa\'nın ıslak taş döşeli tarihi bir meydanında, yere altın bir ışık hunisi düşüren çiçek sepetli ve sokak tabelalı dökme demir bir sokak lambasısın. Karşında taş nehir köprüsü, ışıklı Eyfel/Galata tarzı kule, sahaflar ve kıvılcımlar saçarak geçen nostaljik sarı tramvay; etrafında tuval boyayan sokak ressamı, çeşme başı müzisyenleri, Fransız kafesi, saksafoncu, gece ramen durağı, caz kulübü, Metropolitain metro kemeri, atlıkarınca ve saat kulesi...',
    environmentName: 'Tarihi Avrupa Meydanı • 360° Tramvay, Kafe & Caz Sokağı',
    displayLocationName: 'TARİHİ AVRUPA MEYDANI',
    actionButtonLabel: 'SİMÜLASYONA BAŞLA (SOKAK LAMBASI OL)',
    quote:
        '"Herkes bir yerlere yetişirken karanlıkta durup şehri aydınlatmak, sessiz bir sanattır."',
    isUnlocked: true,
    themeColors: [
      Color(0xFFF4A261),
      Color(0xFFE76F51),
      Color(0xFF1D2D44),
    ],
    icon: Icons.light_rounded,
    features: [
      '360° Kesintisiz Avrupa Mimarisi, Islak Taş Yansımaları & Işık Hunisi',
      'Nehir Köprüsü, Işıklı Panoramik Kule, Sahaflar & Nostaljik Tramvay',
      'Meydan Çeşmesi, Müzisyen Üçlüsü, Sokak Ressamı & Kestane Arabası',
      'Köşe Fransız Kafesi (Café de Nuit), Balkonda Saksafoncu & Plak Dükkanı',
      'Le Chat Noir Caz Kulübü, Gece Ramen & Krep Durağı & Neon Tabelalar',
      'Astronomik Saat Kulesi, Art Nouveau Metro Girişi & Işıklı Atlıkarınca',
      'Çiçek Sepetli & Tabelalı Sokak Lambası, Gece Kelebekleri & Kediler',
      '5 Sokak Lambası Stili (Realistic, Cyberpunk, Caz Feneri, Kraliyet, Lo-Fi)',
      '4 Atmosfer Modu, 5 Kamera Dönüş Şekli & Sinematik Display Modu',
    ],
    scenicPoints: [
      ScenicPoint(label: '🚋 Tramvay, Köprü & Kule (0°)', angle: 0.0),
      ScenicPoint(label: '🎻 Çeşme, Ressam & Müzisyenler (74°)', angle: 74.0),
      ScenicPoint(label: '☕ Fransız Kafesi & Saksafoncu (128°)', angle: 128.0),
      ScenicPoint(label: '🎷 Caz Kulübü & Ramen Sokağı (168°)', angle: 168.0),
      ScenicPoint(label: '🕰️ Saat Kulesi, Metro & Atlıkarınca (222°)', angle: 222.0),
    ],
    thoughts: [
      'Şu an tarihi bir Avrupa meydanında altın ışık hunisi saçan bir sokak lambasısın.',
      'Üzerindeki "CAFÉ DE NUIT" ve "JAZZ CLUB" tabelaları gece gezginlerine yol gösteriyor.',
      'Nostaljik sarı tramvay çanını çalarak nehir kıyısındaki raylardan kıvılcımlarla geçiyor.',
      'Şövalesinin başındaki sokak ressamı meydanın gece ışıklarını tuvaline aktarıyor.',
      'Meydan çeşmesinin önünde keman, akordeon ve kontrbas çalan üçlünün melodisi yankılanıyor.',
      'Köşedeki Fransız kafesinin tentesi altında insanlar sıcak kahvelerini ve kruvasanlarını paylaşıyor.',
      'Üst katın ferforje balkonuna çıkan bir müzisyen gecenin karanlığına saksafon üflüyor.',
      'Gece ramen ve krep durağının kazanından yükselen buhar, neon ışıkların altında dans ediyor.',
      'Islak Arnavut kaldırımlarındaki su birikintileri senin sarı ışığını bir ayna gibi yansıtıyor.',
      'Art Nouveau tarzı "METROPOLITAIN" metro girişinin kehribar küre lambaları parıldıyor.',
      'Meydanın batı köşesindeki ışıklı atlıkarınca (Carousel) nostaljik müzik kutusu gibi dönüyor.',
      'Astronomik saat kulesinin ışıklı kadranında yelkovan gece yarısına doğru sessizce ilerliyor.',
      'Lo-Fi modda kaşkolun, kulaklığın ve dibinde kıvrılıp uyuyan tekir kediyle meydanın en huzurlu köşesisin.',
      'Kestane arabasından yükselen sıcak duman meydandan geçen şemsiyeli yayaları kendine çekiyor.',
      'Nehirdeki yemekli gezi teknesinin ışıkları taş köprünün kemerleri altından geçerken suya vuruyor.',
      'Cam fenerinin etrafında dönen küçük gece kelebekleri ve çiçek sepetlerin rüzgarda salınıyor.',
      'İnsanlar şemsiyeleriyle telaşla geçip giderken sen hep aynı köşede, dimdik ve sakinsin.',
      'Park bankında tek bir şemsiyenin altına sığınmış iki kişi nehir kulesini izliyor.',
      'Hiçbir yere gitmene gerek yok. Bütün şehir hikayeleri zaten senin ışığının altından geçiyor.',
      'Bu 360° Avrupa meydanında zaman aksın, tramvaylar geçsin, sen sadece parılda.',
    ],
    styleLabels: [
      '🏮 Realistic',
      '🕶️ Cyberpunk',
      '🎷 Caz Feneri',
      '👑 Kraliyet',
      '🎧 Lo-Fi Kedi',
    ],
    atmosphereLabels: [
      '🌇 Alacakaranlık',
      '🌙 Gece Yarısı',
      '☀️ Şehir Öğlesi',
      '🌧️ Lo-Fi Yağmur',
    ],
    ambientWeatherLabels: [
      '15°C • Paris Alacakaranlık Esintisi',
      '11°C • Yıldızlı Gece Yarısı',
      '19°C • Parlak Avrupa Öğlesi',
      '12°C • Islak Taşlar & Lo-Fi Yağmur',
    ],
    directionZones: [
      DirectionZone(
        startAngle: 335,
        endAngle: 22,
        label: 'TAŞ NEHİR KÖPRÜSÜ, PANORAMİK KULE & TEKNELER',
      ),
      DirectionZone(
        startAngle: 22,
        endAngle: 54,
        label: 'NOSTALJİK TRAMVAY DURAĞI, BAZİLİKA & SAHAFLAR',
      ),
      DirectionZone(
        startAngle: 54,
        endAngle: 98,
        label: 'SOKAK RESSAMI, MEYDAN ÇEŞMESİ & MÜZİSYEN ÜÇLÜSÜ',
      ),
      DirectionZone(
        startAngle: 98,
        endAngle: 154,
        label: 'CAFÉ DE NUIT, BALKONDA SAKSAFONCU & PLAK DÜKKANI',
      ),
      DirectionZone(
        startAngle: 154,
        endAngle: 195,
        label: 'LE CHAT NOIR CAZ KULÜBÜ & GECE RAMEN DURAĞI',
      ),
      DirectionZone(
        startAngle: 195,
        endAngle: 245,
        label: 'METROPOLITAIN METRO KEMERİ & ASTRONOMİK SAAT KULESİ',
      ),
      DirectionZone(
        startAngle: 245,
        endAngle: 335,
        label: 'KLASİK OTOMOBİL, IŞIKLI ATLIKARINCA & PARK BANKLARI',
      ),
    ],
    defaultDirectionLabel: 'TAŞ NEHİR KÖPRÜSÜ & NOSTALJİK TRAMVAY',
  ),

  // 5. DESERT CACTUS SIMULATOR
  ZenVerseModel(
    id: 'desert_cactus',
    title: 'Cactus Simulator',
    subtitle: 'Kızıl Kanyon, Petra Tapınağı & Balonlar',
    description:
        'Kızıl Kanyon\'un altın kumulları üzerinde kollarını gökyüzüne açmış görkemli bir Saguaro kaktüsüsün. Gökyüzünde alev püskürterek yükselen 16 sıcak hava balonu ve kanyon uçurumundaki ahşap köprüden dumanlar saçarak geçen Vahşi Batı buharlı treni; etrafında kanyon şelalesiyle beslenen zümrüt vaha gölü, 6 develik İpek Yolu kervanı, kayaya oyulmuş Petra Tapınağı (El-Hazne), kerpiç halı çarşısı, Bedevi kamp ateşi, antik basamaklı piramit ve gözlemevi...',
    environmentName: 'Kızıl Kanyon • 360° Petra Tapınağı, Kanyon Treni & Vaha',
    displayLocationName: 'KIZIL KANYON & PETRA',
    actionButtonLabel: 'SİMÜLASYONA BAŞLA (ÇÖL KAKTÜSÜ OL)',
    quote:
        '"Çölün ortasında dikenlerinle sabretmeyi bilirsen, tepende en güzel çöl çiçeği açar."',
    isUnlocked: true,
    themeColors: [
      Color(0xFFD84315),
      Color(0xFFFFB300),
      Color(0xFF4E342E),
    ],
    icon: Icons.wb_sunny_rounded,
    features: [
      '360° Kızıl Kanyon Kayalıkları, 16 Sıcak Hava Balonu & Kanyon Buharlı Treni',
      'Kanyon Şelalesi, Zümrüt Vaha Gölü, Flamingolar & Büyük 6 Develik Kervan',
      'Kayaya Oyulmuş Antik Petra Tapınağı (El-Hazne) & Kervansaray Kalesi',
      'Kubbeli Kerpiç Halı & Baharat Çarşısı, Tüccarlar & Çömlek Atölyesi',
      'Bedevi Çadırı, İran Halıları, Çöl Ateşi, Ud Müzisyeni & Çöl Tilkisi',
      'Antik Basamaklı Çöl Piramidi, Dikilitaşlar & Dönen Ahşap Yel Değirmeni',
      'Kubbeli Çöl Gözlemevi, Pirinç Teleskoplar, Tumbleweed & Kertenkele',
      '5 Kaktüs Stili (Realistic, Kovboy Şerif, Mariachi, Vaha Kralı, Lo-Fi)',
      '4 Atmosfer Modu, 5 Kamera Dönüş Şekli & Sinematik Display Modu',
    ],
    scenicPoints: [
      ScenicPoint(label: '🚂 Balonlar & Kanyon Treni (15°)', angle: 15.0),
      ScenicPoint(label: '🐪 Şelale, Vaha & Kervan (74°)', angle: 74.0),
      ScenicPoint(label: '🏛️ Petra Tapınağı & Çarşı (122°)', angle: 122.0),
      ScenicPoint(label: '🔥 Bedevi Çadırı & Ateş (165°)', angle: 165.0),
      ScenicPoint(label: '🔭 Piramit, Değirmen & Gözlemevi (230°)', angle: 230.0),
    ],
    thoughts: [
      'Şu an Kızıl Kanyon\'a bakan ulu bir Saguaro kaktüsüsün. Yanındaki kayada küçük bir kertenkele güneşleniyor.',
      'Kızıl kaya sütunlarının arasından 16 rengarenk sıcak hava balonu alev saçarak yükseliyor.',
      'Kanyon uçurumundaki yüksek ahşap köprüden Vahşi Batı buharlı treni beyaz dumanlar püskürterek geçiyor.',
      'Altın kumul sırtında binicileriyle 6 büyük deveden oluşan kervan vahaya doğru yürüyor.',
      'Kızıl kayalardan dökülen şelalenin beslediği zümrüt vaha gölünde pembe flamingolar dinleniyor.',
      'Sarp kumtaşı kayalığa oyulmuş görkemli Petra Tapınağı (El-Hazne) kızıl güneşte parıldıyor.',
      'Kerpiç çarşıda dokuma İran halılarının ve bakır fenerlerin altında tüccarlar nane çayı ikram ediyor.',
      'Bedevi çadırının önündeki çöl ateşinde gezginler ud müziği eşliğinde hikayeler anlatıyor.',
      'Ateşin hemen yanında kocaman kulaklı sevimli bir çöl tilkisi (Fennec) kıvrılmış ısınıyor.',
      'Antik basamaklı çöl piramidinin ve dikilitaşların önünde arkeologlar hiyeroglifleri inceliyor.',
      'Ahşap Vahşi Batı yel değirmeninin pervanesi sıcak kanyon rüzgarıyla durmadan dönüyor.',
      'Kubbeli çöl gözlemevinin önündeki dev pirinç teleskoplarla astronomlar Samanyolu\'nu inceliyor.',
      'Kovboy modunda şerif şapkan, güneş gözlüğün ve kırmızı bandananla kanyonun tek hakimisin.',
      'Mariachi modunda sombrero şapkan ve gitarınla çöl rüzgarına neşeli bir fiesta katıyorsun.',
      'Gece olduğunda çöl gökyüzü milyonlarca yıldız ve kayan yıldızlarla bir elmas gibi parlıyor.',
      'Yıllarca tek bir damla yağmuru sabırla bekleyen çöl, yağmur modunda çiçeklerle uyanıyor.',
      'Hiçbir yere yürümen gerekmiyor; balonlar, trenler ve kervanlar senin etrafında dönüyor.',
      'Tepende açan pembe çöl çiçeğinin etrafında küçük bir sinekkuşu kanat çırpıyor.',
      'Sadece kollarını gökyüzüne açmış bir kaktüs olmanın özgürlüğünü hisset.',
      'Bu 360° çöl masalında ne susuzluk var ne de telaş; sadece sonsuz ufuk ve sen.',
    ],
    styleLabels: [
      '🌵 Realistic',
      '🤠 Kovboy Şerif',
      '🎸 Mariachi',
      '👑 Vaha Kralı',
      '🎧 Lo-Fi Mirage',
    ],
    atmosphereLabels: [
      '🌅 Kızıl Kanyon',
      '🌌 Samanyolu Gecesi',
      '☀️ Çöl Güneşi',
      '⛈️ Çöl Musonu',
    ],
    ambientWeatherLabels: [
      '31°C • Kızıl Kanyon Meltemi',
      '17°C • Berrak Yıldız Gözlemi Gecesi',
      '38°C • Altın Kumul Güneşi',
      '23°C • Bereketli Çöl Yağmuru',
    ],
    directionZones: [
      DirectionZone(
        startAngle: 335,
        endAngle: 18,
        label: 'KIZIL KANYON KAYALIKLARI & SICAK HAVA BALONLARI',
      ),
      DirectionZone(
        startAngle: 18,
        endAngle: 52,
        label: 'AHŞAP KANYON KÖPRÜSÜ & VAHŞİ BATI BUHARLI TRENİ',
      ),
      DirectionZone(
        startAngle: 52,
        endAngle: 98,
        label: 'KANYON ŞELALESİ, ZÜMRÜT VAHA GÖLÜ & DEVE KERVANI',
      ),
      DirectionZone(
        startAngle: 98,
        endAngle: 152,
        label: 'KAYAYA OYULMUŞ PETRA TAPINAĞI, KERVANSARAY & HALI ÇARŞISI',
      ),
      DirectionZone(
        startAngle: 152,
        endAngle: 195,
        label: 'BEDEVİ ÇADIRI, ÇÖL ATEŞİ, UD MÜZİSYENİ & ÇÖL TİLKİSİ',
      ),
      DirectionZone(
        startAngle: 195,
        endAngle: 240,
        label: 'BASAMAKLI ANTİK PİRAMİT, DİKİLİTAŞLAR & YEL DEĞİRMENİ',
      ),
      DirectionZone(
        startAngle: 240,
        endAngle: 335,
        label: 'ÇÖL GÖZLEMEVİ KUBBESİ, TELESKOPLAR & KAKTÜS VADİSİ',
      ),
    ],
    defaultDirectionLabel: 'KIZIL KANYON, BALONLAR & VAHŞİ BATI TRENİ',
  ),

  // 6. COLOGNE CHRISTMAS TREE SIMULATOR
  ZenVerseModel(
    id: 'christmas_tree',
    title: 'Christmas Tree Simulator',
    subtitle: 'Köln Katedrali, Noel Pazarı & Buz Pisti',
    description:
        'Almanya\'nın tarihi Köln (Cologne) şehrinin karlı Roncalliplatz meydanında, binlerce sıcak ışık, cam süsler ve hediye paketleriyle donatılmış dev bir Yılbaşı Ağacısın. Karşında gökyüzüne uzanan ikiz kuleli Gotik Köln Katedrali (Kölner Dom) ve yıldızlı ışık çadırı altında şarkı söyleyen koro; etrafında Heumarkt açık hava buz pistinde kayan insanlar, ahşap Noel pazarı kulübeleri, sıcak şarap (Glühwein) ve Bratwurst yiyen kalabalık, dönen ahşap Noel piramidi, dev dönme dolap ve Ren Nehri üzerindeki Hohenzollern Köprüsü...',
    environmentName: 'Köln (Cologne) • 360° Katedral, Noel Pazarı & Buz Pisti',
    displayLocationName: 'KÖLN NOEL MEYDANI',
    actionButtonLabel: 'SİMÜLASYONA BAŞLA (YILBAŞI AĞACI OL)',
    quote:
        '"Kışın en karanlık gecesinde bile, kalbindeki binlerce sıcak ışıkla bütün bir şehri ısıtabilirsin."',
    isUnlocked: true,
    themeColors: [
      Color(0xFFC62828),
      Color(0xFFFFB300),
      Color(0xFF1B5E20),
    ],
    icon: Icons.celebration_rounded,
    features: [
      '360° İkiz Kuleli Gotik Köln Katedrali (Kölner Dom) & Yıldızlı Işık Çadırı',
      'Heumarkt Açık Hava Buz Pisti, Buzda Kayan 7 Patenci & Dağ Şalesi',
      'Köln Altstadt Evleri, Ahşap Noel Pazarı Kulübeleri & Dönen Noel Piramidi',
      'Fıçı Masalarda Sıcak Glühwein İçen, Bratwurst Yiyen & Gezen İnsanlar',
      'Işıklı Dev Dönme Dolap (Riesenrad), Kömürde Sosis Izgarası & Atlıkarınca',
      'Ren Nehri, Aşk Kilitli Hohenzollern Köprüsü, Tren & Noel Gezi Gemisi',
      'Gece Modunda Ay Önünden Geçen Noel Baba & Ren Geyiği Kızağı Silüeti',
      '5 Yılbaşı Ağacı Stili (Realistic, Noel Babalı, Glühwein Fiesta, Kraliyet, Lo-Fi)',
      '4 Atmosfer Modu, 5 Kamera Dönüş Şekli & Sinematik Display Modu',
    ],
    scenicPoints: [
      ScenicPoint(label: '⛪ Köln Katedrali & Meydan (0°)', angle: 0.0),
      ScenicPoint(label: '⛸️ Heumarkt Buz Pisti (72°)', angle: 72.0),
      ScenicPoint(label: '🎄 Noel Piramidi & Pazar (128°)', angle: 128.0),
      ScenicPoint(label: '🎡 Dönme Dolap & Izgara (176°)', angle: 176.0),
      ScenicPoint(label: '🌉 Ren Nehri & Köprü (252°)', angle: 252.0),
    ],
    thoughts: [
      'Şu an Köln\'ün kalbinde, Kölner Dom\'un hemen önünde parıldayan dev bir Yılbaşı Ağacısın.',
      'İkiz Gotik katedral kuleleri ve gümüş çatısı kış akşamında büyüleyici bir ışıkla parlıyor.',
      'Başının üzerindeki yıldızlı ışık çadırı (Sternenzelt) tüm Roncalliplatz meydanını sarıyor.',
      'Heumarkt açık hava buz pistinde (Heinzels Wintermärchen) insanlar ışıklı köprünün altından kayıyor.',
      'Kırmızı çatılı ahşap Noel pazarı kulübelerinden tarçın, kavrulmuş badem ve sıcak Glühwein kokusu yükseliyor.',
      'Dört katlı dev ahşap Noel piramidinin (Weihnachtspyramide) pervanesi mumların sıcaklığıyla dönüyor.',
      'Altındaki sekizgen kırmızı çatılı ahşap pavyonun (Baum-Pavillon) yıldızları meydana neşe saçıyor.',
      'Kömür ateşinde sallanan ızgarada (Schwenkgrill) pişen Bratwurst sosislerin dumanı göğe karışıyor.',
      'Işıklı dev dönme dolabın kabinleri tarihi Köln Altstadt çatılarını yukarıdan izliyor.',
      'Ren Nehri üzerindeki üç kemerli Hohenzollern Köprüsü\'nden beyaz ICE hızlı treni süzülerek geçiyor.',
      'Köprü korkuluklarındaki binlerce renkli aşk kilidi nehir ışıklarında parıldıyor.',
      'Gece modunda dolunayın önünden Noel Baba ve ren geyiklerinin kızağı sessizce süzülüyor.',
      'Dibindeki rengarenk kurdeleli hediye paketleri ve Fındıkkıran askeri seninle birlikte nöbette.',
      'Lo-Fi modda kulaklığın ve binlerce sıcak altın ışığınla meydanın en huzurlu köşesisin.',
      'İnsanlar yanından geçerken başlarını kaldırıp tependeki parlayan Beytlehem yıldızına gülümsüyor.',
      'Kar taneleri 50.000 sarı ışığının arasından süzülerek Arnavut kaldırımlarına konuyor.',
      'Hiçbir yere yetişmen gerekmiyor. Sen bu kış masalının ve Köln\'ün en sıcak merkezisin.',
      'Ren Nehri\'ndeki ışıklı gezi gemisi Groß St. Martin kulesinin önünden ağır ağır ilerliyor.',
      'Yeni bir yıl yaklaşırken herkesin dilekleri ve tebessümleri senin dallarında buluşuyor.',
      'Sadece parılda ve 360° yaşayan bu gerçekçi Köln Noel pazarının senin etrafında dönmesini izle.',
    ],
    styleLabels: [
      '🎄 Realistic',
      '🎅 Noel Baba',
      '🥨 Glühwein Fiesta',
      '👑 Kraliyet',
      '🎧 Lo-Fi Kış',
    ],
    atmosphereLabels: [
      '🌇 Noel Alacakaranlığı',
      '🌙 Yılbaşı Gecesi',
      '☀️ Kış Güneşi',
      '🌨️ Yoğun Kar Yağışı',
    ],
    ambientWeatherLabels: [
      '-1°C • Tarçın & Kar Meltemi',
      '-4°C • Işıltılı Yılbaşı Gecesi',
      '3°C • Berrak Köln Kış Güneşi',
      '-6°C • Masalsı Noel Kar Tipisi',
    ],
    directionZones: [
      DirectionZone(
        startAngle: 330,
        endAngle: 42,
        label: 'KÖLN KATEDRALİ (KÖLNER DOM), MUSICAL DOME & RONCALLIPLATZ',
      ),
      DirectionZone(
        startAngle: 42,
        endAngle: 98,
        label: 'HEUMARKT AÇIK HAVA BUZ PİSTİ, IŞIKLI KÖPRÜ & ALMHÜTTE',
      ),
      DirectionZone(
        startAngle: 98,
        endAngle: 156,
        label: 'DÖNEN NOEL PİRAMİDİ, ALTSTADT EVLERİ & PAZAR SOKAKLARI',
      ),
      DirectionZone(
        startAngle: 156,
        endAngle: 215,
        label: 'DEV DÖNME DOLAP (RIESENRAD), SCHWENKGRILL & ATLIKARINCA',
      ),
      DirectionZone(
        startAngle: 215,
        endAngle: 330,
        label: 'REN NEHRİ, HOHENZOLLERN KÖPRÜSÜ, ICE TRENİ & ST. MARTİN',
      ),
    ],
    defaultDirectionLabel: 'KÖLN KATEDRALİ (KÖLNER DOM) & RONCALLIPLATZ MEYDANI',
  ),
];
