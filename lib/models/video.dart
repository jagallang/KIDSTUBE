class Video {
  final String id;
  final String title;
  final String thumbnail;
  final String channelTitle;
  final String publishedAt;

  Video({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.channelTitle,
    required this.publishedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    final highThumbnail = thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {};

    String videoId = '';
    if (json['id'] is String) {
      videoId = json['id'];
    } else if (json['id'] is Map) {
      videoId = json['id']['videoId'] ?? '';
    }

    return Video(
      id: videoId,
      title: snippet['title'] ?? '',
      thumbnail: highThumbnail['url'] ?? '',
      channelTitle: snippet['channelTitle'] ?? '',
      publishedAt: snippet['publishedAt'] ?? '',
    );
  }

  // playlistItems.list API 응답을 위한 생성자
  factory Video.fromPlaylistItem(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    final highThumbnail = thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'] ?? {};
    
    // playlistItems에서는 snippet.resourceId.videoId에 비디오 ID가 있습니다
    String videoId = '';
    if (snippet['resourceId'] != null) {
      videoId = snippet['resourceId']['videoId'] ?? '';
    }

    return Video(
      id: videoId,
      title: snippet['title'] ?? '',
      thumbnail: highThumbnail['url'] ?? '',
      channelTitle: snippet['channelTitle'] ?? '',
      publishedAt: snippet['publishedAt'] ?? '',
    );
  }

  // 캐시를 위한 JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'channelTitle': channelTitle,
      'publishedAt': publishedAt,
    };
  }
}