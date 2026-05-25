// Firebase Messaging Service Worker — requis si Firebase Web est activé
// Laisser vide pour l'instant (FCM géré côté mobile uniquement)
// Pour activer Firebase Web, configurer ici avec les credentials du projet Firebase

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
});
