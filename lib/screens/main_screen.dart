import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video.dart';
import '../models/channel.dart';
import '../models/recommendation_weights.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';
import 'pin_verification_screen.dart';
import 'channel_management_screen.dart';
import 'video_player_screen.dart';
import 'all_channels_screen.dart';
import 'recommendation_settings_screen.dart';
import 'api_settings_screen.dart';

class MainScreen extends StatefulWidget {
  final String apiKey;

  const MainScreen({Key? key, required this.apiKey}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late YouTubeService _youtubeService;
  List<Video> _videos = [];
  List<Channel> _channels = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMoreVideos = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _youtubeService = YouTubeService(apiKey: widget.apiKey);
    _loadVideos();
    
    // 스크롤 리스너 추가
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // 스크롤이 끝에서 200px 이내에 도달하면 더 많은 비디오 로드
      _loadMoreVideos();
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _hasMoreVideos = true;
    });

    _channels = await StorageService.getChannels();
    
    if (_channels.isNotEmpty) {
      // 추천 가중치를 가져와서 가중치 기반 추천 사용
      final weights = await StorageService.getRecommendationWeights();
      final videos = await _youtubeService.getWeightedRecommendedVideos(_channels, weights);
      
      print('로드된 비디오 개수: ${videos.length}'); // 디버깅용 로그
      
      setState(() {
        _videos = videos;
        _isLoading = false;
        _isRefreshing = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !_hasMoreVideos || _channels.isEmpty) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      // 추천 가중치를 가져와서 가중치 기반 추천 사용 - 추가 10개 로드
      final weights = await StorageService.getRecommendationWeights();
      final newVideos = await _youtubeService.getWeightedRecommendedVideos(_channels, weights);
      
      // 중복 제거를 위해 기존 비디오 ID 세트 생성
      final existingVideoIds = _videos.map((v) => v.id).toSet();
      final uniqueNewVideos = newVideos.where((v) => !existingVideoIds.contains(v.id)).toList();
      
      if (uniqueNewVideos.isNotEmpty) {
        // 새로운 비디오들을 섞어서 다양성 확보
        uniqueNewVideos.shuffle();
        
        setState(() {
          _videos.addAll(uniqueNewVideos);
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _hasMoreVideos = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      print('더 많은 비디오 로드 중 오류: $e');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
      _videos.clear(); // 기존 비디오 목록 클리어
      _hasMoreVideos = true;
    });
    await _loadVideos();
  }

  void _openVideo(Video video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(video: video),
      ),
    );
  }

  void _openParentSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinVerificationScreen(
          onSuccess: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChannelManagementScreen(apiKey: widget.apiKey),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatPublishedTime(String publishedAt) {
    try {
      final dateTime = DateTime.parse(publishedAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}년 전';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}개월 전';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}일 전';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}시간 전';
      } else {
        return '${difference.inMinutes}분 전';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KidsTube'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openParentSettings,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.red,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'KidsTube',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('홈'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('채널검색'),
              onTap: () {
                Navigator.pop(context);
                _openParentSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('전체 채널'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllChannelsScreen(apiKey: widget.apiKey),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('새로고침'),
              onTap: () {
                Navigator.pop(context);
                _refresh();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('추천 설정'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PinVerificationScreen(
                      onSuccess: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecommendationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('API 설정'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PinVerificationScreen(
                      onSuccess: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ApiSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('부모 설정'),
              onTap: () {
                Navigator.pop(context);
                _openParentSettings();
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.subscriptions_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              '구독한 채널이 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openParentSettings,
              icon: const Icon(Icons.add),
              label: const Text('채널 추가하기'),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              '표시할 영상이 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 16 / 14,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final video = _videos[index];
                
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () => _openVideo(video),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                child: CachedNetworkImage(
                                  imageUrl: video.thumbnail,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.error),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatPublishedTime(video.publishedAt),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                video.channelTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _videos.length,
            ),
          ),
        ),
        // 로딩 인디케이터 추가
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        // 더 이상 로드할 비디오가 없을 때 메시지
        if (!_hasMoreVideos && _videos.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '모든 추천 영상을 확인했습니다',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}