import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/video.dart';
import '../providers/video_provider.dart';
import '../providers/channel_provider.dart';
import '../providers/recommendation_provider.dart';
import '../core/service_locator.dart';
import '../core/background_refresh_manager.dart';
import '../core/cache_analytics.dart';
import 'pin_verification_screen.dart';
import 'pin_setup_screen.dart';
import 'channel_management_screen.dart';
import '../services/storage_service.dart';
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late VideoProvider _videoProvider;
  late ChannelProvider _channelProvider;
  late RecommendationProvider _recommendationProvider;
  late BackgroundRefreshManager _backgroundRefreshManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeProviders();
  }
  
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 백그라운드 새로고침 비활성화 (API 사용량 절약)
    // if (state == AppLifecycleState.resumed) {
    //   _backgroundRefreshManager.startBackgroundRefresh();
    // } else if (state == AppLifecycleState.paused) {
    //   _backgroundRefreshManager.stopBackgroundRefresh();
    // }
  }

  void _initializeProviders() {
    // Initialize services with API key
    initializeWithApiKey(widget.apiKey);
    
    // Create providers with dependency injection
    _channelProvider = ProviderFactory.createChannelProvider();
    _videoProvider = ProviderFactory.createVideoProvider();
    _recommendationProvider = ProviderFactory.createRecommendationProvider();
    
    // Set up provider relationships for reactive updates
    _videoProvider.setChannelProvider(_channelProvider);
    
    // Get background refresh manager
    _backgroundRefreshManager = getService<BackgroundRefreshManager>();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load subscribed channels and videos
      await _channelProvider.loadSubscribedChannels();
      await _videoProvider.loadVideos();
      await _recommendationProvider.loadWeights();
      
      // 백그라운드 새로고침 비활성화 (API 사용량 절약)
      // _backgroundRefreshManager.startBackgroundRefresh();
      
      // Clean old analytics data periodically
      await CacheAnalytics.cleanOldAnalytics();
    });
  }

  void _openVideo(Video video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(video: video),
      ),
    );
  }

  void _openParentSettings() async {
    final hasPin = await StorageService.hasPin();
    
    if (!mounted) return;
    
    if (hasPin) {
      // PIN이 설정되어 있으면 인증 화면으로
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
    } else {
      // PIN이 설정되어 있지 않으면 PIN 설정 화면으로
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinSetupScreen(apiKey: widget.apiKey),
        ),
      );
    }
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _videoProvider),
        ChangeNotifierProvider.value(value: _channelProvider),
        ChangeNotifierProvider.value(value: _recommendationProvider),
      ],
      child: Scaffold(
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
        drawer: _buildDrawer(),
        body: RefreshIndicator(
          onRefresh: () => _videoProvider.refreshVideos(),
          child: _buildBodyWithSelectors(),
        ),
      ),
    );
  }

  Widget _buildBody(VideoProvider videoProvider) {
    if (videoProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (videoProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              videoProvider.error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => videoProvider.loadVideos(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (!videoProvider.hasChannels) {
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

    if (!videoProvider.hasVideos) {
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

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 14,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: videoProvider.videos.length,
      itemBuilder: (context, index) {
        final video = videoProvider.videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(Video video) {
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
                      memCacheWidth: 400,
                      memCacheHeight: 300,
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
  }

  Widget _buildDrawer() {
    return Drawer(
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
            onTap: () => Navigator.pop(context),
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
              _videoProvider.refreshVideos();
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
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('PIN 리셋 (디버깅)'),
            onTap: () async {
              Navigator.pop(context);
              await StorageService.clearPin();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN이 리셋되었습니다. 설정 버튼을 다시 눌러주세요.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Optimized body builder using Selector pattern for performance
  Widget _buildBodyWithSelectors() {
    return Column(
      children: [
        // Error state selector
        Selector<VideoProvider, String?>(
          selector: (context, provider) => provider.error,
          builder: (context, error, child) {
            if (error != null) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _videoProvider.loadVideos(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        
        // Main content selector
        Expanded(
          child: Selector2<VideoProvider, ChannelProvider, ({bool isLoading, bool hasVideos, bool hasChannels})>(
            selector: (context, videoProvider, channelProvider) => (
              isLoading: videoProvider.isLoading,
              hasVideos: videoProvider.hasVideos,
              hasChannels: channelProvider.hasSubscribedChannels,
            ),
            builder: (context, state, child) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!state.hasChannels) {
                return _buildNoChannelsState();
              }

              if (!state.hasVideos) {
                return _buildNoVideosState();
              }

              return _buildVideoGrid();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoChannelsState() {
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

  Widget _buildNoVideosState() {
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

  Widget _buildVideoGrid() {
    return Selector<VideoProvider, List<Video>>(
      selector: (context, provider) => provider.videos,
      builder: (context, videos, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 16 / 14,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            return _buildVideoCard(videos[index]);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundRefreshManager.dispose();
    _videoProvider.dispose();
    _channelProvider.dispose();
    _recommendationProvider.dispose();
    super.dispose();
  }
}