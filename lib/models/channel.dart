class Channel {
  final String id;
  final String title;
  final String thumbnail;
  final String subscriberCount;
  final String uploadsPlaylistId;
  final String category;

  Channel({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.subscriberCount,
    required this.uploadsPlaylistId,
    this.category = '랜덤',
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final statistics = json['statistics'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    final highThumbnail = thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {};

    // 채널 ID 추출
    String channelId = '';
    if (json['id'] is String) {
      channelId = json['id'];
    } else if (json['id'] is Map) {
      channelId = json['id']['channelId'] ?? '';
    }

    // 구독자 수 포맷팅
    String subscriberCount = '0';
    if (statistics['subscriberCount'] != null) {
      final count = int.tryParse(statistics['subscriberCount'].toString()) ?? 0;
      if (count >= 1000000) {
        subscriberCount = '${(count / 1000000).toStringAsFixed(1)}M';
      } else if (count >= 1000) {
        subscriberCount = '${(count / 1000).toStringAsFixed(1)}K';
      } else {
        subscriberCount = count.toString();
      }
    }

    // 업로드 재생목록 ID 추출 (채널ID의 UC를 UU로 바꾸거나, contentDetails에서 가져오기)
    String uploadsPlaylistId = '';
    if (json['contentDetails'] != null && json['contentDetails']['relatedPlaylists'] != null) {
      uploadsPlaylistId = json['contentDetails']['relatedPlaylists']['uploads'] ?? '';
    } else if (channelId.startsWith('UC')) {
      // UC로 시작하는 채널 ID의 경우 UU로 바꾸면 업로드 재생목록 ID가 됩니다
      uploadsPlaylistId = channelId.replaceFirst('UC', 'UU');
    }

    // 채널 이름 기반 카테고리 자동 분류
    final title = snippet['title'] ?? snippet['channelTitle'] ?? '';
    String category = _categorizeChannel(title);

    return Channel(
      id: channelId,
      title: title,
      thumbnail: highThumbnail['url'] ?? '',
      subscriberCount: subscriberCount,
      uploadsPlaylistId: uploadsPlaylistId,
      category: category,
    );
  }

  static String _categorizeChannel(String title) {
    final lowerTitle = title.toLowerCase();
    
    // 한글 관련 키워드
    if (lowerTitle.contains('한글') || lowerTitle.contains('국어') || 
        lowerTitle.contains('글자') || lowerTitle.contains('읽기') || 
        lowerTitle.contains('쓰기')) {
      return '한글';
    }
    
    // 키즈 관련 키워드
    if (lowerTitle.contains('뽀로로') || lowerTitle.contains('핑크퐁') || 
        lowerTitle.contains('타요') || lowerTitle.contains('코코몽') ||
        lowerTitle.contains('키즈') || lowerTitle.contains('어린이')) {
      return '키즈';
    }
    
    // 만들기 관련 키워드
    if (lowerTitle.contains('만들기') || lowerTitle.contains('공작') || 
        lowerTitle.contains('종이접기') || lowerTitle.contains('diy') ||
        lowerTitle.contains('craft')) {
      return '만들기';
    }
    
    // 게임 관련 키워드
    if (lowerTitle.contains('게임') || lowerTitle.contains('놀이') || 
        lowerTitle.contains('퍼즐') || lowerTitle.contains('보드게임') ||
        lowerTitle.contains('play')) {
      return '게임';
    }
    
    // 영어 관련 키워드
    if (lowerTitle.contains('영어') || lowerTitle.contains('abc') || 
        lowerTitle.contains('파닉스') || lowerTitle.contains('영단어') ||
        lowerTitle.contains('english')) {
      return '영어';
    }
    
    // 과학 관련 키워드
    if (lowerTitle.contains('과학') || lowerTitle.contains('실험') || 
        lowerTitle.contains('자연') || lowerTitle.contains('동물') || 
        lowerTitle.contains('우주') || lowerTitle.contains('science')) {
      return '과학';
    }
    
    // 미술 관련 키워드
    if (lowerTitle.contains('미술') || lowerTitle.contains('그림') || 
        lowerTitle.contains('색칠') || lowerTitle.contains('창작') ||
        lowerTitle.contains('art')) {
      return '미술';
    }
    
    // 음악 관련 키워드
    if (lowerTitle.contains('음악') || lowerTitle.contains('노래') || 
        lowerTitle.contains('동요') || lowerTitle.contains('악기') ||
        lowerTitle.contains('music')) {
      return '음악';
    }
    
    // 기본값은 랜덤
    return '랜덤';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnail': thumbnail,
        'subscriberCount': subscriberCount,
        'uploadsPlaylistId': uploadsPlaylistId,
        'category': category,
      };
}