import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminDemandesDomestiquesPage extends StatefulWidget {
  final Color accentColor;

  const AdminDemandesDomestiquesPage({super.key, required this.accentColor});

  @override
  State<AdminDemandesDomestiquesPage> createState() =>
      _AdminDemandesDomestiquesPageState();
}

class _AdminDemandesDomestiquesPageState
    extends State<AdminDemandesDomestiquesPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _demandes = [];
  String _filtreStatut = 'en_attente_validation';

  static const _statuts = [
    'en_attente_validation',
    'en_cours_traitement',
    'affecte',
    'annule',
  ];

  static const _labelsStatut = {
    'en_attente_validation': 'En attente',
    'en_cours_traitement': 'En traitement',
    'affecte': 'Affectée',
    'annule': 'Annulée',
  };

  static const _labelsService = {
    'menagere': 'Ménagère',
    'servante': 'Servante',
    'serveuse': 'Serveuse',
  };

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('demandes_service_domestique')
          .select(
              'id, type_service, type_prestation, nom_demandeur, telephone_demandeur, '
              'ville, commune, description, date_souhaitee, statut, '
              'enquete_effectuee, notes_admin, created_at')
          .eq('statut', _filtreStatut)
          .order('created_at', ascending: true);
      if (mounted) {
        setState(() {
          _demandes = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Admin demandes: erreur: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changerStatut(
    String id,
    String nouveauStatut, {
    bool? enquete,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{'statut': nouveauStatut};
      if (enquete != null) updates['enquete_effectuee'] = enquete;
      if (notes != null) updates['notes_admin'] = notes;
      await _supabase
          .from('demandes_service_domestique')
          .update(updates)
          .eq('id', id);
      if (mounted) {
        _showSnack("Demande mise à jour !");
        _charger();
      }
    } on PostgrestException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      debugPrint('Erreur changement statut: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showActionSheet(Map<String, dynamic> d) {
    final notesCtrl = TextEditingController(text: d['notes_admin'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Actions — ${_labelsService[d['type_service']] ?? d['type_service']}",
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                d['nom_demandeur'] ?? '',
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Notes admin
              TextField(
                controller: notesCtrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Notes internes (enquête, observations...)",
                  hintStyle: GoogleFonts.inter(
                      color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              if (d['statut'] == 'en_attente_validation')
                _actionBtn(
                  Icons.assignment_turned_in,
                  "Prendre en charge",
                  Colors.blue,
                  () {
                    Navigator.pop(ctx);
                    _changerStatut(
                      d['id'],
                      'en_cours_traitement',
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                  },
                ),

              if (d['statut'] == 'en_cours_traitement' &&
                  d['enquete_effectuee'] != true)
                _actionBtn(
                  Icons.search_rounded,
                  "Marquer enquête effectuée",
                  Colors.purple,
                  () {
                    Navigator.pop(ctx);
                    _changerStatut(
                      d['id'],
                      'en_cours_traitement',
                      enquete: true,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                  },
                ),

              if (d['statut'] == 'en_cours_traitement')
                _actionBtn(
                  Icons.check_circle_rounded,
                  "Marquer comme affectée",
                  Colors.green,
                  () {
                    Navigator.pop(ctx);
                    _changerStatut(
                      d['id'],
                      'affecte',
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                  },
                ),

              if (d['statut'] != 'annule')
                _actionBtn(
                  Icons.cancel_outlined,
                  "Annuler / Rejeter",
                  Colors.red,
                  () {
                    Navigator.pop(ctx);
                    _changerStatut(
                      d['id'],
                      'annule',
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                  },
                ),

              // Sauvegarder notes seulement
              _actionBtn(
                Icons.save_outlined,
                "Sauvegarder les notes",
                Colors.grey,
                () async {
                  if (notesCtrl.text.trim().isEmpty) return;
                  await _supabase
                      .from('demandes_service_domestique')
                      .update({'notes_admin': notesCtrl.text.trim()})
                      .eq('id', d['id']);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnack("Notes sauvegardées");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Demandes domestiques",
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
            onPressed: _charger,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: _statuts.map((s) {
                final sel = _filtreStatut == s;
                return GestureDetector(
                  onTap: () {
                    setState(() => _filtreStatut = s);
                    _charger();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? widget.accentColor
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _labelsStatut[s] ?? s,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: widget.accentColor))
                : _demandes.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _demandes.length,
                        itemBuilder: (_, i) =>
                            _buildCard(_demandes[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> d) {
    final String statut = d['statut'] ?? '';
    final bool enqueteFaite = d['enquete_effectuee'] == true;
    final DateTime? created = d['created_at'] != null
        ? DateTime.tryParse(d['created_at'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statutColor(statut).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _labelsService[d['type_service']] ??
                        d['type_service'],
                    style: GoogleFonts.inter(
                      color: widget.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (d['type_prestation'] != null)
                  Text(
                    d['type_prestation'],
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 11),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _statutColor(statut).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _labelsStatut[statut] ?? statut,
                    style: GoogleFonts.inter(
                      color: _statutColor(statut),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Infos demandeur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      d['nom_demandeur'] ?? '—',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    if (d['telephone_demandeur'] != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        d['telephone_demandeur'],
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white38, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      "${d['commune'] ?? ''}${d['commune'] != null && d['ville'] != null ? ', ' : ''}${d['ville'] ?? ''}",
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 12),
                    ),
                    if (d['date_souhaitee'] != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        d['date_souhaitee'],
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                if ((d['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    d['description'],
                    style: GoogleFonts.inter(
                        color: Colors.white60, fontSize: 12, height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                if (enqueteFaite) ...[
                  const Icon(Icons.verified_user,
                      color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text("Enquête OK",
                      style: GoogleFonts.inter(
                          color: Colors.green, fontSize: 11)),
                  const SizedBox(width: 12),
                ],
                if (created != null)
                  Text(
                    DateFormat('dd/MM/yy HH:mm').format(created.toLocal()),
                    style: GoogleFonts.inter(
                        color: Colors.white24, fontSize: 11),
                  ),
                const Spacer(),
                if (statut != 'annule')
                  GestureDetector(
                    onTap: () => _showActionSheet(d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Actions",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'en_attente_validation':
        return Colors.orange;
      case 'en_cours_traitement':
        return Colors.blue;
      case 'affecte':
        return Colors.green;
      case 'annule':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_work_rounded,
              size: 60,
              color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            "Aucune demande ${_labelsStatut[_filtreStatut]?.toLowerCase() ?? ''}",
            style:
                GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
