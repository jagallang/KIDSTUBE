import 'package:flutter/material.dart';
import '../models/recommendation_weights.dart';
import '../services/storage_service.dart';

class RecommendationSettingsScreen extends StatefulWidget {
  const RecommendationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationSettingsScreen> createState() => _RecommendationSettingsScreenState();
}

class _RecommendationSettingsScreenState extends State<RecommendationSettingsScreen> {
  RecommendationWeights _weights = const RecommendationWeights();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeights();
  }

  Future<void> _loadWeights() async {
    final weights = await StorageService.getRecommendationWeights();
    setState(() {
      _weights = weights;
      _isLoading = false;
    });
  }

  Future<void> _saveWeights() async {
    await StorageService.saveRecommendationWeights(_weights);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('추천 설정이 저장되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _updateWeight(String category, double value) {
    setState(() {
      switch (category) {
        case '한글':
          _weights = _weights.copyWith(korean: value.round());
          break;
        case '키즈':
          _weights = _weights.copyWith(kids: value.round());
          break;
        case '만들기':
          _weights = _weights.copyWith(making: value.round());
          break;
        case '게임':
          _weights = _weights.copyWith(games: value.round());
          break;
        case '영어':
          _weights = _weights.copyWith(english: value.round());
          break;
        case '과학':
          _weights = _weights.copyWith(science: value.round());
          break;
        case '미술':
          _weights = _weights.copyWith(art: value.round());
          break;
        case '음악':
          _weights = _weights.copyWith(music: value.round());
          break;
        case '랜덤':
          _weights = _weights.copyWith(random: value.round());
          break;
      }
    });
  }

  void _resetToDefaults() {
    setState(() {
      _weights = const RecommendationWeights();
    });
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

  Widget _buildWeightSlider(String category, int currentValue) {
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);
    final ratio = _weights.total > 0 ? (currentValue / _weights.total * 100) : 0.0;
    final videoCounts = _weights.getVideoCountsForTotal(20);
    final videoCount = videoCounts[category] ?? 0;

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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
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
                inactiveTrackColor: color.withOpacity(0.3),
                overlayColor: color.withOpacity(0.1),
              ),
              child: Slider(
                value: currentValue.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) => _updateWeight(category, value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            onPressed: _resetToDefaults,
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
            // 설명 카드
            Container(
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
            ),

            // 총합 표시 카드
            Container(
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
                      _weights.total.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 카테고리별 슬라이더들
            _buildWeightSlider('한글', _weights.korean),
            _buildWeightSlider('키즈', _weights.kids),
            _buildWeightSlider('만들기', _weights.making),
            _buildWeightSlider('게임', _weights.games),
            _buildWeightSlider('영어', _weights.english),
            _buildWeightSlider('과학', _weights.science),
            _buildWeightSlider('미술', _weights.art),
            _buildWeightSlider('음악', _weights.music),
            _buildWeightSlider('랜덤', _weights.random),

            const SizedBox(height: 24),

            // 저장 버튼
            Container(
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
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}