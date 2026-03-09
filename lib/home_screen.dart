import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_billing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  int _streamKey = 0;
  bool _isRefreshing = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _streamKey++;
      _isRefreshing = false;
    });
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'From Date',
      builder: _datepickerTheme,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        // Reset toDate if it's before fromDate
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = null;
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? (_fromDate ?? DateTime.now()),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'To Date',
      builder: _datepickerTheme,
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  Widget Function(BuildContext, Widget?) get _datepickerTheme =>
      (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF2563EB),
                onPrimary: Colors.white,
                surface: Color(0xFF0D2045),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF0A1628),
            ),
            child: child!,
          );

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Converts stored 'yyyy-mm-dd' → 'dd-mm-yyyy' for card display
  String _fmtStored(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    } catch (_) {
      return raw; // fallback: show as-is
    }
  }

  void _clearDateFilter() => setState(() {
        _fromDate = null;
        _toDate = null;
      });

  bool _passesDateFilter(Map<String, dynamic> data) {
    if (_fromDate == null && _toDate == null) return true;
    final raw = data['effectFrom']?.toString();
    if (raw == null) return false;
    try {
      final date = DateTime.parse(raw);
      final from = _fromDate != null
          ? DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day)
          : null;
      final to = _toDate != null
          ? DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59)
          : null;
      if (from != null && date.isBefore(from)) return false;
      if (to != null && date.isAfter(to)) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _deleteBilling(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2045),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry',
            style:
                TextStyle(color: Colors.white, fontFamily: 'PlayfairDisplay')),
        content: const Text('Are you sure you want to delete this booking?',
            style: TextStyle(color: Colors.white70, fontFamily: 'Lato')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54, fontFamily: 'Lato')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontFamily: 'Lato',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('billings')
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2045),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Rate Chart',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        actions: [
          // Refresh button
          IconButton(
            onPressed: _isRefreshing ? null : _refresh,
            tooltip: 'Refresh',
            icon: AnimatedRotation(
              turns: _isRefreshing ? 1 : 0,
              duration: const Duration(milliseconds: 800),
              child: Icon(
                Icons.refresh_rounded,
                color: _isRefreshing ? Colors.white30 : Colors.white70,
                size: 22,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: const Color(0xFF2563EB).withOpacity(0.5)),
            ),
            child: const Text(
              'Best Express',
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF93C5FD),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Container(
            color: const Color(0xFF0D2045),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                  fontFamily: 'Lato', color: Colors.white, fontSize: 14),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by party name or port…',
                hintStyle: const TextStyle(
                    fontFamily: 'Lato', color: Colors.white38, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF60A5FA), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close,
                            color: Colors.white38, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0A1628),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
            ),
          ),

          // ── Date Range Filter ──
          Container(
            color: const Color(0xFF0D2045),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                // From Date
                Expanded(
                  child: GestureDetector(
                    onTap: _pickFromDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _fromDate != null
                              ? const Color(0xFF2563EB).withOpacity(0.6)
                              : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: _fromDate != null
                                ? const Color(0xFF60A5FA)
                                : Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _fromDate != null
                                  ? _fmt(_fromDate!)
                                  : 'From date',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 12,
                                color: _fromDate != null
                                    ? Colors.white
                                    : Colors.white38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('→',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                          fontFamily: 'Lato')),
                ),

                // To Date
                Expanded(
                  child: GestureDetector(
                    onTap: _pickToDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _toDate != null
                              ? const Color(0xFF2563EB).withOpacity(0.6)
                              : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: _toDate != null
                                ? const Color(0xFF60A5FA)
                                : Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _toDate != null ? _fmt(_toDate!) : 'To date',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 12,
                                color: _toDate != null
                                    ? Colors.white
                                    : Colors.white38,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Clear date filter button
                if (_fromDate != null || _toDate != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearDateFilter,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.close,
                          color: Color(0xFFEF4444), size: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('billings')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              key: ValueKey(_streamKey),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(
                            color: Colors.red, fontFamily: 'Lato')),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];

                // ── Client-side filter by party name or port + date range ──
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Text filter
                  if (_searchQuery.isNotEmpty) {
                    final party =
                        (data['partyName'] ?? '').toString().toLowerCase();
                    final portFrom =
                        (data['portFrom'] ?? '').toString().toLowerCase();
                    final portTo =
                        (data['portTo'] ?? '').toString().toLowerCase();
                    if (!party.contains(_searchQuery) &&
                        !portFrom.contains(_searchQuery) &&
                        !portTo.contains(_searchQuery)) return false;
                  }
                  // Date range filter
                  return _passesDateFilter(data);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                          ),
                          child: Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off_outlined
                                : Icons.receipt_long_outlined,
                            color: const Color(0xFF2563EB),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery"'
                              : 'No bookings yet',
                          style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 18,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different party name or port'
                              : 'Tap + to add a new billing entry',
                          style: const TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 14,
                              color: Colors.white38),
                        ),
                      ],
                    ),
                  );
                }

                // ── Result count when searching ──
                //
                return Column(
                  children: [
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list,
                                color: Color(0xFF60A5FA), size: 15),
                            const SizedBox(width: 6),
                            Text(
                              '${docs.length} result${docs.length == 1 ? '' : 's'} for "$_searchQuery"',
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 12,
                                color: Color(0xFF60A5FA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        color: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFF0D2045),
                        displacement: 20,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.2)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Header row ──
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  data['partyName'] ?? '—',
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'PlayfairDisplay',
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (data['updatedFromId'] !=
                                                  null) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 7,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF59E0B)
                                                            .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                        color: const Color(
                                                                0xFFF59E0B)
                                                            .withOpacity(0.5)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.update,
                                                          color:
                                                              Color(0xFFFBBF24),
                                                          size: 11),
                                                      SizedBox(width: 3),
                                                      Text(
                                                        'Updated',
                                                        style: TextStyle(
                                                          fontFamily: 'Lato',
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Color(0xFFFBBF24),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AddBillingScreen(
                                                    docId: doc.id,
                                                    existingData: data,
                                                  ),
                                                ),
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2563EB)
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                    Icons.edit_outlined,
                                                    color: Color(0xFF60A5FA),
                                                    size: 18),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _deleteBilling(
                                                  context, doc.id),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444)
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                    Icons.delete_outline,
                                                    color: Color(0xFFEF4444),
                                                    size: 18),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    const Divider(
                                        color: Colors.white10, height: 1),
                                    const SizedBox(height: 12),

                                    // ── Rate chips ──
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _InfoChip(
                                            icon: Icons.currency_rupee,
                                            label: 'INR Rate',
                                            value:
                                                data['rate']?.toString() ?? '—',
                                            sublabel:
                                                (data['mode'] ?? 'Sea') == 'Air'
                                                    ? 'per kg'
                                                    : 'per container',
                                          ),
                                          const SizedBox(width: 8),
                                          _InfoChip(
                                              icon: Icons.attach_money,
                                              label: 'AED Rate',
                                              value:
                                                  data['aedRate']?.toString() ??
                                                      '—'),
                                          if (data['feet'] != null) ...[
                                            const SizedBox(width: 8),
                                            _InfoChip(
                                                icon: Icons.straighten,
                                                label: 'Feet',
                                                value: data['feet'] ?? '—'),
                                          ],
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // ── Route card: Port From → Port To ──
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.08)),
                                      ),
                                      child: Row(
                                        children: [
                                          // Port From pill
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: const [
                                                    Icon(
                                                        Icons
                                                            .flight_takeoff_outlined,
                                                        color:
                                                            Color(0xFF60A5FA),
                                                        size: 12),
                                                    SizedBox(width: 4),
                                                    Text('FROM',
                                                        style: TextStyle(
                                                          fontFamily: 'Lato',
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Color(0xFF60A5FA),
                                                          letterSpacing: 1.2,
                                                        )),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  data['portFrom'] ?? '—',
                                                  style: const TextStyle(
                                                    fontFamily: 'Lato',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Arrow connector
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Color(0xFF2563EB),
                                                    size: 16),
                                                Container(
                                                  width: 30,
                                                  height: 1,
                                                  color: const Color(0xFF2563EB)
                                                      .withOpacity(0.3),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Port To pill
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: const [
                                                    Text('TO',
                                                        style: TextStyle(
                                                          fontFamily: 'Lato',
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              Color(0xFF34D399),
                                                          letterSpacing: 1.2,
                                                        )),
                                                    SizedBox(width: 4),
                                                    Icon(
                                                        Icons
                                                            .flight_land_outlined,
                                                        color:
                                                            Color(0xFF34D399),
                                                        size: 12),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  data['portTo'] ?? '—',
                                                  style: const TextStyle(
                                                    fontFamily: 'Lato',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.end,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // ── Effective Date badge ──
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E40AF)
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: const Color(0xFF3B82F6)
                                                    .withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.calendar_today_outlined,
                                                  color: Color(0xFF93C5FD),
                                                  size: 12),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Effective: ${_fmtStored(data['effectFrom']?.toString())}',
                                                style: const TextStyle(
                                                  fontFamily: 'Lato',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF93C5FD),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // ── Status + Mode badges ──
                                    Row(
                                      children: [
                                        _StatusBadge(
                                          label: data['status'] ?? 'Booking',
                                          color: (data['status'] ?? '') ==
                                                  'Clearing'
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFF2563EB),
                                          icon: (data['status'] ?? '') ==
                                                  'Clearing'
                                              ? Icons.check_circle_outline
                                              : Icons.bookmark_added_outlined,
                                        ),
                                        const SizedBox(width: 8),
                                        _StatusBadge(
                                          label: data['mode'] ?? 'Sea',
                                          color: (data['mode'] ?? '') == 'Air'
                                              ? const Color(0xFF7C3AED)
                                              : const Color(0xFF0891B2),
                                          icon: (data['mode'] ?? '') == 'Air'
                                              ? Icons.flight_outlined
                                              : Icons.directions_boat_outlined,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddBillingScreen()),
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Billing',
          style: TextStyle(
            fontFamily: 'Lato',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Small info chip widget ──
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sublabel;
  const _InfoChip(
      {required this.icon,
      required this.label,
      required this.value,
      this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white30, size: 11),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                      fontFamily: 'Lato', fontSize: 10, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
                overflow: TextOverflow.ellipsis),
            if (sublabel != null) ...[
              const SizedBox(height: 2),
              Text(
                sublabel!,
                style: const TextStyle(
                  fontFamily: 'Lato',
                  fontSize: 9,
                  color: Color(0xFF60A5FA),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status / Mode badge ──
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
