import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/location_picker_widget.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String receiverName;
  final String receiverId;
  final Color accentColor;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverName,
    required this.receiverId,
    required this.accentColor,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    final String content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'expediteur_id': supabase.auth.currentUser!.id,
        'contenu': content,
        'est_proposition_intervention': false,
      });
      
      await supabase.from('conversations').update({
        'dernier_message': content,
        'mis_a_jour_le': DateTime.now().toIso8601String(),
      }).eq('id', widget.conversationId);

    } catch (e) {
      debugPrint("Erreur envoi: $e");
    }
  }

  void _sendAgreement(String price, String details) async {
    if (price.isEmpty || details.isEmpty) return;
    
    try {
      final String agreementText = "📦 PROPOSITION D'INTERVENTION\n💰 Prix: $price FCFA\n📍 Lieu: $details";
      
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'expediteur_id': supabase.auth.currentUser!.id,
        'contenu': agreementText,
        'est_proposition_intervention': true,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Erreur envoi accord: $e");
    }
  }

  void _confirmIntervention(String messageId, String content) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // currentUser = client (qui accepte l'offre du tech)
      // widget.receiverId = tech (qui a envoyé l'accord)
      await supabase.from('interventions').insert({
        'client_id': currentUser.id,
        'tech_id': widget.receiverId,
        'titre_service': 'Accord via messagerie',
        'statut': 'en_attente',
        'description': content,
        'date_prevue': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
      });

      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'expediteur_id': currentUser.id,
        'contenu': "✅ OFFRE ACCEPTÉE. L'intervention est officiellement enregistrée !",
        'est_proposition_intervention': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Intervention confirmée !", style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur : ${e.message}", style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
      debugPrint("Erreur confirmation: $e");
    } catch (e) {
      debugPrint("Erreur confirmation: $e");
    }
  }

  void _showAgreementDialog() {
    final TextEditingController _priceController = TextEditingController();
    final TextEditingController _detailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20, left: 20, right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text("Fixer l'intervention", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Prix convenu (FCFA)",
                    prefixIcon: const Icon(Icons.money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () async {
                    final LatLng? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerWidget(
                          accentColor: widget.accentColor,
                          onLocationSelected: (LatLng coords) {},
                        ),
                      ),
                    );
                    if (result != null && mounted) {
                      setModalState(() {
                        _detailController.text = "${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}";
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.map_outlined, color: widget.accentColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _detailController.text.isEmpty 
                                ? "Pointer le lieu sur la carte" 
                                : "Lieu : ${_detailController.text}",
                            style: GoogleFonts.inter(
                              fontSize: 13, 
                              color: _detailController.text.isEmpty ? Colors.grey[600] : Colors.black87
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _sendAgreement(_priceController.text, _detailController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Envoyer l'accord", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.accentColor.withValues(alpha: 0.1), 
              child: Text(widget.receiverName[0], style: TextStyle(color: widget.accentColor))
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName, 
                    style: GoogleFonts.poppins(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold), 
                    overflow: TextOverflow.ellipsis
                  ),
                  Text("En ligne", style: GoogleFonts.inter(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('conversation_id', widget.conversationId)
                  .order('cree_le', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['expediteur_id'] == supabase.auth.currentUser?.id;
                    final isAgreement = msg['est_proposition_intervention'] ?? false;

                    if (isAgreement) return _buildAgreementCard(msg, isMe);
                    return _buildMessageBubble(msg['contenu'], isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? widget.accentColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)],
        ),
        child: Text(text, style: GoogleFonts.inter(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
      ),
    );
  }

  Widget _buildAgreementCard(Map<String, dynamic> msg, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.accentColor, width: 1.5),
        boxShadow: [BoxShadow(color: widget.accentColor.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(Icons.handshake_outlined, color: widget.accentColor, size: 30),
          const SizedBox(height: 10),
          Text("ACCORD D'INTERVENTION", 
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: widget.accentColor)
          ),
          const SizedBox(height: 8),
          Text(msg['contenu'], textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          if (!isMe)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmIntervention(msg['id'], msg['contenu']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text("Accepter l'offre", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                "En attente de confirmation du client...",
                style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.orange[800]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white, 
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle, color: widget.accentColor, size: 32),
                  onPressed: _showAgreementDialog,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text("Accord", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: widget.accentColor)),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: const InputDecoration(hintText: "Écrivez votre message...", border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: widget.accentColor,
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20), 
                onPressed: _sendMessage
              ),
            ),
          ],
        ),
      ),
    );
  }
}