import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_contact.dart';
import '../providers/loan_provider.dart';

class LoanContactModal extends ConsumerStatefulWidget {
  final LoanContact? editContact;

  const LoanContactModal({super.key, this.editContact});

  @override
  ConsumerState<LoanContactModal> createState() => _LoanContactModalState();
}

class _LoanContactModalState extends ConsumerState<LoanContactModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _type = 'borrowed'; // 'borrowed' (Nợ) or 'lent' (Cho vay)

  @override
  void initState() {
    super.initState();
    if (widget.editContact != null) {
      _nameController.text = widget.editContact!.contactName;
      _type = widget.editContact!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (widget.editContact != null) {
        final updated = widget.editContact!.copyWith(
          contactName: _nameController.text.trim(),
          type: _type,
        );
        await ref.read(loanProvider.notifier).updateLoanContact(updated);
      } else {
        final contact = LoanContact(
          contactName: _nameController.text.trim(),
          type: _type,
          totalAmount: 0,
          remainingAmount: 0,
        );
        await ref.read(loanProvider.notifier).addLoanContact(contact);
      }
      
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.editContact != null ? 'Sửa Người Giao Dịch' : 'Thêm Người Giao Dịch', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Loại'),
                items: const [
                  DropdownMenuItem(value: 'borrowed', child: Text('Nợ')),
                  DropdownMenuItem(value: 'lent', child: Text('Cho vay')),
                ],
                onChanged: widget.editContact != null && (widget.editContact!.totalAmount > 0 || widget.editContact!.remainingAmount > 0)
                  ? null // Disable type change if there are transactions
                  : (val) {
                      if (val != null) setState(() => _type = val);
                    },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Tên người giao dịch'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
