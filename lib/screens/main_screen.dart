import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/video.dart';
import '../providers/video_provider.dart';
import '../providers/channel_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      final channelProvider = Provider.of<ChannelProvider>(context, listen: false);
      
      videoProvider.setApiKey(widget.apiKey);
      channelProvider.setApiKey(widget.apiKey);
      videoProvider.loadVideos();
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
      drawer: _buildDrawer(),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          return RefreshIndicator(
            onRefresh: () => videoProvider.refreshVideos(),
            child: _buildBody(videoProvider),
          );
        },
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
              Provider.of<VideoProvider>(context, listen: false).refreshVideos();
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
    );
  }
}