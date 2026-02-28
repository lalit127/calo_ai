// lib/screens/settings_screen.dart — Cal AI exact design
import 'package:cal_ai/services/dart/storage_service.dart';
import 'package:cal_ai/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

const kLime = Color(0xFFC1FF72);
const kSurface = Color(0xFF111111);
const kGray = Color(0xFF888888);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    _calCtrl.text = (await _storage.getGoalCalories()).toString();
    _proCtrl.text = (await _storage.getGoalProtein()).toStringAsFixed(0);
    _nameCtrl.text = await _storage.getUserName() ?? '';
    setState(() {});
  }

  Future<void> _save() async {
    await _storage.setGoalCalories(int.tryParse(_calCtrl.text) ?? 2000);
    await _storage.setGoalProtein(double.tryParse(_proCtrl.text) ?? 150);
    await _storage.setUserName(_nameCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Settings saved'),
        backgroundColor: kLime,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Profile',
                      style: AppTextStyles(context).display22W700.copyWith(
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: kLime,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child:  Text('Save',
                          style: AppTextStyles(context).display14W700.copyWith(
                              color: Colors.black,)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  // Profile avatar
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: kLime,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child:  Center(
                            child: Text('👤', style: AppTextStyles(context).display14W700.copyWith(fontSize: 36)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _nameCtrl.text.isEmpty ? 'User' : _nameCtrl.text,
                          style:  AppTextStyles(context).display18W700.copyWith(
                              color: Colors.white,),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  _sectionLabel('PROFILE'),
                  const SizedBox(height: 10),
                  _inputTile('Name', _nameCtrl, Icons.person_outline, hint: 'Your name'),

                  const SizedBox(height: 20),
                  _sectionLabel('DAILY GOALS'),
                  const SizedBox(height: 10),
                  _inputTile('Calories', _calCtrl, Icons.local_fire_department_outlined,
                      hint: '2000', keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  _inputTile('Protein (g)', _proCtrl, Icons.fitness_center_outlined,
                      hint: '150', keyboardType: TextInputType.number),

                  const SizedBox(height: 20),
                  _sectionLabel('AI CONFIGURATION'),
                  const SizedBox(height: 10),
                  // API key tile
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.key_outlined, color: kGray, size: 18),
                            const SizedBox(width: 10),
                            const Text('Mistral API Key',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _keyCtrl,
                          obscureText: _obscure,
                          style: AppTextStyles(context).display13W500.copyWith(color: Colors.white,fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            hintText: 'Paste your key here',
                            hintStyle: const TextStyle(color: Color(0xFF444444)),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: kLime, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: kGray, size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Get a free key at console.mistral.ai',
                            style: TextStyle(color: kGray, fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('APP INFO'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Version', '1.0.0', first: true),
                        _divider(),
                        _infoRow('AI Model', 'Mistral Pixtral-12b'),
                        _divider(),
                        _infoRow('Made with', '❤️ + Flutter'),
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
  }

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(
          color: kGray, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600));

  Widget _inputTile(String label, TextEditingController ctrl, IconData icon,
      {String? hint, TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: kGray, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles(context).display11W500.copyWith(color: kGray)),
                const SizedBox(height: 4),
                TextField(
                  controller: ctrl,
                  keyboardType: keyboardType,
                  style: AppTextStyles(context).display15W600.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Color(0xFF444444)),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool first = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kGray, fontSize: 14)),
          Text(value,
              style: AppTextStyles(context).display14W600.copyWith(
                  color: Colors.white,)),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFF1A1A1A), indent: 16, endIndent: 16);
}
