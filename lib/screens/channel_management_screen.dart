import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';
import 'main_screen.dart';
import 'recommendation_settings_screen.dart';

class ChannelManagementScreen extends StatefulWidget {
  final String apiKey;

  const ChannelManagementScreen({Key? key, required this.apiKey}) : super(key: key);

  @override
  State<ChannelManagementScreen> createState() => _ChannelManagementScreenState();
}

class _ChannelManagementScreenState extends State<ChannelManagementScreen> {
  late YouTubeService _youtubeService;
  final _searchController = TextEditingController();
  List<Channel> _searchResults = [];
  List<Channel> _popularChannels = [];
  List<Channel> _subscribedChannels = [];
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isLoadingPopular = true;
  bool _hasSearched = false;

  // 인기 한국 키즈 채널들
  final List<String> _popularChannelNames = [
    '뽀로로',
    '핑크퐁',
    '타요',
    '코코몽',
    '베이비버스',
    '티디키즈',
    '똑똑키즈',
    '키클',
    '키즈폰트',
    '슈퍼조조',
    '바다탐험대 옥토넛',
    '구구단 송',
    '토마스와 친구들',
    '페파피그',
    'CoComelon',
  ];

  @override
  void initState() {
    super.initState();
    _youtubeService = YouTubeService(apiKey: widget.apiKey);
    _loadSubscribedChannels();
    _loadPopularChannels();
  }

  Future<void> _loadSubscribedChannels() async {
    final channels = await StorageService.getChannels();
    setState(() {
      _subscribedChannels = channels;
      _isLoading = false;
    });
  }

  Future<void> _loadPopularChannels() async {
    setState(() {
      _isLoadingPopular = true;
    });

    List<Channel> channels = [];
    
    // 각 인기 채널명으로 검색해서 채널 정보 가져오기
    for (String channelName in _popularChannelNames.take(10)) {
      try {
        final searchResults = await _youtubeService.searchChannels(channelName);
        if (searchResults.isNotEmpty) {
          // 구독자 수 1만명 이상인 채널만 추가
          final filteredChannels = searchResults.where((channel) {
            final subscriberCount = _parseSubscriberCount(channel.subscriberCount);
            return subscriberCount >= 10000;
          }).toList();
          
          if (filteredChannels.isNotEmpty) {
            channels.add(filteredChannels.first);
          }
        }
        // API 호출 제한을 피하기 위한 지연
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('Error loading channel $channelName: $e');
      }
    }

    setState(() {
      _popularChannels = channels;
      _isLoadingPopular = false;
    });
  }

  Future<void> _searchChannels() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _hasSearched = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final results = await _youtubeService.searchChannels(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _addChannel(Channel channel) async {
    await StorageService.addChannel(channel);
    await _loadSubscribedChannels();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${channel.title} 채널이 추가되었습니다')),
    );
  }

  Future<void> _removeChannel(String channelId) async {
    await StorageService.removeChannel(channelId);
    await _loadSubscribedChannels();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('채널이 삭제되었습니다')),
    );
  }

  void _showUnsubscribeDialog(Channel channel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('구독 취소'),
          content: Text('${channel.title} 채널 구독을 취소하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeChannel(channel.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${channel.title} 구독을 취소했습니다')),
                );
              },
              child: const Text('구독 취소', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeSetup() async {
    if (_subscribedChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 이상의 채널을 추가해주세요')),
      );
      return;
    }

    await StorageService.setSetupComplete(true);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainScreen(apiKey: widget.apiKey)),
    );
  }

  // 구독자 수 문자열을 숫자로 변환
  int _parseSubscriberCount(String subscriberCountStr) {
    if (subscriberCountStr.isEmpty || subscriberCountStr == '0') {
      return 0;
    }

    String cleanStr = subscriberCountStr.toLowerCase().replaceAll(',', '');
    double multiplier = 1;
    
    if (cleanStr.contains('k')) {
      multiplier = 1000;
      cleanStr = cleanStr.replaceAll('k', '');
    } else if (cleanStr.contains('m')) {
      multiplier = 1000000;
      cleanStr = cleanStr.replaceAll('m', '');
    }

    try {
      double value = double.parse(cleanStr);
      return (value * multiplier).round();
    } catch (e) {
      print('Error parsing subscriber count: $subscriberCountStr');
      return 0;
    }
  }

  Widget _buildChannelAvatar(Channel channel) {
    if (channel.thumbnail.isEmpty) {
      // 썸네일이 없는 경우 이니셜로 대체
      return CircleAvatar(
        backgroundColor: Colors.red.shade400,
        child: Text(
          channel.title.isNotEmpty ? channel.title.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      backgroundImage: CachedNetworkImageProvider(channel.thumbnail),
      onBackgroundImageError: (exception, stackTrace) {
        print('Error loading thumbnail for ${channel.title}: $exception');
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채널 관리'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecommendationSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.tune),
            tooltip: '추천 설정',
          ),
          TextButton(
            onPressed: _completeSetup,
            child: const Text('완료', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '채널 검색...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _searchChannels(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _searchChannels,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('검색', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  '구독 채널 (${_subscribedChannels.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (_subscribedChannels.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('구독한 채널이 없습니다\n채널을 검색하여 추가해주세요', textAlign: TextAlign.center),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: _subscribedChannels.length,
                itemBuilder: (context, index) {
                  final channel = _subscribedChannels[index];
                  return Card(
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: _buildChannelAvatar(channel),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              channel.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () => _showUnsubscribeDialog(channel),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.remove_circle, 
                                color: Colors.red, 
                                size: 16
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          const Divider(),
          
          // 검색 상태 또는 결과 표시
          if (_isSearching)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasSearched && _searchResults.isNotEmpty)
            // 검색 결과 표시
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '검색 결과 (${_searchResults.length}개)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final channel = _searchResults[index];
                        final isSubscribed = _subscribedChannels.any((c) => c.id == channel.id);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: _buildChannelAvatar(channel),
                            title: Text(
                              channel.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Text(
                              '구독자 ${channel.subscriberCount}명',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing: isSubscribed
                                ? IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () => _showUnsubscribeDialog(channel),
                                    tooltip: '구독 취소',
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.red),
                                    onPressed: () => _addChannel(channel),
                                    tooltip: '구독하기',
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else if (_hasSearched && _searchResults.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('검색 결과가 없습니다', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (_isLoadingPopular)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('인기 채널을 불러오는 중...'),
                  ],
                ),
              ),
            )
          else
            // 인기 채널 표시 (기본)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.shade50,
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          '인기 키즈 채널',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_popularChannels.length}개',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _popularChannels.isEmpty
                        ? const Center(
                            child: Text('인기 채널을 불러올 수 없습니다'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _popularChannels.length,
                            itemBuilder: (context, index) {
                              final channel = _popularChannels[index];
                              final isSubscribed = _subscribedChannels.any((c) => c.id == channel.id);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: _buildChannelAvatar(channel),
                                  title: Text(
                                    channel.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  subtitle: Text(
                                    '구독자 ${channel.subscriberCount}명',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  trailing: isSubscribed
                                      ? IconButton(
                                          icon: const Icon(Icons.check_circle, color: Colors.green),
                                          onPressed: () => _showUnsubscribeDialog(channel),
                                          tooltip: '구독 취소',
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.add_circle, color: Colors.red),
                                          onPressed: () => _addChannel(channel),
                                          tooltip: '구독하기',
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}