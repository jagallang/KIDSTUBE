class Channel {
  final String id;
  final String title;
  final String thumbnail;
  final String subscriberCount;
  final String uploadsPlaylistId;

  Channel({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.subscriberCount,
    required this.uploadsPlaylistId,
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

    return Channel(
      id: channelId,
      title: snippet['title'] ?? snippet['channelTitle'] ?? '',
      thumbnail: highThumbnail['url'] ?? '',
      subscriberCount: subscriberCount,
      uploadsPlaylistId: uploadsPlaylistId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnail': thumbnail,
        'subscriberCount': subscriberCount,
        'uploadsPlaylistId': uploadsPlaylistId,
      };
}