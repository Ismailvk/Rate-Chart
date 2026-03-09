import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddBillingScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const AddBillingScreen({super.key, this.docId, this.existingData});

  @override
  State<AddBillingScreen> createState() => _AddBillingScreenState();
}

class _AddBillingScreenState extends State<AddBillingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _partyNameCtrl = TextEditingController();
  final _portFromCtrl = TextEditingController();
  final _portToCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _aedRateCtrl = TextEditingController();

  String? _selectedFeet;
  DateTime? _selectedDate;
  String _status = 'Clearing'; // 'Clearing' or 'Booking'
  String _mode = 'Sea'; // 'Sea' or 'Air'
  bool _isLoading = false;

  bool get _isEditing => widget.docId != null;

  final List<String> _feetOptions = ['20 Ft', '40 Ft', '40 HC', '45 Ft'];

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.existingData != null) {
      final d = widget.existingData!;
      _partyNameCtrl.text = d['partyName'] ?? '';
      _portFromCtrl.text = d['portFrom'] ?? '';
      _portToCtrl.text = d['portTo'] ?? '';
      _rateCtrl.text = d['rate']?.toString() ?? '';
      _aedRateCtrl.text = d['aedRate']?.toString() ?? '';
      _selectedFeet = d['feet'];
      _status = d['status'] ?? 'Clearing';
      _mode = d['mode'] ?? 'Sea';
      if (d['effectFrom'] != null) {
        try {
          _selectedDate = DateTime.parse(d['effectFrom']);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _partyNameCtrl.dispose();
    _portFromCtrl.dispose();
    _portToCtrl.dispose();
    _rateCtrl.dispose();
    _aedRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
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
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _addBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mode == 'Sea' && _selectedFeet == null) {
      _showSnack('Please select container size (Feet)');
      return;
    }
    if (_selectedDate == null) {
      _showSnack('Please select Effective From date');
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'partyName': _partyNameCtrl.text.trim(),
      'portFrom': _portFromCtrl.text.trim(),
      'portTo': _portToCtrl.text.trim(),
      'feet': _mode == 'Sea' ? _selectedFeet : null,
      'rate': num.tryParse(_rateCtrl.text.trim()) ?? 0,
      'aedRate': num.tryParse(_aedRateCtrl.text.trim()) ?? 0,
      'effectFrom': _selectedDate!.toIso8601String().split('T').first,
      'status': _status,
      'mode': _mode,
      'createdAt': FieldValue.serverTimestamp(),
      // Track which document this was updated from
      if (_isEditing) 'updatedFromId': widget.docId,
    };

    try {
      final col = FirebaseFirestore.instance.collection('billings');
      // Always add a NEW document — old document is preserved as history
      await col.add(data);
      _showSnack(_isEditing
          ? 'New entry created. Old data kept as history.'
          : 'Bill added successfully');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Lato', color: Colors.white)),
        backgroundColor: const Color(0xFF0D2045),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Generic toggle row (2 options) ──
  Widget _buildToggle({
    required String label,
    required List<String> options,
    required IconData leftIcon,
    required IconData rightIcon,
    required String selected,
    required ValueChanged<String> onChanged,
    Color activeColor = const Color(0xFF2563EB),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D2045),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: options.asMap().entries.map((entry) {
              final idx = entry.key;
              final opt = entry.value;
              final isSelected = selected == opt;
              final icon = idx == 0 ? leftIcon : rightIcon;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: activeColor.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.white38),
                        const SizedBox(width: 6),
                        Text(
                          opt,
                          style: TextStyle(
                            fontFamily: 'Lato',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
        title: Text(
          _isEditing ? 'Update Billing' : 'Add Billing',
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2563EB).withOpacity(0.2),
                      const Color(0xFF1E40AF).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
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
                      child: const Icon(Icons.receipt_long,
                          color: Color(0xFF60A5FA), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing
                              ? 'Edit Billing Entry'
                              : 'New Billing Entry',
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Rate Chart — Best Express',
                          style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 12,
                              color: Color(0xFF93C5FD)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Party Name ──
              _SectionLabel(label: 'Party Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _partyNameCtrl,
                hint: 'Enter party / company name',
                icon: Icons.business_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Party name is required' : null,
              ),

              const SizedBox(height: 20),

              // ── Port From ──────────────────────────────── Port To ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: 'Port From'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _portFromCtrl,
                          hint: 'e.g. JNPT, Dubai',
                          icon: Icons.flight_takeoff_outlined,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: 'Port To'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _portToCtrl,
                          hint: 'e.g. Mundra, Chennai',
                          icon: Icons.flight_land_outlined,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Mode toggle: Sea / Air ── (moved up so Feet reacts)
              _buildToggle(
                label: 'Mode',
                options: const ['Sea', 'Air'],
                leftIcon: Icons.directions_boat_outlined,
                rightIcon: Icons.flight_outlined,
                selected: _mode,
                activeColor: _mode == 'Sea'
                    ? const Color(0xFF0891B2)
                    : const Color(0xFF7C3AED),
                onChanged: (v) => setState(() {
                  _mode = v;
                  if (v == 'Air') _selectedFeet = null; // clear feet for Air
                }),
              ),

              // ── Container Size — only for Sea ──
              if (_mode == 'Sea') ...[
                const SizedBox(height: 20),
                _SectionLabel(label: 'Container Size (Feet)'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2045),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFeet,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0D2045),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      hint: const Row(
                        children: [
                          Icon(Icons.straighten,
                              color: Colors.white38, size: 20),
                          SizedBox(width: 12),
                          Text('Select container size',
                              style: TextStyle(
                                  fontFamily: 'Lato',
                                  color: Colors.white38,
                                  fontSize: 15)),
                        ],
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white38),
                      items: _feetOptions
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Row(
                                  children: [
                                    const Icon(Icons.straighten,
                                        color: Color(0xFF60A5FA), size: 18),
                                    const SizedBox(width: 12),
                                    Text(f,
                                        style: const TextStyle(
                                            fontFamily: 'Lato',
                                            color: Colors.white,
                                            fontSize: 15)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedFeet = v),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Rate (INR) ──
              _SectionLabel(label: 'Rate (₹ INR)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _rateCtrl,
                hint: 'Enter rate in Indian Rupees',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v == null || v.isEmpty ? 'INR Rate is required' : null,
              ),

              const SizedBox(height: 20),

              // ── Rate (AED) ──
              _SectionLabel(label: 'Rate (AED — Dubai)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _aedRateCtrl,
                hint: 'Enter rate in UAE Dirham',
                icon: Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (v) =>
                    v == null || v.isEmpty ? 'AED Rate is required' : null,
              ),

              const SizedBox(height: 20),

              // ── Effective From ──
              _SectionLabel(label: 'Effective From'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2045),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Color(0xFF60A5FA), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : 'Select effective date',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 15,
                          color: _selectedDate != null
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white38),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Status toggle: Clearing / Booking ──
              _buildToggle(
                label: 'Status',
                options: const ['Clearing', 'Booking'],
                leftIcon: Icons.check_circle_outline,
                rightIcon: Icons.bookmark_added_outlined,
                selected: _status,
                activeColor: _status == 'Clearing'
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF2563EB),
                onChanged: (v) => setState(() => _status = v),
              ),

              const SizedBox(height: 36),

              // ── Add Bill button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor:
                        const Color(0xFF2563EB).withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(
                          _isEditing
                              ? Icons.save_outlined
                              : Icons.add_circle_outline,
                          color: Colors.white,
                          size: 20),
                  label: Text(
                    _isLoading
                        ? 'Saving...'
                        : _isEditing
                            ? 'Save Changes'
                            : 'Add Bill',
                    style: const TextStyle(
                      fontFamily: 'Lato',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(
          fontFamily: 'Lato', color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Lato', color: Colors.white38),
        prefixIcon: Icon(icon, color: const Color(0xFF60A5FA), size: 20),
        filled: true,
        fillColor: const Color(0xFF0D2045),
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
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        errorStyle: const TextStyle(fontFamily: 'Lato'),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Lato',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white60,
        letterSpacing: 0.5,
      ),
    );
  }
}
