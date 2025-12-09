import 'dart:convert';
import 'dart:io';

import 'package:app_vedc/utils/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Small model to hold file + metadata computed asynchronously
class _CsvEntry {
  final File file;
  final String name;
  final String sizeText;
  final String dateText;

  _CsvEntry({
    required this.file,
    required this.name,
    required this.sizeText,
    required this.dateText,
  });
}

class DataEcgScreen extends StatefulWidget {
  const DataEcgScreen({super.key, this.lastCsvPath});

  final String? lastCsvPath;

  @override
  State<DataEcgScreen> createState() => _DataEcgScreenState();
}

class _DataEcgScreenState extends State<DataEcgScreen> {
  String? _uploadingPath;
  String? _sendingPath;

  static const String _filePrefix = 'ecg_';

  // Cached future so we don't reload files on every build
  late Future<Map<String, Object>> _filesFuture;

  @override
  void initState() {
    super.initState();
    _filesFuture = _loadFilesAndSynced();
  }

  Future<List<_CsvEntry>> _loadCsvFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final entities = await dir
        .list()
        .where(
          (entity) =>
              entity is File &&
              entity.path.endsWith('.csv') &&
              p.basename(entity.path).startsWith(_filePrefix),
        )
        .toList();
    final files = entities.cast<File>();
    files.sort((a, b) => b.path.compareTo(a.path));

    final results = <_CsvEntry>[];
    for (final f in files) {
      try {
        final len = await f.length();
        final modified = await f.lastModified();
        final sizeText = '${(len / 1024).toStringAsFixed(1)} KB';
        final dateText =
            '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')} ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';
        results.add(
          _CsvEntry(
            file: f,
            name: p.basename(f.path),
            sizeText: sizeText,
            dateText: dateText,
          ),
        );
      } catch (_) {
        results.add(
          _CsvEntry(
            file: f,
            name: p.basename(f.path),
            sizeText: '',
            dateText: '',
          ),
        );
      }
    }
    return results;
  }

  Future<Map<String, String>> _getSyncedMap() async {
    final query = await FirebaseFirestore.instance
        .collection('ecg_exports')
        .get();
    final map = <String, String>{};
    for (final doc in query.docs) {
      final fn = doc.data()['fileName'];
      if (fn is String && fn.isNotEmpty) map[fn] = doc.id;
    }
    return map;
  }

  Future<Map<String, Object>> _loadFilesAndSynced() async {
    final files = await _loadCsvFiles();
    final synced = await _getSyncedMap();
    return {'entries': files, 'synced': synced};
  }

  Future<void> _deleteFileWithConfirm(
    File file,
    Map<String, String> syncedMap,
  ) async {
    final name = p.basename(file.path);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa file "$name" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // ignore: avoid_print
      print('Attempting to delete ECG file: ${file.path}');

      final exists = await file.exists();
      if (!exists) {
        final docId = syncedMap[name];
        if (docId != null) {
          await FirebaseFirestore.instance
              .collection('ecg_exports')
              .doc(docId)
              .delete();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File không tồn tại: $name')));
        setState(() {
          _filesFuture = _loadFilesAndSynced();
        });
        return;
      }

      await file.delete();

      final docId = syncedMap[name];
      if (docId != null) {
        await FirebaseFirestore.instance
            .collection('ecg_exports')
            .doc(docId)
            .delete();
      }

      // ignore: avoid_print
      print('Deleted ECG file: ${file.path}');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xóa $name')));
      setState(() {
        _filesFuture = _loadFilesAndSynced();
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('Failed to delete $name: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
    }
  }

  Future<void> _uploadToFirestore(File file) async {
    setState(() {
      _uploadingPath = file.path;
    });
    try {
      final exists = await file.exists();
      if (!exists) throw StateError('File không tồn tại: ${file.path}');

      final bytes = await file.readAsBytes();
      final size = bytes.length;
      if (size > 900 * 1024) {
        throw StateError(
          'File quá lớn (${(size / 1024).toStringAsFixed(1)} KB), Firestore chỉ phù hợp file < 1MB',
        );
      }

      final fileName = p.basename(file.path);
      final contentBase64 = base64Encode(bytes);
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('ecg_exports').add({
        'fileName': fileName,
        'sizeBytes': size,
        'contentBase64': contentBase64,
        'uploadedAt': FieldValue.serverTimestamp(),
        'userUid': user?.uid,
        'userEmail': user?.email,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đồng bộ lên Firestore: $fileName')),
      );
      if (mounted) {
        setState(() {
          _filesFuture = _loadFilesAndSynced();
        });
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đồng bộ Firestore lỗi (${e.code}): ${e.message ?? e}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đồng bộ thất bại: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPath = null;
        });
      }
    }
  }

  Future<void> _sendEmail(File file) async {
    setState(() {
      _sendingPath = file.path;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final storedName = prefs.getString('user_fullName');
      final fileName = p.basename(file.path);
      int sizeBytes = 0;
      DateTime? modified;
      try {
        sizeBytes = await file.length();
        modified = await file.lastModified();
      } catch (_) {}

      final sizeKb = (sizeBytes / 1024).toStringAsFixed(1);
      final modifiedStr = modified != null
          ? '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')} ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}'
          : 'N/A';

      final subject = '[VEDC] Dữ liệu ECG - $fileName';
      final body =
          '''Kính gửi Bác sĩ,

Tôi gửi kèm file dữ liệu ECG (tên file: $fileName) thu thập từ ứng dụng VEDC.

Thông tin bệnh nhân :
- Tên: ${storedName ?? user?.displayName ?? 'Không có'}
- Email: ${user?.email ?? 'Không có'}
- UserID: ${user?.uid ?? 'Không có'}

Thông tin file:
- Kích thước: ${sizeKb} KB
- Thời gian: $modifiedStr

Mô tả ngắn:
Dữ liệu thu ở chế độ realtime, định dạng CSV. Vui lòng phản hồi nếu cần thêm thông tin hoặc hướng dẫn phân tích.

Trân trọng,
          ${storedName ?? user?.displayName ?? user?.email ?? 'Người gửi'}
''';

      final xfile = XFile(file.path);
      await Share.shareXFiles([xfile], text: body, subject: subject);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã mở trình chia sẻ, chọn Gmail/Outlook...'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gửi email thất bại: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _sendingPath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: VedcColors.background,
        foregroundColor: VedcColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Data ECG',
          style: TextStyle(
            color: VedcColors.textPrimary,
            fontFamily: 'Livvic',
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),
      backgroundColor: VedcColors.background,
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<Map<String, Object>>(
              future: _filesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data;
                final entries =
                    (data?['entries'] as List<_CsvEntry>?) ??
                    const <_CsvEntry>[];
                final synced = Map<String, String>.from(
                  data?['synced'] as Map? ?? {},
                );

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 64,
                          color: VedcColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có file CSV',
                          style: TextStyle(
                            fontSize: 16,
                            color: VedcColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Thu dữ liệu ở màn Realtime để tạo file CSV.',
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _filesFuture = _loadFilesAndSynced();
                    });
                    await _filesFuture;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final file = entry.file;
                      final name = entry.name;
                      final isLatest =
                          widget.lastCsvPath != null &&
                          file.path == widget.lastCsvPath;
                      final uploading = _uploadingPath == file.path;
                      final sending = _sendingPath == file.path;
                      final isSynced = synced.containsKey(name);
                      final sizeText = entry.sizeText;
                      final dateText = entry.dateText;

                      return Card(
                        color: VedcColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(name),
                              content: const Text(
                                'Chọn hành động cho file này.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đường dẫn: ${file.path}',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Xem đường dẫn'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(ctx).pop();
                                    await _deleteFileWithConfirm(file, synced);
                                  },
                                  child: const Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.insert_drive_file,
                                  color: Colors.cyanAccent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: VedcColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSynced)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                left: 8.0,
                                              ),
                                              child: Icon(
                                                Icons.cloud_done,
                                                color: Colors.green,
                                                size: 18,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (sizeText.isNotEmpty)
                                            Text(
                                              sizeText,
                                              style: const TextStyle(
                                                color: VedcColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          if (sizeText.isNotEmpty &&
                                              dateText.isNotEmpty)
                                            const SizedBox(width: 8),
                                          if (dateText.isNotEmpty)
                                            Text(
                                              dateText,
                                              style: const TextStyle(
                                                color: VedcColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          if (isLatest) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.cyan.withOpacity(
                                                  0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Mới',
                                                style: TextStyle(
                                                  color: Colors.cyan.shade400,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    uploading
                                        ? const SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : IconButton(
                                            onPressed: () =>
                                                _uploadToFirestore(file),
                                            icon: const Icon(
                                              Icons.cloud_upload_outlined,
                                            ),
                                            color: Colors.cyanAccent,
                                            tooltip: 'Đồng bộ',
                                          ),
                                    sending
                                        ? const SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : IconButton(
                                            onPressed: () => _sendEmail(file),
                                            icon: const Icon(
                                              Icons.send_outlined,
                                            ),
                                            color: Colors.cyanAccent,
                                            tooltip: 'Gửi',
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
