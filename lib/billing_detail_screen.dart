import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_billing_screen.dart';

class BillingDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const BillingDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<BillingDetailScreen> createState() => _BillingDetailScreenState();
}

class _BillingDetailScreenState extends State<BillingDetailScreen> {
  String _fmtStored(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    } catch (_) {
      return raw;
    }
  }

  // ── Edit Remarks bottom sheet ──
  Future<void> _showEditRemarksSheet(
    BuildContext context, {
    required String aedDocId,
    required String currentRemarks,
  }) async {
    final ctrl = TextEditingController(text: currentRemarks);
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D2045),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Edit Remarks',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Update the note for this AED rate entry',
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                minLines: 3,
                autofocus: true,
                style: const TextStyle(
                    fontFamily: 'Lato', color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter remarks…',
                  hintStyle: const TextStyle(
                      fontFamily: 'Lato', color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0A1628),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          setSheet(() => saving = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('billings')
                                .doc(widget.docId)
                                .collection('aedRates')
                                .doc(aedDocId)
                                .update({
                              'remarks': ctrl.text.trim(),
                              'addedAt': FieldValue.serverTimestamp(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (_) {
                            setSheet(() => saving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                  label: Text(
                    saving ? 'Saving…' : 'Save Remarks',
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2045),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Billing Details',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF60A5FA), size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddBillingScreen(docId: widget.docId, existingData: widget.data),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Party Name header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0D2045),
                    const Color(0xFF0F2D6B).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF2563EB).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.business_outlined,
                        color: Color(0xFF60A5FA), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.data['partyName'] ?? '—',
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _StatusBadge(
                              label: widget.data['status'] ?? 'Booking',
                              color: (widget.data['status'] ?? '') == 'Clearing'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF2563EB),
                              icon: (widget.data['status'] ?? '') == 'Clearing'
                                  ? Icons.check_circle_outline
                                  : Icons.bookmark_added_outlined,
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(
                              label: widget.data['mode'] ?? 'Sea',
                              color: (widget.data['mode'] ?? '') == 'Air'
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFF0891B2),
                              icon: (widget.data['mode'] ?? '') == 'Air'
                                  ? Icons.flight_outlined
                                  : Icons.directions_boat_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Route ──
            _SectionTitle(title: 'Route'),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2045),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFF2563EB).withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  // Port From
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Icon(Icons.flight_takeoff_outlined,
                              color: Color(0xFF60A5FA), size: 13),
                          SizedBox(width: 4),
                          Text('FROM',
                              style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF60A5FA),
                                  letterSpacing: 1.2)),
                        ]),
                        const SizedBox(height: 4),
                        Text(widget.data['portFrom'] ?? '—',
                            style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Color(0xFF2563EB), size: 20),
                  // Port To
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text('TO',
                                style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF34D399),
                                    letterSpacing: 1.2)),
                            SizedBox(width: 4),
                            Icon(Icons.flight_land_outlined,
                                color: Color(0xFF34D399), size: 13),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(widget.data['portTo'] ?? '—',
                            style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                            textAlign: TextAlign.end),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Rates Row ──
            _SectionTitle(title: 'Rates & Details'),
            const SizedBox(height: 10),
            Row(
              children: [
                _DetailChip(
                    icon: Icons.currency_rupee,
                    label: 'INR Rate',
                    value: widget.data['rate']?.toString() ?? '—',
                    sublabel: (widget.data['mode'] ?? 'Sea') == 'Air'
                        ? 'per kg'
                        : 'per container'),
                const SizedBox(width: 8),
                if (widget.data['feet'] != null)
                  _DetailChip(
                      icon: Icons.straighten,
                      label: 'Feet',
                      value: widget.data['feet'] ?? '—'),
              ],
            ),
            const SizedBox(height: 10),
            // Effective date badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: Color(0xFF93C5FD), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Effective From: ${_fmtStored(widget.data['effectFrom']?.toString())}',
                    style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF93C5FD)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── AED Rate History ──
            Row(
              children: [
                const Icon(Icons.attach_money,
                    color: Color(0xFFFBBF24), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'AED Rate History',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'All AED rates for this party, newest first',
              style: TextStyle(
                  fontFamily: 'Lato', fontSize: 12, color: Colors.white38),
            ),
            const SizedBox(height: 4),
            // Swipe hint
            Row(
              children: const [
                Icon(Icons.chevron_left_rounded,
                    color: Colors.white24, size: 14),
                SizedBox(width: 4),
                Text(
                  'Swipe left on an entry to edit its remarks',
                  style: TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 11,
                      color: Colors.white24,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('billings')
                  .doc(widget.docId)
                  .collection('aedRates')
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2563EB))),
                  );
                }

                final rateDocs = snapshot.data?.docs ?? [];

                // If no sub-collection yet, fall back to root-level aedRate
                if (rateDocs.isEmpty) {
                  final fallback = widget.data['aedRate']?.toString();
                  if (fallback != null && fallback.isNotEmpty) {
                    return _AedRateRow(
                      aedDocId: '',
                      rate: fallback,
                      date: _fmtStored(widget.data['effectFrom']?.toString()),
                      isLatest: true,
                      isFirst: true,
                      isLast: true,
                      remarks: widget.data['remarks'] ?? '',
                      onEditRemarks: (r) => _showEditRemarksSheet(
                          context,
                          aedDocId: '',
                          currentRemarks: r),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2045),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No AED rate history yet. Tap + on the home screen to add.',
                      style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 13,
                          color: Colors.white38),
                    ),
                  );
                }

                return Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2045),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF2563EB).withOpacity(0.15)),
                  ),
                  child: Column(
                    children: List.generate(rateDocs.length, (i) {
                      final rateData =
                          rateDocs[i].data() as Map<String, dynamic>;
                      final aedDocId = rateDocs[i].id;
                      return _AedRateRow(
                        aedDocId: aedDocId,
                        rate: rateData['rate']?.toString() ?? '—',
                        date:
                            _fmtStored(rateData['effectiveDate']?.toString()),
                        isLatest: i == 0,
                        isFirst: i == 0,
                        isLast: i == rateDocs.length - 1,
                        portFrom: rateData['portFrom']?.toString() ?? '',
                        portTo: rateData['portTo']?.toString() ?? '',
                        remarks: rateData['remarks']?.toString() ?? '',
                        onEditRemarks: (r) => _showEditRemarksSheet(
                          context,
                          aedDocId: aedDocId,
                          currentRemarks: r,
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── AED rate timeline row (swipeable for remarks editing) ──
class _AedRateRow extends StatefulWidget {
  final String aedDocId;
  final String rate;
  final String date;
  final bool isLatest;
  final bool isFirst;
  final bool isLast;
  final String portFrom;
  final String portTo;
  final String remarks;
  final void Function(String currentRemarks) onEditRemarks;

  const _AedRateRow({
    required this.aedDocId,
    required this.rate,
    required this.date,
    required this.isLatest,
    required this.isFirst,
    required this.isLast,
    this.portFrom = '',
    this.portTo = '',
    this.remarks = '',
    required this.onEditRemarks,
  });

  @override
  State<_AedRateRow> createState() => _AedRateRowState();
}

class _AedRateRowState extends State<_AedRateRow> {
  double _dragOffset = 0;
  bool _revealed = false;
  final double _revealWidth = 72;

  @override
  Widget build(BuildContext context) {
    final hasPort = widget.portFrom.isNotEmpty || widget.portTo.isNotEmpty;
    final hasRemarks = widget.remarks.isNotEmpty;

    return ClipRect(
      child: Stack(
        children: [
          // ── Background Edit button ──
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _dragOffset = 0;
                    _revealed = false;
                  });
                  widget.onEditRemarks(widget.remarks);
                },
                child: Container(
                  width: _revealWidth,
                  color: const Color(0xFF2563EB).withOpacity(0.85),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(height: 3),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Sliding row ──
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragOffset =
                    (_dragOffset + details.delta.dx).clamp(-_revealWidth, 0.0);
              });
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                if (_dragOffset < -_revealWidth / 2) {
                  _dragOffset = -_revealWidth;
                  _revealed = true;
                } else {
                  _dragOffset = 0;
                  _revealed = false;
                }
              });
            },
            onTap: () {
              if (_revealed) {
                setState(() {
                  _dragOffset = 0;
                  _revealed = false;
                });
              }
            },
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2045),
                  border: widget.isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Colors.white10)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dot
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isLatest
                              ? const Color(0xFFFBBF24)
                              : Colors.white24,
                          border: widget.isLatest
                              ? Border.all(
                                  color: const Color(0xFFF59E0B), width: 2)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Rate + port + remarks
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'AED ',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 11,
                                  color: widget.isLatest
                                      ? const Color(0xFFFBBF24)
                                      : Colors.white38,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                widget.rate,
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: widget.isLatest
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),

                          // Port route
                          if (hasPort) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.flight_takeoff_outlined,
                                      color: Color(0xFF60A5FA), size: 11),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      widget.portFrom.isNotEmpty
                                          ? widget.portFrom
                                          : '—',
                                      style: const TextStyle(
                                          fontFamily: 'Lato',
                                          fontSize: 11,
                                          color: Colors.white70),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5),
                                    child: Icon(Icons.arrow_forward_rounded,
                                        color: Color(0xFF2563EB), size: 11),
                                  ),
                                  const Icon(Icons.flight_land_outlined,
                                      color: Color(0xFF34D399), size: 11),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      widget.portTo.isNotEmpty
                                          ? widget.portTo
                                          : '—',
                                      style: const TextStyle(
                                          fontFamily: 'Lato',
                                          fontSize: 11,
                                          color: Colors.white70),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Remarks
                          if (hasRemarks) ...[
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.notes_outlined,
                                    color: Color(0xFF93C5FD), size: 12),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    widget.remarks,
                                    style: const TextStyle(
                                      fontFamily: 'Lato',
                                      fontSize: 11,
                                      color: Color(0xFFBAD4F8),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Date + LATEST badge + swipe hint
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.isLatest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFFBBF24).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFFBBF24)
                                      .withOpacity(0.5)),
                            ),
                            child: const Text(
                              'LATEST',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFBBF24),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        if (widget.isLatest) const SizedBox(height: 4),
                        Text(
                          widget.date,
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 11,
                            color: widget.isLatest
                                ? const Color(0xFF93C5FD)
                                : Colors.white30,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white24,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Lato',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white38,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sublabel;

  const _DetailChip(
      {required this.icon,
      required this.label,
      required this.value,
      this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white30, size: 12),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Lato',
                        fontSize: 10,
                        color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(sublabel!,
                  style: const TextStyle(
                      fontFamily: 'Lato',
                      fontSize: 9,
                      color: Color(0xFF60A5FA),
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
