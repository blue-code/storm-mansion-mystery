import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class InvestigationSheet extends ConsumerWidget {
  const InvestigationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: const Color(0xFF121417),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: const Color(0xFFD4A76A).withOpacity(0.2), width: 1.5),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ),
            TabBar(
              indicatorColor: const Color(0xFFD4A76A),
              indicatorWeight: 3,
              labelColor: const Color(0xFFD4A76A),
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(icon: Icon(Icons.menu_book, size: 18), text: '증거 목록'),
                Tab(icon: Icon(Icons.assignment_ind, size: 18), text: '인물 정보'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildEvidenceTab(gameState.evidence),
                  _buildSuspectTab(ref, gameState.trustMap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceTab(List<String> evidence) {
    if (evidence.isEmpty) {
      return const Center(child: Text('아직 발견된 단서가 없습니다.', style: TextStyle(color: Colors.white24)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: evidence.length,
      itemBuilder: (context, index) {
        final item = evidence[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: ListTile(
            leading: const Icon(Icons.fingerprint, color: Color(0xFFD4A76A)),
            title: Text(item, style: const TextStyle(color: Colors.white70)),
          ),
        );
      },
    );
  }

  Widget _buildSuspectTab(WidgetRef ref, Map<String, int> trustMap) {
    final charactersAsync = ref.watch(charactersProvider);

    return charactersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD4A76A))),
      error: (err, _) => Center(child: Text('데이터 로드 실패: $err', style: TextStyle(color: Colors.white24))),
      data: (profiles) {
        if (profiles.isEmpty) {
          return const Center(child: Text('조사된 인물이 없습니다.', style: TextStyle(color: Colors.white24)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            final trustValue = trustMap[profile.name] ?? 0;
            
            final statusColor = trustValue >= 10 
              ? const Color(0xFF7EB8C9) 
              : (trustValue <= -10 ? const Color(0xFFB4122D) : Colors.white60);

            return Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: statusColor, size: 20),
                  ),
                  title: Text(
                    profile.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      trustValue >= 10 ? "우호적" : (trustValue <= -10 ? "적대적" : "중립"),
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),
                          Text(
                            "나이: ${profile.age}세",
                            style: const TextStyle(color: Color(0xFFD4A76A), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            profile.description,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.edit_note, color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "탐정의 메모: ${profile.note}",
                                    style: const TextStyle(color: Colors.amber, fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}



// 사용 예시 (스토리 스크린에서 FloatingActionButton 등으로 호출)
void showInvestigationMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const InvestigationSheet(),
  );
}
