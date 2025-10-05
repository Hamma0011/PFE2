import 'package:flutter/material.dart';
import '../../../shop/models/horaire_model.dart';
import '../../../shop/models/jour_semaine.dart';
import 'heure_button.dart';


class HoraireTileAmeliore extends StatefulWidget {
  final Horaire horaire;
  final Function(Horaire) onChanged;

  const HoraireTileAmeliore({
    super.key,
    required this.horaire,
    required this.onChanged,
  });

  @override
  State<HoraireTileAmeliore> createState() => _HoraireTileAmelioreState();
}

class _HoraireTileAmelioreState extends State<HoraireTileAmeliore> {
  late Horaire _currentHoraire;

  @override
  void initState() {
    super.initState();
    _currentHoraire = widget.horaire;
  }

  void _toggleOuverture(bool estOuvert) {
    setState(() {
      if (estOuvert) {
        // Quand on active, mettre des heures par défaut
        _currentHoraire = _currentHoraire.copyWith(
          estOuvert: true,
          ouverture: _currentHoraire.ouverture ?? '09:00', // Valeur par défaut
          fermeture: _currentHoraire.fermeture ?? '18:00', // Valeur par défaut
        );
      } else {
        // Quand on désactive, mettre les heures à null
        _currentHoraire = _currentHoraire.copyWith(
          estOuvert: false,
          ouverture: null,
          fermeture: null,
        );
      }
    });
    widget.onChanged(_currentHoraire);
  }

  Future<void> _selectHeure(BuildContext context, bool isOuverture) async {
    // CORRECTION: Utiliser des valeurs par défaut si null
    final heureActuelle = isOuverture
        ? _currentHoraire.ouverture ?? '09:00'
        : _currentHoraire.fermeture ?? '18:00';

    final initialTime = _parseTime(heureActuelle);

    final TimeOfDay? heureChoisie = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (heureChoisie != null) {
      final heureFormattee = '${heureChoisie.hour.toString().padLeft(2, '0')}:${heureChoisie.minute.toString().padLeft(2, '0')}';

      // Validation des heures
      if (!_validerHeures(isOuverture, heureFormattee)) {
        return;
      }

      setState(() {
        _currentHoraire = _currentHoraire.copyWith(
          ouverture: isOuverture ? heureFormattee : _currentHoraire.ouverture,
          fermeture: !isOuverture ? heureFormattee : _currentHoraire.fermeture,
        );
      });
      widget.onChanged(_currentHoraire);
    }
  }

  bool _validerHeures(bool isOuverture, String nouvelleHeure) {
    // CORRECTION: Vérifier que les heures ne sont pas null avant de les utiliser
    if (isOuverture && _currentHoraire.fermeture != null) {
      final nouvelleOuverture = _timeToMinutes(nouvelleHeure);
      final fermeture = _timeToMinutes(_currentHoraire.fermeture!);
      if (nouvelleOuverture >= fermeture) {
        _showErreurHeures('L\'heure d\'ouverture doit être avant l\'heure de fermeture');
        return false;
      }
    } else if (!isOuverture && _currentHoraire.ouverture != null) {
      final ouverture = _timeToMinutes(_currentHoraire.ouverture!);
      final nouvelleFermeture = _timeToMinutes(nouvelleHeure);
      if (nouvelleFermeture <= ouverture) {
        _showErreurHeures('L\'heure de fermeture doit être après l\'heure d\'ouverture');
        return false;
      }
    }
    return true;
  }

  void _showErreurHeures(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _getJourAbrege(JourSemaine jour) {
    switch (jour) {
      case JourSemaine.lundi: return 'LUN';
      case JourSemaine.mardi: return 'MAR';
      case JourSemaine.mercredi: return 'MER';
      case JourSemaine.jeudi: return 'JEU';
      case JourSemaine.vendredi: return 'VEN';
      case JourSemaine.samedi: return 'SAM';
      case JourSemaine.dimanche: return 'DIM';
    }
  }

  Color _getCouleurJour(JourSemaine jour) {
    switch (jour) {
      case JourSemaine.lundi:
      case JourSemaine.mardi:
      case JourSemaine.mercredi:
      case JourSemaine.jeudi:
      case JourSemaine.vendredi:
        return Colors.blue;
      case JourSemaine.samedi:
        return Colors.orange;
      case JourSemaine.dimanche:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleurJour = _getCouleurJour(_currentHoraire.jour);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // En-tête avec jour et switch - TOUJOURS AFFICHÉ
            Row(
              children: [
                // Badge du jour
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _currentHoraire.estOuvert ? couleurJour : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getJourAbrege(_currentHoraire.jour),
                          style: TextStyle(
                            color: _currentHoraire.estOuvert ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          _currentHoraire.estOuvert ? Icons.check : Icons.close,
                          size: 14,
                          color: _currentHoraire.estOuvert ? Colors.white : Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Nom du jour
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentHoraire.jour.valeur,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _currentHoraire.estOuvert ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentHoraire.estOuvert
                            ? '${_currentHoraire.ouverture ?? "09:00"} - ${_currentHoraire.fermeture ?? "18:00"}' // CORRECTION: valeurs par défaut
                            : 'Fermé',
                        style: TextStyle(
                          color: _currentHoraire.estOuvert ? Colors.green[700] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Switch - TOUJOURS AFFICHÉ
                Switch(
                  value: _currentHoraire.estOuvert,
                  onChanged: _toggleOuverture,
                  activeColor: couleurJour,
                ),
              ],
            ),

            // Section horaires (seulement si ouvert)
            if (_currentHoraire.estOuvert) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: HeureButtonAmeliore(
                      label: 'Heure d\'ouverture',
                      heure: _currentHoraire.ouverture ?? '09:00', // CORRECTION: valeur par défaut
                      onTap: () => _selectHeure(context, true),
                      couleur: couleurJour,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: HeureButtonAmeliore(
                      label: 'Heure de fermeture',
                      heure: _currentHoraire.fermeture ?? '18:00', // CORRECTION: valeur par défaut
                      onTap: () => _selectHeure(context, false),
                      couleur: couleurJour,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}