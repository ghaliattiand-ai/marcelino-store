import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/providers/addresses_provider.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          title: const Text('عناويني'),
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddSheet(context),
          backgroundColor: _orange,
          child: const Icon(Icons.add_location_alt, color: Colors.white),
        ),
        body: Consumer<AddressesProvider>(
          builder: (context, provider, _) {
            if (provider.addresses.isEmpty) {
              return _EmptyState(onAdd: () => _showAddSheet(context));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: provider.addresses.length,
              itemBuilder: (ctx, index) {
                final address = provider.addresses[index];
                return _AddressCard(
                  address: address,
                  onDefault: () => provider.setDefault(address.id),
                  onDelete: () => _confirmDelete(context, provider, address),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddressFormSheet(),
    );
  }

  void _confirmDelete(BuildContext context, AddressesProvider provider, Address address) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العنوان'),
        content: Text('هل تريد حذف عنوان "${address.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              provider.removeAddress(address.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف العنوان')),
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'لا يوجد عناوين محفوظة',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف عنوانك الأول لتسهيل عملية التوصيل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('إضافة عنوان'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onDefault;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.onDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: address.isDefault ? Border.all(color: _orange, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _navy.withValues(alpha: 0.1),
                  child: const Icon(Icons.location_on, color: _navy, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'الافتراضي',
                                style: TextStyle(fontSize: 10, color: _orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${address.street}، ${address.city}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address.phone,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                    if (value == 'default') onDefault();
                  },
                  itemBuilder: (_) => [
                    if (!address.isDefault)
                      const PopupMenuItem(value: 'default', child: Text('تعيين كافتراضي')),
                    const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet();

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isDefault = true;

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AddressesProvider>();
    final address = Address(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      phone: _phoneController.text.trim(),
      isDefault: _isDefault,
    );
    provider.addAddress(address);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافة العنوان بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'عنوان جديد',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _navy),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                label: 'اسم العنوان (المنزل، العمل...)',
                icon: Icons.label,
                validator: (v) => v!.trim().isEmpty ? 'أدخل اسم العنوان' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _streetController,
                label: 'الشارع والتفاصيل',
                icon: Icons.streetview,
                validator: (v) => v!.trim().isEmpty ? 'أدخل الشارع' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _cityController,
                label: 'المدينة',
                icon: Icons.location_city,
                validator: (v) => v!.trim().isEmpty ? 'أدخل المدينة' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v!.trim().isEmpty) return 'أدخل رقم الهاتف';
                  if (v.trim().length < 10) return 'رقم الهاتف قصير جداً';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v ?? true),
                contentPadding: EdgeInsets.zero,
                title: const Text('تعيين كعنوان افتراضي'),
                activeColor: _orange,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ العنوان', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _navy),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _navy),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
