import 'package:flutter/material.dart';

import '../perfil/perfil_tela.dart';
import 'agenda_tela.dart';
import 'semana_padrao_tela.dart';

/// Área do instrutor: agenda do dia, semana padrão e perfil.
class InicioInstrutor extends StatefulWidget {
  const InicioInstrutor({super.key});

  @override
  State<InicioInstrutor> createState() => _InicioInstrutorState();
}

class _InicioInstrutorState extends State<InicioInstrutor> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: switch (_aba) {
          0 => const AgendaTela(),
          1 => const SemanaPadraoTela(),
          _ => const PerfilTela(),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _aba,
          onDestinationSelected: (i) => setState(() => _aba = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Horários',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      );
}
