import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';
import '../core/service_locator.dart';
import '../core/interfaces/i_storage_service.dart';
import '../core/debug_logger.dart';

class RecommendationSettingsScreen extends StatefulWidget {
  const RecommendationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationSettingsScreen> createState() => _RecommendationSettingsScreenState();
}

class _RecommendationSettingsScreenState extends State<RecommendationSettingsScreen> {
  late RecommendationProvider _recommendationProvider;
  
  @override
  void initState() {
    super.initState();
    // Create provider instance using service locator
    _recommendationProvider = RecommendationProvider(
      storageService: getService<IStorageService>(),
    );
    // Load weights after creation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recommendationProvider.loadWeights();
    });
  }
  
  @override
  void dispose() {
    _recommendationProvider.dispose();
    super.dispose();
  }

  void _saveWeights() async {
    DebugLogger.logFlow('RecommendationSettingsScreen._saveWeights started', data: {
      'totalWeight': _recommendationProvider.weights.total
    });
    
    await _recommendationProvider.saveWeights();
    
    if (mounted && _recommendationProvider.error == null) {
      DebugLogger.logFlow('RecommendationSettingsScreen._saveWeights: success');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('추천 설정이 저장되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (_recommendationProvider.error != null) {
      DebugLogger.logError('RecommendationSettingsScreen._saveWeights failed', _recommendationProvider.error!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_recommendationProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '한글':
        return Colors.blue;
      case '키즈':
        return Colors.pink;
      case '만들기':
        return Colors.orange;
      case '게임':
        return Colors.green;
      case '영어':
        return Colors.indigo;
      case '과학':
        return Colors.teal;
      case '미술':
        return Colors.deepOrange;
      case '음악':
        return Colors.cyan;
      case '랜덤':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '한글':
        return Icons.text_fields;
      case '키즈':
        return Icons.child_care;
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
      case '랜덤':
        return Icons.shuffle;
      default:
        return Icons.category;
    }
  }

  Widget _buildWeightSlider(String category, RecommendationProvider provider) {
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);
    final currentValue = provider.getWeightForCategory(category);
    final ratio = provider.getRatioForCategory(category);
    final videoCount = provider.getVideoCountForCategory(category, 20);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '20개 영상 중 약 ${videoCount}개 (${ratio.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    currentValue.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.3),
                overlayColor: color.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: currentValue.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) => provider.updateWeight(category, value.round()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RecommendationProvider>.value(
      value: _recommendationProvider,
      child: Consumer<RecommendationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('추천 설정'),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('추천 설정'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              actions: [
                TextButton(
                  onPressed: provider.resetToDefaults,
                  child: const Text('초기화', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: _saveWeights,
                  child: const Text('저장', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInfoCard(),
                  _buildTotalWeightCard(provider),
                  const SizedBox(height: 8),
                  ...['한글', '키즈', '만들기', '게임', '영어', '과학', '미술', '음악', '랜덤']
                      .map((category) => _buildWeightSlider(category, provider))
                      .toList(),
                  const SizedBox(height: 24),
                  _buildSaveButton(provider),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '추천 알고리즘 설정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '아이에게 보여줄 영상의 카테고리별 비율을 조정하세요.\n슬라이더를 움직여서 각 카테고리의 가중치를 0-10 사이로 설정할 수 있습니다.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalWeightCard(RecommendationProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '총 가중치 합계',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Text(
              provider.weights.total.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(RecommendationProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _saveWeights,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          '설정 저장',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}