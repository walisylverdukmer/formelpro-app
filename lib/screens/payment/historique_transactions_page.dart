import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HistoriqueTransactionsPage extends StatefulWidget {
  final Color accentColor;

  const HistoriqueTransactionsPage({super.key, required this.accentColor});

  @override
  State<HistoriqueTransactionsPage> createState() =>
      _HistoriqueTransactionsPageState();
}

class _HistoriqueTransactionsPageState
    extends State<HistoriqueTransactionsPage> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List<Map<String, dynamic>> _transactions = [];

  static const _labelsOperateur = {
    'orange_money': 'Orange Money',
    'mtn_momo': 'MTN MoMo',
    'wave': 'Wave',
    'autre': 'Autre',
  };

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final rows = await _supabase
          .from('transactions')
          .select(
              'id, montant, operateur, statut, reference_externe, '
              'created_at, confirmed_at, pays, '
              'interventions(titre_service)')
          .or('client_id.eq.$uid,tech_id.eq.$uid')
          .order('created_at', ascending: false)
          .limit(100);

      if (mounted) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(rows);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur historique transactions: $e');
      if (mounted) setState(() => _loading = false);
    }
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
          "Historique des paiements",
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white38, size: 20),
            onPressed: _charger,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child:
                  CircularProgressIndicator(color: widget.accentColor))
          : _transactions.isEmpty
              ? _buildEmpty()
              : Column(
                  children: [
                    _buildSummaryBar(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: _transactions.length,
                        itemBuilder: (_, i) =>
                            _buildCard(_transactions[i]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryBar() {
    final confirmes = _transactions
        .where((t) => t['statut'] == 'confirme')
        .toList();
    final total = confirmes.fold<int>(
        0, (sum, t) => sum + ((t['montant'] as num?)?.toInt() ?? 0));
    final count = confirmes.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: widget.accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total payé",
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  "$total FCFA",
                  style: GoogleFonts.poppins(
                      color: widget.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white12,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$count transactions",
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 12),
              ),
              Text(
                "confirmées",
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> tx) {
    final String statut = tx['statut'] ?? '';
    final int montant = (tx['montant'] as num?)?.toInt() ?? 0;
    final String operateur =
        _labelsOperateur[tx['operateur']] ?? (tx['operateur'] ?? '—');
    final String? ref = tx['reference_externe'];
    final DateTime? created = tx['created_at'] != null
        ? DateTime.tryParse(tx['created_at'])
        : null;
    final DateTime? confirmed = tx['confirmed_at'] != null
        ? DateTime.tryParse(tx['confirmed_at'])
        : null;
    final String titre =
        (tx['interventions'] as Map?)?.cast<String, dynamic>()['titre_service']
            as String? ??
        'Intervention';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _statutColor(statut).withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : titre + statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    titre,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _statutBadge(statut),
              ],
            ),
            const SizedBox(height: 10),
            // Ligne 2 : montant + opérateur
            Row(
              children: [
                Text(
                  "$montant FCFA",
                  style: GoogleFonts.poppins(
                      color: widget.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_android,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        operateur,
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Référence
            if (ref != null && ref.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.tag, color: Colors.white24, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    ref,
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Dates
            Row(
              children: [
                const Icon(Icons.schedule,
                    color: Colors.white24, size: 12),
                const SizedBox(width: 4),
                Text(
                  created != null
                      ? DateFormat('dd/MM/yy HH:mm')
                          .format(created.toLocal())
                      : '—',
                  style: GoogleFonts.inter(
                      color: Colors.white24, fontSize: 11),
                ),
                if (confirmed != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "Confirmé ${DateFormat('dd/MM/yy').format(confirmed.toLocal())}",
                    style: GoogleFonts.inter(
                        color: Colors.green, fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statutBadge(String statut) {
    final color = _statutColor(statut);
    final labels = {
      'en_attente': 'En attente',
      'confirme': 'Confirmé',
      'echoue': 'Échoué',
      'rembourse': 'Remboursé',
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labels[statut] ?? statut,
        style: GoogleFonts.inter(
            color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'confirme':
        return Colors.green;
      case 'en_attente':
        return Colors.orange;
      case 'echoue':
        return Colors.red;
      case 'rembourse':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text("Aucune transaction enregistrée",
              style:
                  GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 8),
          Text("Vos paiements apparaîtront ici",
              style:
                  GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}
