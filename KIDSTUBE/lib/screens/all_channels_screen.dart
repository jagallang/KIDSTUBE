import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../services/storage_service.dart';

class AllChannelsScreen extends StatefulWidget {
  final String apiKey;

  const AllChannelsScreen({super.key, required this.apiKey});

  @override
  State<AllChannelsScreen> createState() => _AllChannelsScreenState();
}

class _AllChannelsScreenState extends State<AllChannelsScreen> {
  List<Channel> _subscribedChannels = [];
  List<Channel> _filteredChannels = [];
  bool _isLoading = true;
  
  String _selectedCategory = '전체';
  final List<String> _categories = ['전체', '키즈', '한글', '만들기', '게임', '영어', '과학', '미술', '음악'];
  
  // 채널 이름 키워드로 카테고리 분류
  final Map<String, List<String>> _categoryKeywords = {
    '키즈': ['뽀로로', '핑크퐁', '타요', '코코몽', '베이비버스', '키즈', '아기', '어린이', '유아', '키드'],
    '한글': ['한글', '한국어', '국어', '글자', '받침', '자음', '모음', '읽기', '쓰기'],
    '만들기': ['만들기', '공작', '종이접기', '그리기', '창작', '손놀이', 'DIY', '만든다'],
    '게임': ['게임', '놀이', '퍼즐', '숨바꼭질', '술래잡기', '보드게임', '카드게임', '놀이터'],
    '영어': ['영어', 'English', 'ABC', 'Alphabet', '알파벳', 'phonics', '파닉스', '영단어', '영어동요'],
    '과학': ['과학', '실험', 'science', '탐구', '관찰', '자연', '동물', '식물', '우주', '지구', '발명'],
    '미술': ['미술', '그림', '그리기', '색칠', '만들기', '조형', 'art', '디자인', '창작', '컬러링'],
    '음악': ['음악', '노래', '동요', '리듬', '악기', 'music', '피아노', '기타', '합창', '멜로디']
  };

  @override
  void initState() {
    super.initState();
    _loadSubscribedChannels();
  }

  Future<void> _loadSubscribedChannels() async {
    final channels = await StorageService.getChannels();
    if (mounted) {
      setState(() {
        _subscribedChannels = channels;
        _filteredChannels = channels;
        _isLoading = false;
      });
    }
  }

  void _filterChannelsByCategory(String category) {
    if (mounted) {
      setState(() {
        _selectedCategory = category;
        
        if (category == '전체') {
          _filteredChannels = _subscribedChannels;
        } else {
          _filteredChannels = _subscribedChannels.where((channel) {
            return _belongsToCategory(channel, category);
          }).toList();
        }
      });
    }
  }
  
  bool _belongsToCategory(Channel channel, String category) {
    final keywords = _categoryKeywords[category] ?? [];
    final channelTitle = channel.title.toLowerCase();
    
    return keywords.any((keyword) => channelTitle.contains(keyword.toLowerCase()));
  }


  Future<void> _removeChannel(String channelId) async {
    await StorageService.removeChannel(channelId);
    await _loadSubscribedChannels();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채널 구독을 취소했습니다')),
      );
    }
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
              },
              child: const Text('구독 취소', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구독 채널'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 카테고리 필터 탭
          Container(
            height: 50,
            color: Colors.grey.shade100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      _filterChannelsByCategory(category);
                    },
                    selectedColor: Colors.red.shade100,
                    checkmarkColor: Colors.red,
                  ),
                );
              },
            ),
          ),

          // 채널 리스트 헤더
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(
                  _selectedCategory == '전체' ? Icons.subscriptions : _getCategoryIcon(_selectedCategory),
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory == '전체' 
                      ? '전체 구독 채널 (${_filteredChannels.length})'
                      : '$_selectedCategory 채널 (${_filteredChannels.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 채널 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _subscribedChannels.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              '구독한 채널이 없습니다',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '채널검색에서 채널을 추가해보세요',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : _filteredChannels.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  '$_selectedCategory 카테고리에\n해당하는 채널이 없습니다',
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredChannels.length,
                            itemBuilder: (context, index) {
                              final channel = _filteredChannels[index];
                              
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
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _showUnsubscribeDialog(channel),
                                    tooltip: '구독 취소',
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelAvatar(Channel channel) {
    if (channel.thumbnail.isEmpty) {
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
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '키즈':
        return Icons.child_care;
      case '한글':
        return Icons.text_fields;
      case '만들기':
        return Icons.construction;
      case '게임':
        return Icons.games;
      case '영어':
        return Icons.language;
      case '과학':
        return Icons.science;
      case '미술':
        return Icons.palette;
      case '음악':
        return Icons.music_note;
      default:
        return Icons.category;
    }
  }
}