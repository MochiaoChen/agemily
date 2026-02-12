import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/agent_providers.dart';
import '../../providers/database_provider.dart';

class MemoryScreen extends ConsumerWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆笔记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNote(context, ref),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: db.memoryDao.watchAllNotes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!;
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('暂无记忆笔记',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Dismissible(
                key: Key(note.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.error,
                  child: Icon(Icons.delete,
                      color: Theme.of(context).colorScheme.onError),
                ),
                onDismissed: (_) {
                  ref.read(memoryManagerProvider).deleteNote(note.id);
                },
                child: ListTile(
                  title: Text(note.title),
                  subtitle: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加记忆'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: '内容'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(memoryManagerProvider).addNote(
            title: titleController.text,
            content: contentController.text,
          );
    }

    titleController.dispose();
    contentController.dispose();
  }
}
