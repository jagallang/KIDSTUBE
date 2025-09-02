class RecommendationWeights {
  final int korean;  // 한글
  final int kids;    // 키즈
  final int making;  // 만들기
  final int games;   // 게임
  final int english; // 영어
  final int science; // 과학
  final int art;     // 미술
  final int music;   // 음악
  final int random;  // 랜덤 (기타)

  const RecommendationWeights({
    this.korean = 3,
    this.kids = 3,
    this.making = 2,
    this.games = 1,
    this.english = 2,
    this.science = 1,
    this.art = 1,
    this.music = 1,
    this.random = 1,
  });

  RecommendationWeights copyWith({
    int? korean,
    int? kids,
    int? making,
    int? games,
    int? english,
    int? science,
    int? art,
    int? music,
    int? random,
  }) {
    return RecommendationWeights(
      korean: korean ?? this.korean,
      kids: kids ?? this.kids,
      making: making ?? this.making,
      games: games ?? this.games,
      english: english ?? this.english,
      science: science ?? this.science,
      art: art ?? this.art,
      music: music ?? this.music,
      random: random ?? this.random,
    );
  }

  Map<String, dynamic> toJson() => {
        'korean': korean,
        'kids': kids,
        'making': making,
        'games': games,
        'english': english,
        'science': science,
        'art': art,
        'music': music,
        'random': random,
      };

  factory RecommendationWeights.fromJson(Map<String, dynamic> json) {
    return RecommendationWeights(
      korean: json['korean'] ?? 3,
      kids: json['kids'] ?? 3,
      making: json['making'] ?? 2,
      games: json['games'] ?? 1,
      english: json['english'] ?? 2,
      science: json['science'] ?? 1,
      art: json['art'] ?? 1,
      music: json['music'] ?? 1,
      random: json['random'] ?? 1,
    );
  }

  // 총 가중치 합계
  int get total => korean + kids + making + games + english + science + art + music + random;

  // 카테고리별 가중치 비율 계산
  Map<String, double> get ratios {
    if (total == 0) return {};
    return {
      '한글': korean / total,
      '키즈': kids / total,
      '만들기': making / total,
      '게임': games / total,
      '영어': english / total,
      '과학': science / total,
      '미술': art / total,
      '음악': music / total,
      '랜덤': random / total,
    };
  }

  // 카테고리별 영상 개수 계산 (총 20개 영상 기준)
  Map<String, int> getVideoCountsForTotal(int totalVideos) {
    if (total == 0) return {};
    
    return {
      '한글': (totalVideos * korean / total).round(),
      '키즈': (totalVideos * kids / total).round(), 
      '만들기': (totalVideos * making / total).round(),
      '게임': (totalVideos * games / total).round(),
      '영어': (totalVideos * english / total).round(),
      '과학': (totalVideos * science / total).round(),
      '미술': (totalVideos * art / total).round(),
      '음악': (totalVideos * music / total).round(),
      '랜덤': (totalVideos * random / total).round(),
    };
  }
}