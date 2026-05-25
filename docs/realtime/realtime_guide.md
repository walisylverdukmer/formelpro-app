# Guide Realtime & Notifications — FormelPro

*Dernière mise à jour : 2026-05-20*

---

## 1. VUE D'ENSEMBLE

FormelPro utilise deux canaux temps réel en parallèle :

| Canal | Technologie | Usage |
|-------|-------------|-------|
| **Supabase Realtime** | WebSocket PostgreSQL | Liste interventions, messages chat, notifications in-app |
| **Firebase FCM** | Push notifications | Notifications système (app background/fermée) |

Ces deux canaux sont **complémentaires** :
- Supabase Realtime → `SnackBar` quand l'app est **au premier plan**
- FCM → Notification système quand l'app est **en arrière-plan ou fermée**

---

## 2. SUPABASE REALTIME — PATTERNS

### 2.1 Pattern StreamBuilder standard

```dart
// Toujours utiliser .stream() pour les données dynamiques
StreamBuilder<List<Map<String, dynamic>>>(
  stream: Supabase.instance.client
      .from('interventions')
      .stream(primaryKey: ['id'])
      .eq('client_id', uid)
      .order('date_creation', ascending: false),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _ShimmerList();
    }
    if (snapshot.hasError) {
      return _ErrorState(message: snapshot.error.toString());
    }
    final items = snapshot.data ?? [];
    if (items.isEmpty) return const _EmptyState();
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) => _buildItem(items[i]),
    );
  },
)
```

### 2.2 Tables avec Realtime activé

| Table | Activé | Configuré dans |
|-------|--------|---------------|
| `notifications` | ✅ | `migrations.sql` + Supabase Dashboard |
| `messages` | ✅ | `migrations.sql` + Supabase Dashboard |
| `interventions` | ✅ via stream | `stream()` Supabase Flutter SDK |
| Autres | Via `.stream()` | Automatique avec le SDK |

> **Vérification :** Dans Supabase Dashboard → Database → Replication — s'assurer que les tables `notifications` et `messages` sont dans la publication `supabase_realtime`.

### 2.3 Limitation du scope des streams

```dart
// ✅ Toujours filtrer — ne jamais écouter une table entière
.stream(primaryKey: ['id'])
.eq('user_id', uid)           // Filtre par utilisateur

// ✅ Limiter la quantité de données
.stream(primaryKey: ['id'])
.eq('conversation_id', convId)
// Note: .limit() n'est pas supporté sur .stream() — gérer côté Flutter si besoin
```

### 2.4 Unsubscribe dans dispose()

```dart
class _MonEcranState extends State<MonEcran> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // Pattern subscription manuelle si StreamBuilder insuffisant
    _subscription = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .listen((data) {
          if (mounted) setState(() => _notifications = data);
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

---

## 3. ARCHITECTURE CHAT TEMPS RÉEL

### 3.1 Flux complet

```
User A saisit → TextEditingController
    │
    └── _sendMessage()
            │
            └── insert into messages {conversation_id, expediteur_id, contenu, cree_le}
                    │
                    └── Supabase Realtime broadcast
                            │
                            └── User B StreamBuilder reçoit
                                    └── _scrollToBottom()
```

### 3.2 Pattern chat_screen.dart

```dart
// Stream des messages
Stream<List<Map<String, dynamic>>> get _messagesStream =>
    Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId);

// Envoi message
Future<void> _sendMessage(String text) async {
  if (text.trim().isEmpty) return;
  _controller.clear();

  await Supabase.instance.client.from('messages').insert({
    'conversation_id': widget.conversationId,
    'expediteur_id': currentUserId,
    'contenu': text.trim(),
    'est_proposition_intervention': false,
  });

  // Mettre à jour le dernier message de la conversation
  await Supabase.instance.client
      .from('conversations')
      .update({'dernier_message': text.trim(), 'mis_a_jour_le': DateTime.now().toIso8601String()})
      .eq('id', widget.conversationId);
}
```

### 3.3 Scroll automatique au dernier message

```dart
final _scrollController = ScrollController();

// Après rebuild (StreamBuilder)
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
});
```

---

## 4. FIREBASE CLOUD MESSAGING (FCM)

### 4.1 Architecture côté Supabase

```
INSERT INTO notifications (user_id, titre, message, type)
    │
    ▼
Trigger "send-push-on-insert" (PostgreSQL)
    │ HTTP POST avec Authorization: Bearer <service_role_key>
    ▼
Edge Function: send-push-notification (Deno)
    │ Construit JWT depuis FIREBASE_SERVICE_ACCOUNT
    │ Appel FCM v1 API: POST /projects/{project}/messages:send
    ▼
FCM → Topic "user_{user_id}"
    │
    ▼
Appareil Android/iOS
```

### 4.2 Abonnement côté Flutter (main.dart)

```dart
Future<void> _initFCM(String userId) async {
  final messaging = FirebaseMessaging.instance;

  // Demander permission
  final settings = await messaging.requestPermission(
    alert: true, badge: true, sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {

    // S'abonner au topic personnel
    await messaging.subscribeToTopic('user_$userId');
  }
}
```

### 4.3 Configuration requise (fichiers manuels)

| Fichier | Emplacement | Source |
|---------|-------------|--------|
| `google-services.json` | `android/app/` | Console Firebase → Paramètres projet → Android |
| `GoogleService-Info.plist` | `ios/Runner/` | Console Firebase → Paramètres projet → iOS |

**Android — `android/app/build.gradle` :**
```gradle
apply plugin: 'com.google.gms.google-services'
```

**Android — `android/build.gradle` :**
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

### 4.4 Handlers FCM dans main.dart

```dart
// BACKGROUND (app fermée ou arrière-plan)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notification système affichée automatiquement par FCM
}

// FOREGROUND (app active — silencieux pour éviter doublon avec SnackBar Supabase)
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Ne rien afficher — le NotificationService Supabase gère le SnackBar
  debugPrint("FCM foreground reçu: ${message.notification?.title}");
});

// TAP SUR NOTIFICATION (app en arrière-plan, user tape)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  _routeFromNotification(message.data);
});
```

### 4.5 Routing futur depuis notification (Phase 3)

```dart
void _routeFromNotification(Map<String, dynamic> data) {
  final type = data['type'];
  switch (type) {
    case 'message':
      // Navigator.push → ChatScreen(conversationId: data['conversation_id'])
      break;
    case 'intervention':
      // Navigator.push → MissionDetailPage(interventionId: data['intervention_id'])
      break;
    case 'paiement':
      // Navigator.push → TransactionPage
      break;
  }
}
```

### 4.6 Désabonnement FCM à la déconnexion

```dart
// Dans auth_service.dart — signOut()
Future<void> signOut() async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId != null) {
    await FirebaseMessaging.instance.unsubscribeFromTopic('user_$userId');
  }
  await _supabase.auth.signOut();
}
```

---

## 5. NOTIFICATION SERVICE SUPABASE (in-app)

### 5.1 Fonctionnement actuel

```dart
// services/notification_service.dart
// Stream sur notifications non lues → SnackBar Soft Premium
class NotificationService {
  void init(BuildContext context, String userId) {
    Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('est_lu', false)
        .listen((notifications) {
          for (final notif in notifications) {
            _showSnackBar(context, notif);
            _markAsRead(notif['id']);
          }
        });
  }
}
```

### 5.2 Badge widget

```dart
// widgets/notification_badge.dart
// IconButton avec badge count + BottomSheet liste complète
StreamBuilder(
  stream: .from('notifications').stream(['id']).eq('user_id', uid).eq('est_lu', false),
  builder: (_, snap) {
    final count = snap.data?.length ?? 0;
    return Badge(count > 0 ? count.toString() : null, child: IconButton(...));
  },
)
```

---

## 6. BONNES PRATIQUES & ERREURS À ÉVITER

### 6.1 Performance

```dart
// ❌ ÉVITER — écouter une table sans filtre
.from('messages').stream(primaryKey: ['id'])

// ✅ Toujours filtrer
.from('messages').stream(primaryKey: ['id']).eq('conversation_id', convId)
```

### 6.2 Fuites mémoire

```dart
// ❌ Stream non annulé = fuite mémoire + écouteurs fantômes
void initState() {
  Supabase.instance.client.from('table').stream(...).listen(handler);
}

// ✅ Conserver et annuler
StreamSubscription? _sub;
void initState() { _sub = ...stream.listen(handler); }
void dispose() { _sub?.cancel(); super.dispose(); }
```

### 6.3 Doublon de notifications

Le `NotificationService` et FCM foreground écoutent tous les deux → **Ne JAMAIS afficher dans `onMessage`** FCM ce qui est déjà géré par le SnackBar Supabase.

### 6.4 État `mounted` obligatoire

```dart
// Avant tout setState ou ScaffoldMessenger après async
if (mounted) {
  setState(() { ... });
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```
