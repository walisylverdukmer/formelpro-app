import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:formelpro/screens/interventions/demande_intervention_page.dart';

class SubCategoriesPage extends StatefulWidget {
  final String groupName;
  final Color accentColor;

  const SubCategoriesPage({
    super.key,
    required this.groupName,
    required this.accentColor,
  });

  @override
  State<SubCategoriesPage> createState() => _SubCategoriesPageState();
}

class _SubCategoriesPageState extends State<SubCategoriesPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _subCategories = [];

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  Future<void> _loadSubCategories() async {
    try {
      final response = await supabase
          .from('categories_services')
          .select('id, nom, description')
          .eq('groupe_parent', widget.groupName)
          .eq('est_valide', true)
          .order('nom');

      if (mounted) {
        setState(() {
          _subCategories = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur sous-catégories: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.groupName,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
              fontSize: 20),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.accentColor))
          : _buildList(),
    );
  }

  Widget _buildList() {
    if (_subCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.blueGrey.shade100),
            const SizedBox(height: 16),
            Text(
              'Aucun service disponible pour le moment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.blueGrey.shade400, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _subCategories.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final sub = _subCategories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DemandeInterventionPage(
                    categoryName: sub['nom'],
                    categoryId: sub['id'].toString(),
                    accentColor: widget.accentColor,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sub['nom'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sub['description'] ?? 'Cliquez pour demander ce service.',
                            style: GoogleFonts.inter(
                              color: Colors.blueGrey.shade400,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded,
                          color: widget.accentColor, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
