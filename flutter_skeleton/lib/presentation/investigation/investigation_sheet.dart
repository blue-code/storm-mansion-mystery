import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class InvestigationSheet extends ConsumerWidget {
  const InvestigationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GameState를 관찰하여 변경사항 즉시 반영
    final gameState = ref.watch(gameStateProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
            ),
            const TabBar(
              indicatorColor: Colors.redAccent,
              labelColor: Colors.redAccent,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.search), text: '수집한 단서 (Evidence)'),
                Tab(icon: Icon(Icons.people), text: '인물 파일 (Trust)'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // 증거물 탭
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: gameState.evidence.length,
                    itemBuilder: (context, index) {
                      final item = gameState.evidence[index];
                      return Card(
                        color: Colors.black45,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.vpn_key, color: Colors.amber),
                          title: Text(item, style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
                  // 인물 신뢰도 탭
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: gameState.trustMap.keys.length,
                    itemBuilder: (context, index) {
                      final charName = gameState.trustMap.keys.elementAt(index);
                      final trustValue = gameState.trustMap[charName]!;
                      
                      Color statusColor = Colors.grey;
                      if (trustValue > 10) statusColor = Colors.green;
                      if (trustValue < 0) statusColor = Colors.red;

                      return Card(
                        color: Colors.black45,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(charName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          trailing: Text(
                            trustValue > 0 ? "호의적" : (trustValue < 0 ? "경계함" : "중립"),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
