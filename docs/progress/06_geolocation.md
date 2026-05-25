# Géolocalisation — Suivi d'évolution

**Statut global : ✅ Complet**  
*Dernière mise à jour : 2026-05-20*

---

## CE QUI EST FAIT

- [x] **GPS device** (`geolocator`) — récupère position actuelle
- [x] **Affichage carte** (`flutter_map` + `latlong2`) — OpenStreetMap, centre sur Abidjan par défaut
- [x] **Sélection de lieu** (`widgets/location_picker_widget.dart`)  
  Tap sur la carte pour sélectionner une position. Retourne `LatLng`.
- [x] **Partage position via chat** — `LocationPickerWidget` intégré dans `chat_screen.dart`
- [x] **Extraction GPS depuis description** — `mes_interventions_page.dart` parse les coordonnées depuis la description texte
- [x] **Itinéraire externe** — bouton ouverture Google Maps / Apple Maps depuis une intervention

---

## PROCHAINES ÉVOLUTIONS

- [ ] **Carte des techniciens** — pins sur une carte montrant les techs disponibles à proximité
- [ ] **Distance calculée** — afficher "X km" entre client et tech dans la liste
- [ ] **Géofencing** — alerter les techs dans un rayon quand une intervention est créée
- [ ] **Adresse reverse geocoding** — convertir LatLng → adresse textuelle lisible
